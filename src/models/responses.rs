use crate::models::blind::{BlindCommand, BlindStatus, RoomInfo};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
            timestamp: chrono::Utc::now(),
        }
    }

    pub fn error(message: String) -> Self {
        Self {
            success: false,
            data: None,
            error: Some(message),
            timestamp: chrono::Utc::now(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlindControlResponse {
    pub status: String,
    pub blind_id: String,
    pub blind_name: String,
    pub room: String,
    pub command: String,
    pub topic: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

impl BlindControlResponse {
    pub fn new(
        blind_id: String,
        blind_name: String,
        room: String,
        command: BlindCommand,
        topic: String,
    ) -> Self {
        Self {
            status: command.as_str().to_lowercase(),
            blind_id,
            blind_name,
            room,
            command: command.as_str().to_string(),
            topic,
            timestamp: chrono::Utc::now(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchControlResult {
    pub blind_id: String,
    pub blind_name: String,
    pub status: String,
    pub topic: Option<String>,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchControlResponse {
    pub command: String,
    pub target: String, // room name or "all"
    pub total_blinds: usize,
    pub successful: usize,
    pub failed: usize,
    pub results: Vec<BatchControlResult>,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

impl BatchControlResponse {
    pub fn new(command: BlindCommand, target: String) -> Self {
        Self {
            command: command.as_str().to_string(),
            target,
            total_blinds: 0,
            successful: 0,
            failed: 0,
            results: Vec::new(),
            timestamp: chrono::Utc::now(),
        }
    }

    pub fn add_success(&mut self, blind_id: String, blind_name: String, topic: String) {
        self.results.push(BatchControlResult {
            blind_id,
            blind_name,
            status: "success".to_string(),
            topic: Some(topic),
            error: None,
        });
        self.successful += 1;
        self.total_blinds += 1;
    }

    pub fn add_failure(&mut self, blind_id: String, blind_name: String, error: String) {
        self.results.push(BatchControlResult {
            blind_id,
            blind_name,
            status: "error".to_string(),
            topic: None,
            error: Some(error),
        });
        self.failed += 1;
        self.total_blinds += 1;
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemStatusResponse {
    pub status: String,
    pub mqtt_connected: bool,
    pub total_blinds: usize,
    pub enabled_blinds: usize,
    pub rooms: Vec<RoomInfo>,
    pub uptime: String,
    pub version: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigResponse {
    pub mqtt: MqttConfigResponse,
    pub server: ServerConfigResponse,
    pub blinds: Vec<BlindStatus>,
    pub total_blinds: usize,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MqttConfigResponse {
    pub broker_host: String,
    pub broker_port: u16,
    pub client_id: String,
    pub username: Option<String>,
    // Note: password is intentionally omitted for security
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfigResponse {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoomsResponse {
    pub rooms: Vec<String>,
    pub total_rooms: usize,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub message: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

impl HealthResponse {
    pub fn healthy() -> Self {
        Self {
            status: "healthy".to_string(),
            message: "Tabi Backend is running normally".to_string(),
            timestamp: chrono::Utc::now(),
        }
    }

    pub fn unhealthy(reason: String) -> Self {
        Self {
            status: "unhealthy".to_string(),
            message: reason,
            timestamp: chrono::Utc::now(),
        }
    }
}
