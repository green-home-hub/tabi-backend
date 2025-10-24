#!/bin/bash
# Run script para Tabi Backend
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
CONTAINER_NAME="tabi-backend"
IMAGE_NAME="tabi-backend:latest"
HTTP_PORT="8080"
MQTT_PORT="1883"

echo -e "${BLUE}🚀 Tabi Backend - Run Script${NC}"
echo "==============================="

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: $0 [COMANDO]${NC}"
    echo ""
    echo "Comandos disponibles:"
    echo "  start     - Iniciar contenedor"
    echo "  stop      - Detener contenedor"
    echo "  restart   - Reiniciar contenedor"
    echo "  logs      - Ver logs del contenedor"
    echo "  status    - Ver estado del contenedor"
    echo "  shell     - Abrir shell en el contenedor"
    echo "  test      - Probar API y MQTT"
    echo "  clean     - Limpiar contenedores e imágenes"
    echo "  compose   - Usar docker-compose (up/down/logs)"
    echo "  help      - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start"
    echo "  $0 logs -f"
    echo "  $0 compose up -d"
}

# Verificar que Docker está corriendo
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker no está corriendo${NC}"
        exit 1
    fi
}

# Verificar si la imagen existe
check_image() {
    if ! docker images $IMAGE_NAME --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
        echo -e "${YELLOW}⚠️  Imagen $IMAGE_NAME no encontrada${NC}"
        echo -e "${BLUE}💡 Ejecuta: ./scripts/build.sh primero${NC}"
        exit 1
    fi
}

# Iniciar contenedor
start_container() {
    echo -e "${BLUE}🚀 Iniciando contenedor...${NC}"

    # Detener contenedor existente si está corriendo
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${YELLOW}⚠️  Deteniendo contenedor existente...${NC}"
        docker stop $CONTAINER_NAME > /dev/null
    fi

    # Remover contenedor existente
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        docker rm $CONTAINER_NAME > /dev/null
    fi

    # Iniciar nuevo contenedor
    docker run -d \
        --name $CONTAINER_NAME \
        -p $HTTP_PORT:8080 \
        -p $MQTT_PORT:1883 \
        -v "$(pwd)/config.json:/app/config.json:ro" \
        --restart unless-stopped \
        $IMAGE_NAME

    echo -e "${GREEN}✅ Contenedor iniciado correctamente${NC}"
    echo -e "${BLUE}📡 API disponible en: http://localhost:$HTTP_PORT${NC}"
    echo -e "${BLUE}🔗 MQTT Broker en: localhost:$MQTT_PORT${NC}"
}

# Detener contenedor
stop_container() {
    echo -e "${BLUE}🛑 Deteniendo contenedor...${NC}"
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        docker stop $CONTAINER_NAME
        echo -e "${GREEN}✅ Contenedor detenido${NC}"
    else
        echo -e "${YELLOW}⚠️  Contenedor no está corriendo${NC}"
    fi
}

# Ver logs
show_logs() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${BLUE}📋 Logs del contenedor:${NC}"
        docker logs $@ $CONTAINER_NAME
    else
        echo -e "${RED}❌ Contenedor no está corriendo${NC}"
        exit 1
    fi
}

# Ver estado
show_status() {
    echo -e "${BLUE}📊 Estado del sistema:${NC}"
    echo ""

    # Estado del contenedor
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${GREEN}✅ Contenedor: CORRIENDO${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" -f name=$CONTAINER_NAME
    else
        echo -e "${RED}❌ Contenedor: DETENIDO${NC}"
    fi

    echo ""

    # Test de conectividad
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${BLUE}🔍 Testing conectividad...${NC}"

        # Test HTTP API
        if curl -s "http://localhost:$HTTP_PORT/hello-world" > /dev/null; then
            echo -e "${GREEN}✅ API HTTP: OK${NC}"
        else
            echo -e "${RED}❌ API HTTP: FALLO${NC}"
        fi

        # Test MQTT
        if command -v mosquitto_pub > /dev/null; then
            if timeout 5 mosquitto_pub -h localhost -p $MQTT_PORT -t test -m "ping" 2>/dev/null; then
                echo -e "${GREEN}✅ MQTT Broker: OK${NC}"
            else
                echo -e "${RED}❌ MQTT Broker: FALLO${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  mosquitto_pub no disponible para test MQTT${NC}"
        fi
    fi
}

# Abrir shell
open_shell() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${BLUE}💻 Abriendo shell en el contenedor...${NC}"
        docker exec -it $CONTAINER_NAME /bin/sh
    else
        echo -e "${RED}❌ Contenedor no está corriendo${NC}"
        exit 1
    fi
}

# Test de funcionalidad
test_api() {
    if ! docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${RED}❌ Contenedor no está corriendo${NC}"
        exit 1
    fi

    echo -e "${BLUE}🧪 Probando API y MQTT...${NC}"
    echo ""

    # Test API endpoints
    echo -e "${BLUE}📡 Testing API endpoints:${NC}"

    # Hello world
    echo -n "  - GET /hello-world: "
    if curl -s "http://localhost:$HTTP_PORT/hello-world" | grep -q "Hello world"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi

    # Config
    echo -n "  - GET /blinds/config: "
    if curl -s "http://localhost:$HTTP_PORT/blinds/config" | grep -q "mqtt"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi

    # Status
    echo -n "  - GET /blinds/status: "
    if curl -s "http://localhost:$HTTP_PORT/blinds/status" | grep -q "rooms"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi

    echo ""
    echo -e "${BLUE}📨 Testing MQTT (desde dentro del contenedor):${NC}"

    # Test MQTT interno
    echo -n "  - MQTT publish test: "
    if docker exec $CONTAINER_NAME mosquitto_pub -h localhost -t test -m "hello" 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
}

# Limpiar contenedores e imágenes
clean_all() {
    echo -e "${YELLOW}🧹 Limpiando contenedores e imágenes...${NC}"

    # Detener y remover contenedor
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        echo -e "${GREEN}✅ Contenedor removido${NC}"
    fi

    # Remover imagen
    if docker images $IMAGE_NAME --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
        docker rmi $IMAGE_NAME 2>/dev/null || true
        echo -e "${GREEN}✅ Imagen removida${NC}"
    fi

    # Limpiar imágenes colgantes
    docker image prune -f > /dev/null 2>&1 || true
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Docker compose wrapper
compose_cmd() {
    shift # Remover 'compose' del array de argumentos
    if [ $# -eq 0 ]; then
        echo -e "${BLUE}📋 Comandos docker-compose disponibles:${NC}"
        echo "  up      - Iniciar servicios"
        echo "  up -d   - Iniciar en background"
        echo "  down    - Detener servicios"
        echo "  logs    - Ver logs"
        echo "  logs -f - Ver logs en tiempo real"
        echo ""
        echo "Ejemplo: $0 compose up -d"
        return
    fi

    echo -e "${BLUE}🐳 Ejecutando: docker-compose $@${NC}"
    docker-compose "$@"
}

# Comando principal
case "${1:-help}" in
    start)
        check_docker
        check_image
        start_container
        ;;
    stop)
        check_docker
        stop_container
        ;;
    restart)
        check_docker
        check_image
        stop_container
        sleep 2
        start_container
        ;;
    logs)
        check_docker
        shift
        show_logs "$@"
        ;;
    status)
        check_docker
        show_status
        ;;
    shell)
        check_docker
        open_shell
        ;;
    test)
        check_docker
        test_api
        ;;
    clean)
        check_docker
        clean_all
        ;;
    compose)
        check_docker
        compose_cmd "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando no reconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
