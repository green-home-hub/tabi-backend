use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlindConfig {
    pub id: String,
    pub name: String,
    pub room: String,
    pub mqtt_topic: String,
    pub device_type: String,
    pub enabled: bool,
    pub battery_topic: Option<String>,
    pub status_topic: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub mqtt: MqttConfig,
    pub server: ServerConfig,
    pub blinds: Vec<BlindConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MqttConfig {
    pub broker_host: String,
    pub broker_port: u16,
    pub client_id: String,
    pub keep_alive_secs: u64,
    pub username: Option<String>,
    pub password: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            mqtt: MqttConfig {
                broker_host: "localhost".to_string(),
                broker_port: 1883,
                client_id: "tabi-backend".to_string(),
                keep_alive_secs: 5,
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
                    name: "Persiana Dormitorio Principal".to_string(),
                    room: "bedroom".to_string(),
                    mqtt_topic: "home/blinds/bedroom/control".to_string(),
                    device_type: "motorized_blind".to_string(),
                    enabled: true,
                    battery_topic: Some("home/blinds/bedroom/battery".to_string()),
                    status_topic: Some("home/blinds/bedroom/status".to_string()),
                },
                BlindConfig {
                    id: "blind_002".to_string(),
                    name: "Persiana Sala".to_string(),
                    room: "living".to_string(),
                    mqtt_topic: "home/blinds/living/control".to_string(),
                    device_type: "motorized_blind".to_string(),
                    enabled: true,
                    battery_topic: Some("home/blinds/living/battery".to_string()),
                    status_topic: Some("home/blinds/living/status".to_string()),
                },
                BlindConfig {
                    id: "blind_003".to_string(),
                    name: "Persiana Cocina".to_string(),
                    room: "kitchen".to_string(),
                    mqtt_topic: "home/blinds/kitchen/control".to_string(),
                    device_type: "motorized_blind".to_string(),
                    enabled: true,
                    battery_topic: Some("home/blinds/kitchen/battery".to_string()),
                    status_topic: Some("home/blinds/kitchen/status".to_string()),
                },
            ],
        }
    }
}

