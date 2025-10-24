use crate::errors::AppError;
use crate::services::BlindService;
use actix_web::{get, web, HttpResponse, Result};

#[get("/blinds/status")]
pub async fn get_blinds_status(
    blind_service: web::Data<BlindService>,
) -> Result<HttpResponse, AppError> {
    let status = blind_service.get_blinds_status();
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "rooms": status
    })))
}

#[get("/blinds/rooms")]
pub async fn get_rooms(blind_service: web::Data<BlindService>) -> Result<HttpResponse, AppError> {
    let rooms_response = blind_service.get_rooms();
    Ok(HttpResponse::Ok().json(rooms_response))
}

#[get("/blinds/config")]
pub async fn get_config(blind_service: web::Data<BlindService>) -> Result<HttpResponse, AppError> {
    let config_response = blind_service.get_config();
    Ok(HttpResponse::Ok().json(config_response))
}

#[get("/status")]
pub async fn get_system_status(
    blind_service: web::Data<BlindService>,
) -> Result<HttpResponse, AppError> {
    let status_response = blind_service.get_system_status().await;
    Ok(HttpResponse::Ok().json(status_response))
}

#[get("/mqtt/info")]
pub async fn get_mqtt_info(
    blind_service: web::Data<BlindService>,
) -> Result<HttpResponse, AppError> {
    let mqtt_info = blind_service.get_mqtt_info().await;
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "mqtt": mqtt_info,
        "timestamp": chrono::Utc::now()
    })))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{AppConfig, BlindConfig, MqttConfig, ServerConfig};
    use crate::services::{BlindService, MqttService};
    use actix_web::{test, App};
    use rumqttc::{AsyncClient, MqttOptions};
    use std::sync::Arc;
    use tokio::sync::Mutex;

    fn create_test_config() -> AppConfig {
        AppConfig {
            mqtt: MqttConfig {
                broker_host: "localhost".to_string(),
                broker_port: 1883,
                client_id: "test".to_string(),
                keep_alive_secs: 60,
                username: None,
                password: None,
            },
            server: ServerConfig {
                host: "0.0.0.0".to_string(),
                port: 8080,
            },
            blinds: vec![BlindConfig {
                id: "test_blind".to_string(),
                name: "Test Blind".to_string(),
                room: "test_room".to_string(),
                mqtt_topic: "test/topic".to_string(),
                device_type: "test".to_string(),
                enabled: true,
                battery_topic: None,
                status_topic: None,
            }],
        }
    }

    async fn create_test_service() -> web::Data<BlindService> {
        let config = Arc::new(create_test_config());
        let mqtt_options = MqttOptions::new("test", "localhost", 1883);
        let (client, _) = AsyncClient::new(mqtt_options, 10);
        let mqtt_service = MqttService::new(Arc::new(Mutex::new(client)));
        let blind_service = BlindService::new(mqtt_service, config);
        web::Data::new(blind_service)
    }

    #[actix_web::test]
    async fn test_get_blinds_status() {
        let service = create_test_service().await;
        let app = test::init_service(App::new().app_data(service).service(get_blinds_status)).await;

        let req = test::TestRequest::get().uri("/blinds/status").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_get_rooms() {
        let service = create_test_service().await;
        let app = test::init_service(App::new().app_data(service).service(get_rooms)).await;

        let req = test::TestRequest::get().uri("/blinds/rooms").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_get_config() {
        let service = create_test_service().await;
        let app = test::init_service(App::new().app_data(service).service(get_config)).await;

        let req = test::TestRequest::get().uri("/blinds/config").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_get_system_status() {
        let service = create_test_service().await;
        let app = test::init_service(App::new().app_data(service).service(get_system_status)).await;

        let req = test::TestRequest::get().uri("/status").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }
}
