use crate::errors::AppError;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum BlindCommand {
    Open,
    Close,
    Stop,
}

impl BlindCommand {
    pub fn as_str(&self) -> &'static str {
        match self {
            BlindCommand::Open => "OPEN",
            BlindCommand::Close => "CLOSE",
            BlindCommand::Stop => "STOP",
        }
    }
}

impl FromStr for BlindCommand {
    type Err = AppError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_uppercase().as_str() {
            "OPEN" => Ok(BlindCommand::Open),
            "CLOSE" => Ok(BlindCommand::Close),
            "STOP" => Ok(BlindCommand::Stop),
            _ => Err(AppError::InvalidAction(s.to_string())),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlindStatus {
    pub id: String,
    pub name: String,
    pub room: String,
    pub device_type: String,
    pub mqtt_topic: String,
    pub status_topic: Option<String>,
    pub battery_topic: Option<String>,
    pub enabled: bool,
    pub last_command: Option<BlindCommand>,
    pub last_update: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlindControlRequest {
    pub action: BlindCommand,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoomInfo {
    pub name: String,
    pub blind_count: usize,
    pub enabled_blinds: usize,
    pub blinds: Vec<String>, // blind IDs
}

impl BlindControlRequest {
    pub fn new(action: BlindCommand) -> Self {
        Self {
            action,
            timestamp: chrono::Utc::now(),
        }
    }
}

impl From<&crate::config::BlindConfig> for BlindStatus {
    fn from(blind_config: &crate::config::BlindConfig) -> Self {
        Self {
            id: blind_config.id.clone(),
            name: blind_config.name.clone(),
            room: blind_config.room.clone(),
            device_type: blind_config.device_type.clone(),
            mqtt_topic: blind_config.mqtt_topic.clone(),
            status_topic: blind_config.status_topic.clone(),
            battery_topic: blind_config.battery_topic.clone(),
            enabled: blind_config.enabled,
            last_command: None,
            last_update: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_blind_command_from_str() {
        assert_eq!(BlindCommand::from_str("OPEN").unwrap(), BlindCommand::Open);
        assert_eq!(BlindCommand::from_str("open").unwrap(), BlindCommand::Open);
        assert_eq!(
            BlindCommand::from_str("CLOSE").unwrap(),
            BlindCommand::Close
        );
        assert_eq!(
            BlindCommand::from_str("close").unwrap(),
            BlindCommand::Close
        );
        assert_eq!(BlindCommand::from_str("STOP").unwrap(), BlindCommand::Stop);
        assert_eq!(BlindCommand::from_str("stop").unwrap(), BlindCommand::Stop);

        assert!(BlindCommand::from_str("invalid").is_err());
    }

    #[test]
    fn test_blind_command_as_str() {
        assert_eq!(BlindCommand::Open.as_str(), "OPEN");
        assert_eq!(BlindCommand::Close.as_str(), "CLOSE");
        assert_eq!(BlindCommand::Stop.as_str(), "STOP");
    }

    #[test]
    fn test_blind_control_request_new() {
        let request = BlindControlRequest::new(BlindCommand::Open);
        assert_eq!(request.action, BlindCommand::Open);
        assert!(request.timestamp <= chrono::Utc::now());
    }
}