impl AppConfig {
    /// Carga la configuración desde un archivo JSON
    pub fn load_from_file<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let content = fs::read_to_string(path)?;
        let config: AppConfig = serde_json::from_str(&content)?;
        Ok(config)
    }

    /// Guarda la configuración actual en un archivo JSON
    pub fn save_to_file<P: AsRef<Path>>(&self, path: P) -> Result<(), Box<dyn std::error::Error>> {
        let content = serde_json::to_string_pretty(self)?;
        fs::write(path, content)?;
        Ok(())
    }

    /// Carga la configuración desde archivo o crea una por defecto
    pub fn load_or_default<P: AsRef<Path>>(path: P) -> Self {
        match Self::load_from_file(&path) {
            Ok(config) => {
                println!(
                    "✅ Configuración cargada desde: {}",
                    path.as_ref().display()
                );
                config
            }
            Err(e) => {
                println!(
                    "⚠️  Error cargando configuración: {}. Usando configuración por defecto.",
                    e
                );
                let default_config = Self::default();
                if let Err(save_error) = default_config.save_to_file(&path) {
                    eprintln!(
                        "❌ Error guardando configuración por defecto: {}",
                        save_error
                    );
                } else {
                    println!(
                        "✅ Configuración por defecto guardada en: {}",
                        path.as_ref().display()
                    );
                }
                default_config
            }
        }
    }

    /// Obtiene una persiana por su ID
    pub fn get_blind_by_id(&self, id: &str) -> Option<&BlindConfig> {
        self.blinds.iter().find(|blind| blind.id == id)
    }

    /// Obtiene persianas por habitación
    pub fn get_blinds_by_room(&self, room: &str) -> Vec<&BlindConfig> {
        self.blinds
            .iter()
            .filter(|blind| blind.room == room && blind.enabled)
            .collect()
    }

    /// Obtiene todas las persianas habilitadas
    pub fn get_enabled_blinds(&self) -> Vec<&BlindConfig> {
        self.blinds.iter().filter(|blind| blind.enabled).collect()
    }

    /// Obtiene todas las habitaciones únicas
    pub fn get_rooms(&self) -> Vec<String> {
        let mut rooms: Vec<String> = self
            .blinds
            .iter()
            .filter(|blind| blind.enabled)
            .map(|blind| blind.room.clone())
            .collect();
        rooms.sort();
        rooms.dedup();
        rooms
    }

    /// Crea un mapa de persianas por habitación para acceso rápido
    pub fn get_blinds_map(&self) -> HashMap<String, Vec<&BlindConfig>> {
        let mut map: HashMap<String, Vec<&BlindConfig>> = HashMap::new();

        for blind in &self.blinds {
            if blind.enabled {
                map.entry(blind.room.clone())
                    .or_insert_with(Vec::new)
                    .push(blind);
            }
        }

        map
    }

    /// Valida la configuración
    pub fn validate(&self) -> Result<(), String> {
        if self.blinds.is_empty() {
            return Err("No hay persianas configuradas".to_string());
        }

        // Verificar IDs únicos
        let mut ids = std::collections::HashSet::new();
        for blind in &self.blinds {
            if !ids.insert(&blind.id) {
                return Err(format!("ID de persiana duplicado: {}", blind.id));
            }
        }

        // Verificar que los temas MQTT no estén vacíos
        for blind in &self.blinds {
            if blind.mqtt_topic.trim().is_empty() {
                return Err(format!("Tema MQTT vacío para persiana: {}", blind.id));
            }
        }

        Ok(())
    }

    /// Agrega una nueva persiana a la configuración
    pub fn add_blind(&mut self, blind: BlindConfig) -> Result<(), String> {
        // Verificar que el ID no exista
        if self.get_blind_by_id(&blind.id).is_some() {
            return Err(format!("Ya existe una persiana con ID: {}", blind.id));
        }

        self.blinds.push(blind);
        Ok(())
    }

    /// Actualiza una persiana existente
    pub fn update_blind(&mut self, blind: BlindConfig) -> Result<(), String> {
        if let Some(existing) = self.blinds.iter_mut().find(|b| b.id == blind.id) {
            *existing = blind;
            Ok(())
        } else {
            Err(format!("No se encontró persiana con ID: {}", blind.id))
        }
    }

    /// Habilita o deshabilita una persiana
    pub fn set_blind_enabled(&mut self, id: &str, enabled: bool) -> Result<(), String> {
        if let Some(blind) = self.blinds.iter_mut().find(|b| b.id == id) {
            blind.enabled = enabled;
            Ok(())
        } else {
            Err(format!("No se encontró persiana con ID: {}", id))
        }
    }

    /// Elimina una persiana de la configuración
    pub fn remove_blind(&mut self, id: &str) -> Result<BlindConfig, String> {
        if let Some(pos) = self.blinds.iter().position(|b| b.id == id) {
            Ok(self.blinds.remove(pos))
        } else {
            Err(format!("No se encontró persiana con ID: {}", id))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;

    #[test]
    fn test_default_config() {
        let config = AppConfig::default();
        assert_eq!(config.blinds.len(), 3);
        assert_eq!(config.mqtt.broker_host, "localhost");
        assert_eq!(config.server.port, 8080);
    }

    #[test]
    fn test_get_blind_by_id() {
        let config = AppConfig::default();
        let blind = config.get_blind_by_id("blind_001");
        assert!(blind.is_some());
        assert_eq!(blind.unwrap().room, "bedroom");
    }

    #[test]
    fn test_get_blinds_by_room() {
        let config = AppConfig::default();
        let bedroom_blinds = config.get_blinds_by_room("bedroom");
        assert_eq!(bedroom_blinds.len(), 1);
        assert_eq!(bedroom_blinds[0].id, "blind_001");
    }

    #[test]
    fn test_get_rooms() {
        let config = AppConfig::default();
        let rooms = config.get_rooms();
        assert_eq!(rooms.len(), 3);
        assert!(rooms.contains(&"bedroom".to_string()));
        assert!(rooms.contains(&"living".to_string()));
        assert!(rooms.contains(&"kitchen".to_string()));
    }

    #[test]
    fn test_validate() {
        let config = AppConfig::default();
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_save_and_load() {
        let config = AppConfig::default();
        let temp_file = NamedTempFile::new().unwrap();

        // Guardar
        config.save_to_file(temp_file.path()).unwrap();

        // Cargar
        let loaded_config = AppConfig::load_from_file(temp_file.path()).unwrap();
        assert_eq!(config.blinds.len(), loaded_config.blinds.len());
        assert_eq!(config.mqtt.broker_host, loaded_config.mqtt.broker_host);
    }

    #[test]
    fn test_add_blind() {
        let mut config = AppConfig::default();
        let initial_count = config.blinds.len();

        let new_blind = BlindConfig {
            id: "blind_004".to_string(),
            name: "Persiana Baño".to_string(),
            room: "bathroom".to_string(),
            mqtt_topic: "home/blinds/bathroom/control".to_string(),
            device_type: "motorized_blind".to_string(),
            enabled: true,
            battery_topic: None,
            status_topic: None,
        };

        assert!(config.add_blind(new_blind).is_ok());
        assert_eq!(config.blinds.len(), initial_count + 1);
    }
}
