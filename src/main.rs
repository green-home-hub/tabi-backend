use std::time::Duration;

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use rumqttc::{AsyncClient, Event, MqttOptions, Packet, QoS};
use serde_json;
use std::sync::Arc;
use tokio::{sync::Mutex, task};

mod config;
use config::{AppConfig, BlindConfig};

#[derive(Clone)]
struct AppState {
    mqtt_client: Arc<Mutex<AsyncClient>>, // compartido entre handlers
    config: Arc<AppConfig>,               // configuración compartida
    mqtt_connected: Arc<Mutex<bool>>,     // estado de conexión MQTT
}

// ----------------------------
// 2. Helper para publicar MQTT con
// ----------------------------
async fn publish_command(
    client: &mut AsyncClient,
    topic: &str,
    payload: &str,
) -> Result<(), rumqttc::ClientError> {
    client
        .publish(topic, QoS::AtLeastOnce, false, payload)
        .await?;
    Ok(())
}

#[get("/hello-world")]
async fn hello(state: web::Data<AppState>) -> impl Responder {
    let topic = String::from("test/topic");
    // HttpResponse::Ok().body("Hello world!")
    let mut client = state.mqtt_client.lock().await;
    match publish_command(&mut client, &topic, "OPEN").await {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({
            "status": 200
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "MQTT publish failed",
            "details": e.to_string(),
        })),
    }
}

// ----------------------------
// Endpoints para control individual por ID
// ----------------------------
#[post("/blinds/id/{blind_id}/{action}")]
async fn control_blind_by_id(
    path: web::Path<(String, String)>,
    state: web::Data<AppState>,
) -> HttpResponse {
    let (blind_id, action) = path.into_inner();
    let action = action.to_uppercase();

    // Validar acción
    if !matches!(action.as_str(), "OPEN" | "CLOSE" | "STOP") {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Invalid action. Use: OPEN, CLOSE, or STOP",
            "blind_id": blind_id
        }));
    }

    // Buscar persiana por ID
    let blind_config = match state.config.get_blind_by_id(&blind_id) {
        Some(blind) => blind,
        None => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "error": "Blind not found",
                "blind_id": blind_id
            }));
        }
    };

    if !blind_config.enabled {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Blind is disabled",
            "blind_id": blind_id
        }));
    }

    let mut client = state.mqtt_client.lock().await;

    match publish_command(&mut client, &blind_config.mqtt_topic, &action).await {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({
            "status": format!("{}", action.to_lowercase()),
            "blind_id": blind_id,
            "blind_name": blind_config.name,
            "room": blind_config.room,
            "command": action,
            "topic": blind_config.mqtt_topic
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "MQTT publish failed",
            "details": e.to_string(),
            "blind_id": blind_id
        })),
    }
}

// ----------------------------
// Endpoints para control por habitación (todas las persianas)
// ----------------------------
#[post("/blinds/room/{room}/{action}")]
async fn control_blinds_by_room(
    path: web::Path<(String, String)>,
    state: web::Data<AppState>,
) -> HttpResponse {
    let (room, action) = path.into_inner();
    let action = action.to_uppercase();

    // Validar acción
    if !matches!(action.as_str(), "OPEN" | "CLOSE" | "STOP") {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Invalid action. Use: OPEN, CLOSE, or STOP",
            "room": room
        }));
    }

    // Obtener todas las persianas de la habitación
    let room_blinds = state.config.get_blinds_by_room(&room);

    if room_blinds.is_empty() {
        return HttpResponse::NotFound().json(serde_json::json!({
            "error": "No blinds found in room or all disabled",
            "room": room
        }));
    }

    let mut client = state.mqtt_client.lock().await;
    let mut results = Vec::new();
    let mut success_count = 0;

    // Enviar comando a todas las persianas de la habitación
    for blind in &room_blinds {
        match publish_command(&mut client, &blind.mqtt_topic, &action).await {
            Ok(_) => {
                success_count += 1;
                results.push(serde_json::json!({
                    "blind_id": blind.id,
                    "blind_name": blind.name,
                    "status": "success",
                    "topic": blind.mqtt_topic
                }));
            }
            Err(e) => {
                results.push(serde_json::json!({
                    "blind_id": blind.id,
                    "blind_name": blind.name,
                    "status": "error",
                    "error": e.to_string(),
                    "topic": blind.mqtt_topic
                }));
            }
        }
    }

    HttpResponse::Ok().json(serde_json::json!({
        "room": room,
        "command": action,
        "total_blinds": room_blinds.len(),
        "successful": success_count,
        "failed": room_blinds.len() - success_count,
        "results": results
    }))
}

// ----------------------------
// Endpoints para control de todas las persianas
// ----------------------------
#[post("/blinds/all/{action}")]
async fn control_all_blinds(action: web::Path<String>, state: web::Data<AppState>) -> HttpResponse {
    let action = action.to_uppercase();

    // Validar acción
    if !matches!(action.as_str(), "OPEN" | "CLOSE" | "STOP") {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Invalid action. Use: OPEN, CLOSE, or STOP"
        }));
    }

    let all_blinds = state.config.get_enabled_blinds();

    if all_blinds.is_empty() {
        return HttpResponse::NotFound().json(serde_json::json!({
            "error": "No enabled blinds found"
        }));
    }

    let mut client = state.mqtt_client.lock().await;
    let mut results = Vec::new();
    let mut success_count = 0;

    // Enviar comando a todas las persianas
    for blind in &all_blinds {
        match publish_command(&mut client, &blind.mqtt_topic, &action).await {
            Ok(_) => {
                success_count += 1;
                results.push(serde_json::json!({
                    "blind_id": blind.id,
                    "blind_name": blind.name,
                    "room": blind.room,
                    "status": "success"
                }));
            }
            Err(e) => {
                results.push(serde_json::json!({
                    "blind_id": blind.id,
                    "blind_name": blind.name,
                    "room": blind.room,
                    "status": "error",
                    "error": e.to_string()
                }));
            }
        }
    }

    HttpResponse::Ok().json(serde_json::json!({
        "command": action,
        "total_blinds": all_blinds.len(),
        "successful": success_count,
        "failed": all_blinds.len() - success_count,
        "results": results
    }))
}

