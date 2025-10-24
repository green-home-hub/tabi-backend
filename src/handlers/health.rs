use crate::models::responses::HealthResponse;
use actix_web::{get, HttpResponse, Result};

#[get("/hello-world")]
pub async fn hello_world() -> Result<HttpResponse> {
    Ok(HttpResponse::Ok().json(HealthResponse::healthy()))
}

#[get("/health")]
pub async fn health_check() -> Result<HttpResponse> {
    Ok(HttpResponse::Ok().json(HealthResponse::healthy()))
}

#[get("/ping")]
pub async fn ping() -> Result<HttpResponse> {
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "message": "pong",
        "timestamp": chrono::Utc::now()
    })))
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, App};

    #[actix_web::test]
    async fn test_hello_world() {
        let app = test::init_service(App::new().service(hello_world)).await;
        let req = test::TestRequest::get().uri("/hello-world").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_health_check() {
        let app = test::init_service(App::new().service(health_check)).await;
        let req = test::TestRequest::get().uri("/health").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_ping() {
        let app = test::init_service(App::new().service(ping)).await;
        let req = test::TestRequest::get().uri("/ping").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }
}
