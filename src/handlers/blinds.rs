use crate::errors::AppError;
use crate::services::BlindService;
use actix_web::{post, web, HttpResponse, Result};

#[post("/blinds/id/{blind_id}/{action}")]
pub async fn control_blind_by_id(
    path: web::Path<(String, String)>,
    blind_service: web::Data<BlindService>,
) -> Result<HttpResponse, AppError> {
    let (blind_id, action) = path.into_inner();

    let result = blind_service
        .control_blind_by_id(&blind_id, &action)
        .await?;
    Ok(HttpResponse::Ok().json(result))
}

#[post("/blinds/room/{room}/{action}")]
pub async fn control_blinds_by_room(
    path: web::Path<(String, String)>,
    blind_service: web::Data<BlindService>,
) -> Result<HttpResponse, AppError> {
    let (room, action) = path.into_inner();

    let result = blind_service.control_blinds_by_room(&room, &action).await?;
    Ok(HttpResponse::Ok().json(result))
}

#[post("/blinds/all/{action}")]
pub async fn control_all_blinds(
    action: web::Path<String>,
    blind_service: web::Data<BlindService>,
) -> Result<HttpResponse, AppError> {
    let action = action.into_inner();

    let result = blind_service.control_all_blinds(&action).await?;
    Ok(HttpResponse::Ok().json(result))
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
            blinds: vec![
                BlindConfig {
                    id: "blind_001".to_string(),
                    name: "Test Blind 1".to_string(),
                    room: "living_room".to_string(),
                    mqtt_topic: "home/blinds/living/control".to_string(),
                    device_type: "motorized_blind".to_string(),
                    enabled: true,
                    battery_topic: None,
                    status_topic: None,
                },
                BlindConfig {
                    id: "blind_002".to_string(),
                    name: "Test Blind 2".to_string(),
                    room: "living_room".to_string(),
                    mqtt_topic: "home/blinds/living2/control".to_string(),
                    device_type: "motorized_blind".to_string(),
                    enabled: true,
                    battery_topic: None,
                    status_topic: None,
                },
            ],
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
    async fn test_control_blind_by_id() {
        let service = create_test_service().await;
        let app =
            test::init_service(App::new().app_data(service).service(control_blind_by_id)).await;

        let req = test::TestRequest::post()
            .uri("/blinds/id/blind_001/OPEN")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_control_blind_by_id_invalid_action() {
        let service = create_test_service().await;
        let app =
            test::init_service(App::new().app_data(service).service(control_blind_by_id)).await;

        let req = test::TestRequest::post()
            .uri("/blinds/id/blind_001/INVALID")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_client_error());
    }

    #[actix_web::test]
    async fn test_control_blind_by_id_not_found() {
        let service = create_test_service().await;
        let app =
            test::init_service(App::new().app_data(service).service(control_blind_by_id)).await;

        let req = test::TestRequest::post()
            .uri("/blinds/id/nonexistent/OPEN")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_client_error());
    }

    #[actix_web::test]
    async fn test_control_blinds_by_room() {
        let service = create_test_service().await;
        let app =
            test::init_service(App::new().app_data(service).service(control_blinds_by_room)).await;

        let req = test::TestRequest::post()
            .uri("/blinds/room/living_room/CLOSE")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_control_blinds_by_room_not_found() {
        let service = create_test_service().await;
        let app =
            test::init_service(App::new().app_data(service).service(control_blinds_by_room)).await;

        let req = test::TestRequest::post()
            .uri("/blinds/room/nonexistent_room/OPEN")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_client_error());
    }

    #[actix_web::test]
    async fn test_control_all_blinds() {
        let service = create_test_service().await;
        let app =
            test::init_service(App::new().app_data(service).service(control_all_blinds)).await;

        let req = test::TestRequest::post()
            .uri("/blinds/all/STOP")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_control_all_blinds_invalid_action() {
        let service = create_test_service().await;
        let app =
            test::init_service(App::new().app_data(service).service(control_all_blinds)).await;

        let req = test::TestRequest::post()
            .uri("/blinds/all/INVALID")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_client_error());
    }
}
