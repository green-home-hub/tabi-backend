# Multi-stage Dockerfile optimizado para Tabi Backend + Mosquitto
# Imagen final: ~25-30MB

#=============================================================================
# Stage 1: Build de la aplicación Rust
#=============================================================================
FROM rust:1.90-alpine AS builder

# Instalar dependencias de build
RUN apk add --no-cache \
    musl-dev \
    pkgconfig \
    openssl-dev

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias primero (para cache layer)
COPY Cargo.toml ./

# Crear un proyecto dummy para cachear dependencias
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copiar código fuente real
COPY src ./src

# Build optimizado de la aplicación
RUN cargo build --release --locked

#=============================================================================
# Stage 2: Runtime con Mosquitto + App
#=============================================================================
FROM alpine:3.22

# Instalar Mosquitto y dependencias mínimas
RUN apk add --no-cache \
    mosquitto \
    mosquitto-clients \
    ca-certificates \
    tzdata && \
    rm -rf /var/cache/apk/*

# Crear usuario no-root
RUN addgroup -g 1001 -S tabi && \
    adduser -u 1001 -S tabi -G tabi

# Crear directorios necesarios
RUN mkdir -p /app /etc/mosquitto/conf.d /var/log/mosquitto && \
    chown -R tabi:tabi /app /var/log/mosquitto

# Copiar binario desde builder
COPY --from=builder /app/target/release/tabi-backend /app/

# Crear directorios de autenticación MQTT
RUN mkdir -p /etc/mosquitto/auth

# Configuración básica de Mosquitto con autenticación
RUN echo "listener 1883" > /etc/mosquitto/conf.d/tabi.conf && \
    echo "allow_anonymous false" >> /etc/mosquitto/conf.d/tabi.conf && \
    echo "password_file /etc/mosquitto/auth/passwd" >> /etc/mosquitto/conf.d/tabi.conf && \
    echo "acl_file /etc/mosquitto/auth/acl" >> /etc/mosquitto/conf.d/tabi.conf && \
    echo "log_dest file /var/log/mosquitto/mosquitto.log" >> /etc/mosquitto/conf.d/tabi.conf

# Generar archivo de contraseña MQTT para el usuario tabi-backend
RUN mosquitto_passwd -c -b /etc/mosquitto/auth/passwd tabi-backend "TabiMQTT2024!"

# Copiar configuración de la app y ACL de MQTT
COPY config.json /app/
COPY mosquitto/mosquitto_acl /etc/mosquitto/auth/acl

# Cambiar ownership
RUN chown -R tabi:tabi /app

# Cambiar a usuario no-root
USER tabi

# Directorio de trabajo
WORKDIR /app

# Exponer puertos
EXPOSE 8080 1883

# Script de inicio que ejecuta Mosquitto + App
COPY --chown=tabi:tabi <<EOF /app/start.sh
#!/bin/sh
echo "🚀 Iniciando Tabi Backend..."

# Iniciar Mosquitto en background
echo "📡 Iniciando Mosquitto MQTT Broker..."
mosquitto -c /etc/mosquitto/mosquitto.conf -d

# Esperar un momento para que Mosquitto inicie
sleep 2

# Verificar que Mosquitto está corriendo
if ! pgrep mosquitto > /dev/null; then
    echo "❌ Error: Mosquitto no pudo iniciar"
    exit 1
fi

echo "✅ Mosquitto iniciado correctamente"

# Iniciar la aplicación Rust
echo "🏠 Iniciando Tabi Backend API..."
exec ./tabi-backend
EOF

RUN chmod +x /app/start.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/hello-world || exit 1

# Comando por defecto
CMD ["/app/start.sh"]
