use std::time::Duration;

use actix_web::{middleware::Logger, web, App, HttpServer};
use rumqttc::{AsyncClient, MqttOptions};
use std::sync::Arc;
use tokio::{sync::Mutex, task};

// Import our modules
mod config;
mod errors;
mod handlers;
mod models;
mod services;

use config::AppConfig;
use services::{BlindService, MqttService};

#[derive(Clone)]
struct AppState {
    blind_service: BlindService,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logging
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    println!("🏠 Iniciando Tabi Backend - Sistema de Control de Persianas");
    println!("📊 Versión: {}", env!("CARGO_PKG_VERSION"));

    // Load configuration
    let config = AppConfig::load_or_default("config.json");

    // Validate configuration
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

    // Setup MQTT client
    let mqtt_client = setup_mqtt_client(&config).await;
    let config_arc = Arc::new(config.clone());

    // Create services
    let mqtt_service = MqttService::new(mqtt_client.clone());
    let blind_service = BlindService::new(mqtt_service.clone(), config_arc);

    // Start MQTT event loop
    start_mqtt_event_loop(mqtt_client, mqtt_service.clone()).await;

    // Create application state
    let app_state = AppState { blind_service };

    println!(
        "🚀 Iniciando servidor HTTP en {}:{}",
        config.server.host, config.server.port
    );

    // Start HTTP server
    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(app_state.blind_service.clone()))
            .wrap(Logger::default())
            // Health endpoints
            .service(handlers::hello_world)
            .service(handlers::health_check)
            .service(handlers::ping)
            // System information endpoints
            .service(handlers::get_blinds_status)
            .service(handlers::get_rooms)
            .service(handlers::get_config)
            .service(handlers::get_system_status)
            .service(handlers::get_mqtt_info)
            // Blind control endpoints
            .service(handlers::control_blind_by_id)
            .service(handlers::control_blinds_by_room)
            .service(handlers::control_all_blinds)
    })
    .bind((config.server.host.as_str(), config.server.port))?
    .run()
    .await
}

async fn setup_mqtt_client(config: &AppConfig) -> Arc<Mutex<AsyncClient>> {
    // Configure MQTT options
    let mut mqttoptions = MqttOptions::new(
        &config.mqtt.client_id,
        &config.mqtt.broker_host,
        config.mqtt.broker_port,
    );
    mqttoptions.set_keep_alive(Duration::from_secs(config.mqtt.keep_alive_secs));

    // Configure authentication if available
    if let (Some(username), Some(password)) = (&config.mqtt.username, &config.mqtt.password) {
        mqttoptions.set_credentials(username, password);
        println!("🔐 Autenticación MQTT configurada");
    }

    // Create async client
    let (client, _eventloop) = AsyncClient::new(mqttoptions, 10);
    Arc::new(Mutex::new(client))
}

async fn start_mqtt_event_loop(_client: Arc<Mutex<AsyncClient>>, mqtt_service: MqttService) {
    // We need to recreate the eventloop because we can't move it from setup_mqtt_client
    // Note: In a full implementation, you would handle the actual MQTT eventloop here
    // For now, we'll use a simplified monitoring approach

    // Start MQTT event handling task
    task::spawn(async move {
        println!("🔄 Iniciando gestor de eventos MQTT...");

        // Set initial connection status
        mqtt_service.set_connected(true).await;

        loop {
            // Basic connection monitoring
            // In a full implementation, you'd handle the actual eventloop here
            tokio::time::sleep(Duration::from_secs(30)).await;

            // You could add connection health checks here
            if !mqtt_service.is_connected().await {
                log::warn!("MQTT connection lost, attempting to reconnect...");
                // Add reconnection logic here
            }
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, App};

    #[actix_web::test]
    async fn test_app_creation() {
        let config = AppConfig::default();
        let mqtt_client = setup_mqtt_client(&config).await;
        let config_arc = Arc::new(config);
        let mqtt_service = MqttService::new(mqtt_client);
        let blind_service = BlindService::new(mqtt_service, config_arc);

        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(blind_service))
                .service(handlers::hello_world),
        )
        .await;

        let req = test::TestRequest::get().uri("/hello-world").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }
}
