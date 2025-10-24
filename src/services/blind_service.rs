use crate::config::{AppConfig, BlindConfig};
use crate::errors::AppError;
use crate::models::blind::{BlindCommand, BlindStatus, RoomInfo};
use crate::models::responses::{
    BatchControlResponse, BlindControlResponse, ConfigResponse, MqttConfigResponse, RoomsResponse,
    ServerConfigResponse, SystemStatusResponse,
};
use crate::services::mqtt_service::MqttService;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;
use std::time::Instant;

pub struct BlindService {
    mqtt_service: MqttService,
    config: Arc<AppConfig>,
    start_time: Instant,
}

impl BlindService {
    pub fn new(mqtt_service: MqttService, config: Arc<AppConfig>) -> Self {
        Self {
            mqtt_service,
            config,
            start_time: Instant::now(),
        }
    }

    pub async fn control_blind_by_id(
        &self,
        blind_id: &str,
        action: &str,
    ) -> Result<BlindControlResponse, AppError> {
        // Parse and validate action
        let command = BlindCommand::from_str(action)?;

        // Find blind configuration
        let blind = self
            .config
            .get_blind_by_id(blind_id)
            .ok_or_else(|| AppError::BlindNotFound(blind_id.to_string()))?;

        // Check if blind is enabled
        if !blind.enabled {
            return Err(AppError::BlindDisabled(blind_id.to_string()));
        }

        // Send MQTT command
        self.mqtt_service
            .publish_command(&blind.mqtt_topic, command.as_str())
            .await?;

        // Create response
        Ok(BlindControlResponse::new(
            blind.id.clone(),
            blind.name.clone(),
            blind.room.clone(),
            command,
            blind.mqtt_topic.clone(),
        ))
    }

    pub async fn control_blinds_by_room(
        &self,
        room: &str,
        action: &str,
    ) -> Result<BatchControlResponse, AppError> {
        let command = BlindCommand::from_str(action)?;
        let room_blinds = self.config.get_blinds_by_room(room);

        if room_blinds.is_empty() {
            return Err(AppError::RoomNotFound(room.to_string()));
        }

        let mut response = BatchControlResponse::new(command.clone(), room.to_string());

        // Send commands to all blinds in the room
        for blind in room_blinds {
            match self
                .mqtt_service
                .publish_command(&blind.mqtt_topic, command.as_str())
                .await
            {
                Ok(_) => {
                    response.add_success(
                        blind.id.clone(),
                        blind.name.clone(),
                        blind.mqtt_topic.clone(),
                    );
                }
                Err(e) => {
                    response.add_failure(blind.id.clone(), blind.name.clone(), e.to_string());
                }
            }
        }

        Ok(response)
    }

    pub async fn control_all_blinds(&self, action: &str) -> Result<BatchControlResponse, AppError> {
        let command = BlindCommand::from_str(action)?;
        let all_blinds = self.config.get_enabled_blinds();

        if all_blinds.is_empty() {
            return Err(AppError::ConfigError("No enabled blinds found".to_string()));
        }

        let mut response = BatchControlResponse::new(command.clone(), "all".to_string());

        // Send commands to all enabled blinds
        for blind in all_blinds {
            match self
                .mqtt_service
                .publish_command(&blind.mqtt_topic, command.as_str())
                .await
            {
                Ok(_) => {
                    response.add_success(
                        blind.id.clone(),
                        blind.name.clone(),
                        blind.mqtt_topic.clone(),
                    );
                }
                Err(e) => {
                    response.add_failure(blind.id.clone(), blind.name.clone(), e.to_string());
                }
            }
        }

        Ok(response)
    }

    pub async fn get_system_status(&self) -> SystemStatusResponse {
        let rooms = self.get_room_info();
        let enabled_blinds = self.config.get_enabled_blinds();
        let mqtt_connected = self.mqtt_service.is_connected().await;

        let uptime = {
            let duration = self.start_time.elapsed();
            let days = duration.as_secs() / 86400;
            let hours = (duration.as_secs() % 86400) / 3600;
            let minutes = (duration.as_secs() % 3600) / 60;
            let seconds = duration.as_secs() % 60;

            if days > 0 {
                format!("{}d {}h {}m {}s", days, hours, minutes, seconds)
            } else if hours > 0 {
                format!("{}h {}m {}s", hours, minutes, seconds)
            } else if minutes > 0 {
                format!("{}m {}s", minutes, seconds)
            } else {
                format!("{}s", seconds)
            }
        };

        SystemStatusResponse {
            status: if mqtt_connected && !enabled_blinds.is_empty() {
                "healthy".to_string()
            } else {
                "degraded".to_string()
            },
            mqtt_connected,
            total_blinds: self.config.blinds.len(),
            enabled_blinds: enabled_blinds.len(),
            rooms,
            uptime,
            version: env!("CARGO_PKG_VERSION").to_string(),
            timestamp: chrono::Utc::now(),
        }
    }

