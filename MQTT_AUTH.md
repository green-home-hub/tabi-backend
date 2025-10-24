# MQTT Authentication Setup for Tabi Backend

This document describes the MQTT authentication configuration for the Tabi Backend system using Mosquitto broker.

## Overview

The Tabi Backend uses Mosquitto MQTT broker with username/password authentication and Access Control Lists (ACL) for secure communication with IoT devices.

## Authentication Configuration

### Default User

- **Username**: `tabi-backend`
- **Password**: `TabiMQTT2024!`
- **Permissions**: Full access to all home automation topics

### Security Features

1. **Password Authentication**: Users must authenticate with username/password
2. **No Anonymous Access**: Anonymous connections are disabled
3. **Access Control Lists (ACL)**: Fine-grained topic permissions
4. **Encrypted Passwords**: Passwords are hashed using Mosquitto's built-in hashing

## File Structure

```
tabi-backend/
├── mosquitto_acl              # ACL permissions file
├── setup-mosquitto-auth.sh    # Authentication setup script
├── add-mqtt-user.sh           # Script to add new users
└── config.json                # Backend configuration with MQTT credentials
```

## Configuration Files

### 1. Password File
Location: `/etc/mosquitto/auth/passwd` (inside container)
- Contains hashed passwords for all MQTT users
- Generated automatically during Docker build

### 2. ACL File
Location: `/etc/mosquitto/auth/acl` (inside container)
- Defines topic-level permissions for each user
- Allows fine-grained access control

### 3. Mosquitto Configuration
Location: `/etc/mosquitto/conf.d/auth.conf` (inside container)
- Enables password authentication
- Disables anonymous access
- References password and ACL files

## Topic Permissions

The `tabi-backend` user has access to the following topic patterns:

### Home Automation Topics
- `home/+/+/+` (read/write) - General home automation
- `home/blinds/+/control` (read/write) - Blind control commands
- `home/blinds/+/status` (read/write) - Blind status updates
- `home/blinds/+/battery` (read/write) - Battery level reports

### System Topics
- `$SYS/broker/+` (read) - Broker statistics
- `system/tabi-backend/+` (write) - Backend system status
- `config/+` (read/write) - Configuration topics

### Emergency Topics
- `emergency/+` (read/write) - Emergency commands and status

### Logging Topics
- `logs/tabi-backend/+` (write) - Application logs
- `diagnostics/tabi-backend/+` (write) - Diagnostic information

## Adding New Users

### Using Docker Exec (Recommended)

```bash
# Access the running container
docker exec -it tabi-backend sh

# Add a new user
mosquitto_passwd -b /etc/mosquitto/auth/passwd new-username new-password

# Reload Mosquitto configuration
pkill -HUP mosquitto
```

### Using the Add User Script

```bash
# Copy the script to the container
docker cp add-mqtt-user.sh tabi-backend:/tmp/

# Execute the script
docker exec -it tabi-backend sh /tmp/add-mqtt-user