// ----------------------------
// Endpoints de información
// ----------------------------
#[get("/blinds/status")]
async fn get_blinds_status(state: web::Data<AppState>) -> HttpResponse {
    let blinds_map = state.config.get_blinds_map();

    HttpResponse::Ok().json(serde_json::json!({
        "rooms": blinds_map.iter().map(|(room, blinds)| {
            (room.clone(), serde_json::json!({
                "blinds": blinds.iter().map(|blind| serde_json::json!({
                    "id": blind.id,
                    "name": blind.name,
                    "device_type": blind.device_type,
                    "mqtt_topic": blind.mqtt_topic,
                    "status_topic": blind.status_topic,
                    "battery_topic": blind.battery_topic,
                    "enabled": blind.enabled
                })).collect::<Vec<_>>()
            }))
        }).collect::<serde_json::Map<String, serde_json::Value>>()
    }))
}

#[get("/blinds/rooms")]
async fn get_rooms(state: web::Data<AppState>) -> HttpResponse {
    let rooms = state.config.get_rooms();

    HttpResponse::Ok().json(serde_json::json!({
        "rooms": rooms,
        "total_rooms": rooms.len()
    }))
}

#[get("/blinds/config")]
async fn get_config(state: web::Data<AppState>) -> HttpResponse {
    let all_blinds = state.config.get_enabled_blinds();

    HttpResponse::Ok().json(serde_json::json!({
        "mqtt": {
            "broker_host": state.config.mqtt.broker_host,
            "broker_port": state.config.mqtt.broker_port,
            "client_id": state.config.mqtt.client_id
        },
        "server": {
            "host": state.config.server.host,
            "port": state.config.server.port
        },
        "blinds": all_blinds.iter().map(|blind| serde_json::json!({
            "id": blind.id,
            "name": blind.name,
            "room": blind.room,
            "device_type": blind.device_type,
            "mqtt_topic": blind.mqtt_topic,
            "enabled": blind.enabled
        })).collect::<Vec<_>>(),
        "total_blinds": all_blinds.len()
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("🏠 Iniciando Tabi Backend - Sistema de Control de Persianas");

    // Cargar configuración
    let config = AppConfig::load_or_default("config.json");

    // Validar configuración
    if let Err(e) = config.validate() {
        eprintln!("❌ Error en la configuración: {}", e);
        std::process::exit(1);
    }

    println!("✅ Configuración válida:");
    println!("   - {} persianas configuradas", config.blinds.len());
    println!("   - {} habitaciones", config.get_rooms().len());
    println!(
        "   - Broker MQTT: {}:{}",
        config.mqtt.broker_host, config.mqtt.broker_port
    );

    // Configura opciones MQTT desde la configuración
    let mut mqttoptions = MqttOptions::new(
        &config.mqtt.client_id,
        &config.mqtt.broker_host,
        config.mqtt.broker_port,
    );
    mqttoptions.set_keep_alive(Duration::from_secs(config.mqtt.keep_alive_secs));

    // Configurar autenticación si está disponible
    if let (Some(username), Some(password)) = (&config.mqtt.username, &config.mqtt.password) {
        mqttoptions.set_credentials(username, password);
        println!("🔐 Autenticación MQTT configurada");
    }

    // Crea cliente asíncrono
    let (client, mut eventloop) = AsyncClient::new(mqttoptions, 10);

    // Task para manejar eventos MQTT
    task::spawn(async move {
        println!("🔄 Iniciando loop de eventos MQTT...");
        loop {
            match eventloop.poll().await {
                Ok(_event) => {
                    // Aquí podrías procesar eventos MQTT específicos
                }
                Err(e) => {
                    eprintln!("❌ Error MQTT: {}", e);
                    // En producción, podrías implementar reconexión automática
                    tokio::time::sleep(Duration::from_secs(5)).await;
                }
            }
        }
    });

    // Estado compartido
    let app_state = web::Data::new(AppState {
        mqtt_client: Arc::new(Mutex::new(client)),
        config: Arc::new(config.clone()),
        mqtt_connected: Arc::new(Mutex::new(false)),
    });

    println!(
        "🚀 Iniciando servidor HTTP en {}:{}",
        config.server.host, config.server.port
    );

    HttpServer::new(move || {
        App::new()
            .app_data(app_state.clone())
            // Endpoints de salud y información
            .service(hello)
            .service(get_blinds_status)
            .service(get_rooms)
            .service(get_config)
            // Control individual por ID
            .service(control_blind_by_id)
            // Control por habitación
            .service(control_blinds_by_room)
            // Control global
            .service(control_all_blinds)
    })
    .bind((config.server.host.as_str(), config.server.port))?
    .run()
    .await
}