    pub fn get_blinds_status(&self) -> HashMap<String, Vec<BlindStatus>> {
        let mut rooms_map: HashMap<String, Vec<BlindStatus>> = HashMap::new();

        for blind in &self.config.blinds {
            if blind.enabled {
                let blind_status = BlindStatus::from(blind);
                rooms_map
                    .entry(blind.room.clone())
                    .or_insert_with(Vec::new)
                    .push(blind_status);
            }
        }

        rooms_map
    }

    pub fn get_rooms(&self) -> RoomsResponse {
        let rooms = self.config.get_rooms();
        RoomsResponse {
            rooms: rooms.clone(),
            total_rooms: rooms.len(),
            timestamp: chrono::Utc::now(),
        }
    }

    pub fn get_config(&self) -> ConfigResponse {
        let enabled_blinds: Vec<BlindStatus> = self
            .config
            .get_enabled_blinds()
            .into_iter()
            .map(|blind| BlindStatus::from(blind))
            .collect();

        ConfigResponse {
            mqtt: MqttConfigResponse {
                broker_host: self.config.mqtt.broker_host.clone(),
                broker_port: self.config.mqtt.broker_port,
                client_id: self.config.mqtt.client_id.clone(),
                username: self.config.mqtt.username.clone(),
                // Password intentionally omitted for security
            },
            server: ServerConfigResponse {
                host: self.config.server.host.clone(),
                port: self.config.server.port,
            },
            blinds: enabled_blinds.clone(),
            total_blinds: enabled_blinds.len(),
            timestamp: chrono::Utc::now(),
        }
    }

    fn get_room_info(&self) -> Vec<RoomInfo> {
        let blinds_by_room = self.config.get_blinds_map();
        let mut rooms = Vec::new();

        for (room_name, room_blinds) in blinds_by_room {
            let enabled_count = room_blinds.iter().filter(|blind| blind.enabled).count();
            let blind_ids: Vec<String> = room_blinds
                .iter()
                .filter(|blind| blind.enabled)
                .map(|blind| blind.id.clone())
                .collect();

            rooms.push(RoomInfo {
                name: room_name,
                blind_count: room_blinds.len(),
                enabled_blinds: enabled_count,
                blinds: blind_ids,
            });
        }

        // Sort rooms by name for consistent output
        rooms.sort_by(|a, b| a.name.cmp(&b.name));
        rooms
    }

    pub fn validate_blind_id(&self, blind_id: &str) -> Result<&BlindConfig, AppError> {
        self.config
            .get_blind_by_id(blind_id)
            .ok_or_else(|| AppError::BlindNotFound(blind_id.to_string()))
    }

    pub fn validate_room(&self, room: &str) -> Result<Vec<&BlindConfig>, AppError> {
        let room_blinds = self.config.get_blinds_by_room(room);
        if room_blinds.is_empty() {
            Err(AppError::RoomNotFound(room.to_string()))
        } else {
            Ok(room_blinds)
        }
    }

    pub async fn get_mqtt_info(&self) -> String {
        self.mqtt_service.get_client_info().await
    }
}

impl Clone for BlindService {
    fn clone(&self) -> Self {
        Self {
            mqtt_service: self.mqtt_service.clone(),
            config: Arc::clone(&self.config),
            start_time: self.start_time,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{MqttConfig, ServerConfig};
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
            blinds: vec![crate::config::BlindConfig {
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

    #[tokio::test]
    async fn test_validate_blind_id() {
        let config = Arc::new(create_test_config());
        let mqtt_options = MqttOptions::new("test", "localhost", 1883);
        let (client, _) = AsyncClient::new(mqtt_options, 10);
        let mqtt_service = MqttService::new(Arc::new(Mutex::new(client)));
        let blind_service = BlindService::new(mqtt_service, config);

        // Valid blind ID
        assert!(blind_service.validate_blind_id("test_blind").is_ok());

        // Invalid blind ID
        assert!(blind_service.validate_blind_id("nonexistent").is_err());
    }

    #[tokio::test]
    async fn test_validate_room() {
        let config = Arc::new(create_test_config());
        let mqtt_options = MqttOptions::new("test", "localhost", 1883);
        let (client, _) = AsyncClient::new(mqtt_options, 10);
        let mqtt_service = MqttService::new(Arc::new(Mutex::new(client)));
        let blind_service = BlindService::new(mqtt_service, config);

        // Valid room
        assert!(blind_service.validate_room("test_room").is_ok());

        // Invalid room
        assert!(blind_service.validate_room("nonexistent_room").is_err());
    }

    #[test]
    fn test_get_rooms() {
        let config = Arc::new(create_test_config());
        let mqtt_options = MqttOptions::new("test", "localhost", 1883);
        let (client, _) = AsyncClient::new(mqtt_options, 10);
        let mqtt_service = MqttService::new(Arc::new(Mutex::new(client)));
        let blind_service = BlindService::new(mqtt_service, config);

        let rooms_response = blind_service.get_rooms();
        assert_eq!(rooms_response.total_rooms, 1);
        assert!(rooms_response.rooms.contains(&"test_room".to_string()));
    }
}
