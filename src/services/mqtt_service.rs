use crate::errors::AppError;
use rumqttc::{AsyncClient, QoS};
use std::sync::Arc;
use tokio::sync::Mutex;

pub struct MqttService {
    client: Arc<Mutex<AsyncClient>>,
    connected: Arc<Mutex<bool>>,
}

impl MqttService {
    pub fn new(client: Arc<Mutex<AsyncClient>>) -> Self {
        Self {
            client,
            connected: Arc::new(Mutex::new(false)),
        }
    }

    pub async fn publish_command(&self, topic: &str, payload: &str) -> Result<(), AppError> {
        let client = self.client.lock().await;

        client
            .publish(topic, QoS::AtLeastOnce, false, payload)
            .await
            .map_err(|e| {
                log::error!("MQTT publish failed for topic '{}': {}", topic, e);
                AppError::MqttError(e)
            })?;

        log::info!("MQTT command sent - Topic: {}, Payload: {}", topic, payload);
        Ok(())
    }

    pub async fn is_connected(&self) -> bool {
        *self.connected.lock().await
    }

    pub async fn set_connected(&self, status: bool) {
        let mut connected = self.connected.lock().await;
        *connected = status;

        if status {
            log::info!("MQTT connection established");
        } else {
            log::warn!("MQTT connection lost");
        }
    }

    pub async fn subscribe_to_topic(&self, topic: &str) -> Result<(), AppError> {
        let client = self.client.lock().await;

        client
            .subscribe(topic, QoS::AtMostOnce)
            .await
            .map_err(|e| {
                log::error!("MQTT subscribe failed for topic '{}': {}", topic, e);
                AppError::MqttError(e)
            })?;

        log::info!("Subscribed to MQTT topic: {}", topic);
        Ok(())
    }

    pub async fn unsubscribe_from_topic(&self, topic: &str) -> Result<(), AppError> {
        let client = self.client.lock().await;

        client.unsubscribe(topic).await.map_err(|e| {
            log::error!("MQTT unsubscribe failed for topic '{}': {}", topic, e);
            AppError::MqttError(e)
        })?;

        log::info!("Unsubscribed from MQTT topic: {}", topic);
        Ok(())
    }

    pub async fn get_client_info(&self) -> String {
        format!("MQTT Service - Connected: {}", self.is_connected().await)
    }
}

impl Clone for MqttService {
    fn clone(&self) -> Self {
        Self {
            client: Arc::clone(&self.client),
            connected: Arc::clone(&self.connected),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rumqttc::MqttOptions;
    use tokio;

    #[tokio::test]
    async fn test_mqtt_service_creation() {
        let mqtt_options = MqttOptions::new("test_client", "localhost", 1883);
        let (client, _eventloop) = AsyncClient::new(mqtt_options, 10);
        let mqtt_service = MqttService::new(Arc::new(Mutex::new(client)));

        assert!(!mqtt_service.is_connected().await);
    }

    #[tokio::test]
    async fn test_connection_status() {
        let mqtt_options = MqttOptions::new("test_client", "localhost", 1883);
        let (client, _eventloop) = AsyncClient::new(mqtt_options, 10);
        let mqtt_service = MqttService::new(Arc::new(Mutex::new(client)));

        mqtt_service.set_connected(true).await;
        assert!(mqtt_service.is_connected().await);

        mqtt_service.set_connected(false).await;
        assert!(!mqtt_service.is_connected().await);
    }

    #[tokio::test]
    async fn test_clone() {
        let mqtt_options = MqttOptions::new("test_client", "localhost", 1883);
        let (client, _eventloop) = AsyncClient::new(mqtt_options, 10);
        let mqtt_service = MqttService::new(Arc::new(Mutex::new(client)));

        let cloned_service = mqtt_service.clone();

        mqtt_service.set_connected(true).await;
        assert!(cloned_service.is_connected().await);
    }
}
