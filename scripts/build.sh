#!/bin/bash
# Build script optimizado para Tabi Backend
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
IMAGE_NAME="tabi-backend"
TAG="latest"
DOCKERFILE="Dockerfile"

echo -e "${BLUE}🔨 Tabi Backend - Build Script${NC}"
echo "=================================="

# Verificar que Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker no está corriendo${NC}"
    exit 1
fi

# Verificar archivos necesarios
if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}❌ Error: $DOCKERFILE no encontrado${NC}"
    exit 1
fi

if [ ! -f "config.json" ]; then
    echo -e "${YELLOW}⚠️  Advertencia: config.json no encontrado, usando configuración por defecto${NC}"
fi

echo -e "${BLUE}📋 Información del build:${NC}"
echo "  - Imagen: $IMAGE_NAME:$TAG"
echo "  - Dockerfile: $DOCKERFILE"
echo "  - Contexto: $(pwd)"

# Limpiar builds anteriores (opcional)
if [ "$1" = "--clean" ]; then
    echo -e "${YELLOW}🧹 Limpiando imágenes anteriores...${NC}"
    docker rmi $IMAGE_NAME:$TAG 2>/dev/null || true
    docker builder prune -f
fi

# Build de la imagen
echo -e "${BLUE}🔨 Construyendo imagen Docker...${NC}"
docker build \
    --tag $IMAGE_NAME:$TAG \
    --file $DOCKERFILE \
    --progress=plain \
    .

# Verificar que el build fue exitoso
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build completado exitosamente${NC}"

    # Mostrar información de la imagen
    IMAGE_SIZE=$(docker images $IMAGE_NAME:$TAG --format "table {{.Size}}" | tail -n 1)
    echo -e "${GREEN}📦 Tamaño de imagen: $IMAGE_SIZE${NC}"

    # Mostrar layers (opcional)
    if [ "$1" = "--verbose" ] || [ "$2" = "--verbose" ]; then
        echo -e "${BLUE}📋 Layers de la imagen:${NC}"
        docker history $IMAGE_NAME:$TAG --no-trunc
    fi

    echo ""
    echo -e "${BLUE}🚀 Comandos útiles:${NC}"
    echo "  # Ejecutar contenedor:"
    echo "    docker run -p 8080:8080 -p 1883:1883 $IMAGE_NAME:$TAG"
    echo ""
    echo "  # Con docker-compose:"
    echo "    docker-compose up"
    echo ""
    echo "  # Ver logs:"
    echo "    docker logs tabi-backend"
    echo ""
    echo "  # Testing MQTT:"
    echo "    docker exec tabi-backend mosquitto_pub -t test -m 'hello'"

else
    echo -e "${RED}❌ Error en el build${NC}"
    exit 1
fi
