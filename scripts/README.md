# Scripts Directory

This directory contains utility scripts for building, running, and managing the Tabi Backend project.

## Available Scripts

### 🔨 `build.sh`
**Purpose**: Docker image build script with advanced features and optimizations.

**Usage**:
```bash
./scripts/build.sh [OPTIONS]
```

**Options**:
- `--clean` - Remove previous images and prune builder cache before building
- `--verbose` - Show detailed layer information after build

**Examples**:
```bash
./scripts/build.sh                    # Standard build
./scripts/build.sh --clean            # Clean build
./scripts/build.sh --verbose          # Build with detailed output
./scripts/build.sh --clean --verbose  # Clean build with details
```

**Features**:
- Automatic Docker availability check
- Build validation and error handling
- Image size reporting
- Colorized output for better readability
- Layer information display (with --verbose)

---

### 🚀 `run.sh`
**Purpose**: Container management script for development and testing.

**Usage**:
```bash
./scripts/run.sh [COMMAND] [OPTIONS]
```

**Available Commands**:
- `start` - Start the application container
- `stop` - Stop the running container
- `restart` - Restart the container
- `logs [OPTIONS]` - View container logs (supports Docker log options)
- `status` - Show system status and connectivity tests
- `shell` - Open interactive shell in the container
- `test` - Run API and MQTT connectivity tests
- `clean` - Remove containers and images
- `compose [COMMAND]` - Docker Compose wrapper
- `help` - Show detailed help information

**Examples**:
```bash
./scripts/run.sh start               # Start container
./scripts/run.sh logs -f             # Follow logs in real-time
./scripts/run.sh status              # Check system status
./scripts/run.sh test                # Run connectivity tests
./scripts/run.sh compose up -d       # Start with docker-compose
./scripts/run.sh shell               # Open container shell
```

**Features**:
- Automatic port mapping (8080 for HTTP, 1883 for MQTT)
- Configuration file mounting from host
- Health checks and connectivity testing
- Docker Compose integration
- Colorized status output

---

### 🔐 `create-mqtt-user.sh`
**Purpose**: Create Mosquitto MQTT broker user credentials.

**Usage**:
```bash
./scripts/create-mqtt-user.sh
```

**What it does**:
- Creates a password file for Mosquitto authentication
- Sets up default credentials for the tabi-backend service
- Generates `mosquitto_passwd` file for Docker container

**Default Credentials**:
- Username: `tabi-backend`
- Password: `TabiMQTT2024!`

**Note**: Remember to rebuild containers after creating new credentials.

---

## Quick Start

1. **Build the application**:
   ```bash
   ./scripts/build.sh
   ```

2. **Start the services**:
   ```bash
   ./scripts/run.sh start
   ```

3. **Check status**:
   ```bash
   ./scripts/run.sh status
   ```

4. **View logs**:
   ```bash
   ./scripts/run.sh logs -f
   ```

## Development Workflow

### Standard Development
```bash
# Build and start
./scripts/build.sh && ./scripts/run.sh start

# Check logs during development
./scripts/run.sh logs -f

# Run tests
./scripts/run.sh test

# Restart after changes
./scripts/run.sh restart
```

### Clean Development Environment
```bash
# Clean build and start fresh
./scripts/build.sh --clean
./scripts/run.sh clean
./scripts/run.sh start
```

### Using Docker Compose
```bash
# Start all services in background
./scripts/run.sh compose up -d

# View logs
./scripts/run.sh compose logs -f

# Stop all services
./scripts/run.sh compose down
```

## Troubleshooting

### Common Issues

1. **"Docker not running"**
   - Ensure Docker Desktop is started
   - Check Docker daemon status

2. **"Image not found"**
   - Run `./scripts/build.sh` first
   - Check if build completed successfully

3. **Port conflicts**
   - Default ports: 8080 (HTTP), 1883 (MQTT)
   - Check for conflicting services: `netstat -tulpn | grep 8080`

4. **Container won't start**
   - Check logs: `./scripts/run.sh logs`
   - Verify configuration: `./scripts/run.sh status`

### Debug Commands
```bash
# System status
./scripts/run.sh status

# Container shell access
./scripts/run.sh shell

# Clean rebuild
./scripts/build.sh --clean
./scripts/run.sh clean
./scripts/run.sh start

# Test connectivity
./scripts/run.sh test
```

## Script Dependencies

### Required Tools
- Docker Engine
- Docker Compose
- Bash shell (Linux/macOS/WSL)

### Optional Tools
- `curl` - For API testing
- `mosquitto-clients` - For MQTT testing
- `jq` - For JSON parsing in logs

## Environment Configuration

The scripts respect the following configuration files:
- `config.json` - Application configuration (mounted into container)
- `docker-compose.yml` - Service orchestration
- `.env` - Environment variables (if present)

## Security Notes

1. **MQTT Credentials**: Default credentials are for development only
2. **Configuration**: `config.json` is mounted read-only into containers
3. **Networking**: Containers use host networking for development convenience
4. **Cleanup**: Use `./scripts/run.sh clean` to remove sensitive data from containers

## Contributing

When adding new scripts:
1. Make them executable: `chmod +x scripts/new-script.sh`
2. Add proper shebang: `#!/bin/bash`
3. Include error handling: `set -e`
4. Use colorized output for better UX
5. Document the script in this README
6. Follow the existing naming convention

---

*For more information about the Tabi Backend project, see the main [README.md](../README.md) file.*