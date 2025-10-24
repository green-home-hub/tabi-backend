use actix_web::{HttpResponse, ResponseError};
use std::fmt;

#[derive(Debug)]
pub enum AppError {
    BlindNotFound(String),
    BlindDisabled(String),
    RoomNotFound(String),
    InvalidAction(String),
    MqttError(rumqttc::ClientError),
    ConfigError(String),
    ValidationError(String),
    InternalError(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::BlindNotFound(id) => write!(f, "Blind not found: {}", id),
            AppError::BlindDisabled(id) => write!(f, "Blind is disabled: {}", id),
            AppError::RoomNotFound(room) => write!(f, "Room not found: {}", room),
            AppError::InvalidAction(action) => write!(f, "Invalid action: {}", action),
            AppError::MqttError(e) => write!(f, "MQTT error: {}", e),
            AppError::ConfigError(msg) => write!(f, "Configuration error: {}", msg),
            AppError::ValidationError(msg) => write!(f, "Validation error: {}", msg),
            AppError::InternalError(msg) => write!(f, "Internal error: {}", msg),
        }
    }
}

impl std::error::Error for AppError {}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        match self {
            AppError::BlindNotFound(id) => HttpResponse::NotFound().json(serde_json::json!({
                "error": "Blind not found",
                "blind_id": id,
                "error_code": "BLIND_NOT_FOUND"
            })),
            AppError::BlindDisabled(id) => HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Blind is disabled",
                "blind_id": id,
                "error_code": "BLIND_DISABLED"
            })),
            AppError::RoomNotFound(room) => HttpResponse::NotFound().json(serde_json::json!({
                "error": "Room not found or has no enabled blinds",
                "room": room,
                "error_code": "ROOM_NOT_FOUND"
            })),
            AppError::InvalidAction(action) => HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Invalid action. Use: OPEN, CLOSE, or STOP",
                "received": action,
                "error_code": "INVALID_ACTION"
            })),
            AppError::MqttError(e) => HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "MQTT communication failed",
                "details": e.to_string(),
                "error_code": "MQTT_ERROR"
            })),
            AppError::ConfigError(msg) => {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Configuration error",
                    "details": msg,
                    "error_code": "CONFIG_ERROR"
                }))
            }
            AppError::ValidationError(msg) => HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Validation error",
                "details": msg,
                "error_code": "VALIDATION_ERROR"
            })),
            AppError::InternalError(msg) => {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Internal server error",
                    "details": msg,
                    "error_code": "INTERNAL_ERROR"
                }))
            }
        }
    }
}

impl From<rumqttc::ClientError> for AppError {
    fn from(error: rumqttc::ClientError) -> Self {
        AppError::MqttError(error)
    }
}

impl From<serde_json::Error> for AppError {
    fn from(error: serde_json::Error) -> Self {
        AppError::InternalError(format!("JSON error: {}", error))
    }
}

impl From<std::io::Error> for AppError {
    fn from(error: std::io::Error) -> Self {
        AppError::InternalError(format!("IO error: {}", error))
    }
}
