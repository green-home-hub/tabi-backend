# Tabi Backend - Control de Persianas MQTT

Sistema simple para controlar persianas electrónicas vía MQTT y API REST con Docker integrado.

## ⚡ Inicio Súper Rápido

### Primera vez (Setup completo)
```bash
# Inicialización automática - hace todo por ti
./tabi init
```

### Uso diario
```bash
./tabi dev          # Iniciar entorno de desarrollo
./tabi status       # Ver estado del sistema
./tabi logs -f      # Ver logs en tiempo real
./tabi help         # Ver todos los comandos disponibles
```

## 🎮 CLI Principal - `./tabi`

El proyecto incluye un CLI unificado que simplifica todas las operaciones:

```bash
./tabi <comando> [opciones]
```

**Comandos principales:**
- `init` - Setup inicial completo
- `dev` - Iniciar desarrollo rápido
- `build` - Construir imagen Docker
- `start/stop/restart` - Control del servicio
- `logs` - Ver logs (usa `-f` para seguir)
- `status` - Estado y tests de conectividad
- `test` - Probar API y MQTT
- `up/down` - Docker Compose shortcuts
- `help` - Ayuda completa

## 🚀 Inicio Rápido con Docker

### 1. Build y Run (Una sola línea)
```bash
# Build la imagen y ejecutar
./tabi build && ./tabi start
```

### 2. Con Docker Compose (Recomendado)
```bash
# Iniciar todo el stack
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

## 📋 Configuración

Edita `config.json` con tus dispositivos:

```json
{
  "mqtt": {
    "broker_host": "localhost",
    "broker_port": 1883,
    "client_id": "tabi-backend"
  },
  "server": {
    "host": "0.0.0.0", 
    "port": 8080
  },
  "blinds": [
    {
      "id": "blind_001",
      "name": "Persiana Dormitorio",
      "room": "bedroom", 
      "mqtt_topic": "home/blinds/bedroom/control",
      "device_type": "motorized_blind",
      "enabled": true
    }
  ]
}
```

## 🔧 Scripts de Gestión

### Build Script
```bash
./tabi build           # Build optimizado
./tabi build --clean   # Build limpio
./tabi build --verbose # Build con detalles
```

### Run Script
```bash
./tabi start      # Iniciar contenedor
./tabi stop       # Detener contenedor
./tabi restart    # Reiniciar contenedor
./tabi logs       # Ver logs
./tabi logs -f    # Ver logs en tiempo real
./tabi status     # Estado del sistema
./tabi test       # Probar API y MQTT
./tabi shell      # Abrir shell en contenedor
./tabi clean      # Limpiar todo
```

### Docker Compose
```bash
./tabi up         # Iniciar en background
./tabi down       # Detener todo
./tabi ps         # Ver servicios activos
```

## 📡 API Endpoints

Una vez ejecutando (http://localhost:8080):

### Control Individual
```bash
# Abrir persiana específica
curl -X POST http://localhost:8080/blinds/id/blind_001/open

# Cerrar persiana específica  
curl -X POST http://localhost:8080/blinds/id/blind_001/close

# Detener persiana específica
curl -X POST http://localhost:8080/blinds/id/blind_001/stop
```

### Control por Habitación
```bash
# Abrir todas las persianas del dormitorio
curl -X POST http://localhost:8080/blinds/room/bedroom/open

# Cerrar todas las persianas de la sala
curl -X POST http://localhost:8080/blinds/room/living/close
```

### Control Global
```bash
# Abrir todas las persianas
curl -X POST http://localhost:8080/blinds/all/open

# Cerrar todas las persianas
curl -X POST http://localhost:8080/blinds/all/close
```

### Información del Sistema
```bash
# Ver configuración
curl http://localhost:8080/blinds/config

# Ver estado de persianas
curl http://localhost:8080/blinds/status

# Ver habitaciones
curl http://localhost:8080/blinds/rooms

# Test básico
curl http://localhost:8080/hello-world
```

## 🔌 Testing MQTT

El broker MQTT está disponible en `localhost:1883`:

```bash
# Publicar comando (desde host)
mosquitto_pub -h localhost -p 1883 -t "home/blinds/bedroom/control" -m "OPEN"

# Escuchar respuestas (desde host)
mosquitto_sub -h localhost -p 1883 -t "home/blinds/+/status"

# Desde dentro del contenedor
docker exec tabi-backend mosquitto_pub -t test -m "hello"
```

## 📊 Monitoreo

### Ver Estado del Sistema
```bash
./tabi status
```

### Logs en Tiempo Real
```bash
# Logs del contenedor
./tabi logs -f

# Logs con docker-compose
./tabi down && ./tabi up && ./tabi logs -f
```

### Health Check
```bash
# El contenedor incluye health check automático
docker ps  # Ver estado HEALTHY
```

## 🏗️ Arquitectura del Contenedor

- **Imagen base**: Alpine Linux (mínima)
- **Tamaño final**: ~25-30MB
- **Multi-stage build**: Optimización máxima
- **Servicios**: Tabi Backend + Mosquitto MQTT
- **Puertos**: 8080 (HTTP) + 1883 (MQTT)
- **Usuario**: No-root para seguridad

## 🔧 Desarrollo Local (sin Docker)

Si prefieres ejecutar localmente:

```bash
# Instalar Mosquitto
sudo apt install mosquitto mosquitto-clients  # Linux
# o descargar desde mosquitto.org para Windows

# Ejecutar Mosquitto
mosquitto -v

# Ejecutar la aplicación
cargo run
```

## 📋 Agregar Nuevas Persianas

1. Edita `config.json`:
```json
{
  "id": "blind_003",
  "name": "Persiana Cocina", 
  "room": "kitchen",
  "mqtt_topic": "home/blinds/kitchen/control",
  "device_type": "motorized_blind",
  "enabled": true
}
```

2. Reinicia el contenedor:
```bash
./tabi restart
```

## 🛠️ Troubleshooting

### Contenedor no inicia
```bash
# Ver logs detallados
./tabi logs

# Verificar configuración
cat config.json | jq .

# Reconstruir imagen
./tabi build --clean
```

### MQTT no conecta
```bash
# Test MQTT broker
./tabi shell
mosquitto_pub -t test -m hello

# Test completo del sistema
./tabi test

# Verificar puerto
netstat -tulpn | grep 1883
```

### API no responde
```bash
# Verificar puerto HTTP
curl http://localhost:8080/hello-world

# Ver logs de la aplicación
docker logs tabi-backend
```

## 📈 Optimizaciones

- ✅ Multi-stage Docker build
- ✅ Cache de dependencias Rust
- ✅ Imagen Alpine mínima
- ✅ Usuario no-root
- ✅ Health checks automáticos
- ✅ Scripts de gestión completos
- ✅ Configuración via volúmenes

---

**Listo para producción**: La imagen está optimizada para uso en Raspberry Pi, servidores locales o cloud.