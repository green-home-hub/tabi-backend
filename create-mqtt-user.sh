#!/bin/sh

# Simple script to create Mosquitto user for tabi-backend
echo "🔐 Creating Mosquitto user for tabi-backend..."

# Create password file with hashed password
mosquitto_passwd -c -b mosquitto_passwd tabi-backend "TabiMQTT2024!"

echo "✅ Password file created: mosquitto_passwd"
echo "📋 User: tabi-backend"
echo "🔑 Password: TabiMQTT2024!"
echo ""
echo "To rebuild container with authentication:"
echo "docker-compose down && docker-compose build --no-cache && docker-compose up"
