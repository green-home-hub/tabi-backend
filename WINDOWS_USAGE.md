# 🪟 Tabi Backend - Windows Usage Guide

Complete guide for running Tabi Backend on Windows with multiple options and troubleshooting.

## 🚀 Quick Start Options

### Option 1: Super Quick (Recommended)
```batch
# Double-click this file for instant development environment
dev.bat
```

### Option 2: Using Main CLI
```batch
# Command Prompt or PowerShell
tabi init                    # Complete setup
tabi dev                     # Development mode
```

### Option 3: PowerShell Script
```powershell
# PowerShell (more features)
.\tabi.ps1 init             # Complete setup
.\tabi.ps1 dev              # Development mode
```

### Option 4: Using Make (if available)
```batch
make dev                    # Quick development start
make help                   # Show all commands
```

## 🛠️ Prerequisites

### Required:
- **Docker Desktop** - [Download here](https://docs.docker.com/get-docker/)
- **Windows 10/11** or **Windows Server 2019+**

### Recommended:
- **Git for Windows** - Includes Git Bash for shell scripts
- **Windows Terminal** - Better terminal experience
- **Visual Studio Code** - For code editing

### Optional:
- **WSL2** - For native Linux experience
- **PowerShell 7** - Enhanced PowerShell features

## 📋 Available Commands

### 🎯 Main Commands

| Command | Batch File | PowerShell | Description |
|---------|------------|------------|-------------|
| `tabi help` | `tabi.bat help` | `.\tabi.ps1 help` | Show all commands |
| `tabi init` | `tabi.bat init` | `.\tabi.ps1 init` | First-time setup |
| `tabi dev` | `tabi.bat dev` | `.\tabi.ps1 dev` | Development mode |
| `tabi build` | `tabi.bat build` | `.\tabi.ps1 build` | Build Docker image |
| `tabi start` | `tabi.bat start` | `.\tabi.ps1 start` | Start application |
| `tabi stop` | `tabi.bat stop` | `.\tabi.ps1 stop` | Stop application |
| `tabi status` | `tabi.bat status` | `.\tabi.ps1 status` | System status |
| `tabi logs -f` | `tabi.bat logs -f` | `.\tabi.ps1 logs -f` | Follow logs |

### 🔧 Development Commands

```batch
# Build and development
tabi build --clean          # Clean build
tabi restart                 # Restart services
tabi shell                   # Open container shell
tabi test                    # Run connectivity tests

# Docker Compose
tabi up                      # Start all services
tabi down                    # Stop all services
tabi ps                      # Show running services

# Maintenance
tabi clean                   # Clean containers/images
tabi setup-mqtt              # Setup MQTT credentials
```

## 🎮 Usage Examples

### First Time Setup
```batch
# 1. Open Command Prompt or PowerShell as Administrator
# 2. Navigate to project directory
cd C:\git\tabi-backend

# 3. Run initialization (does everything automatically)
tabi init

# 4. Check if everything is working
tabi status
tabi test
```

### Daily Development Workflow
```batch
# Start development environment
tabi dev

# Follow logs in real-time (new terminal window)
tabi logs -f

# Make changes to code, then restart
tabi restart

# Test your changes
tabi test

# Stop when done
tabi stop
```

### Using Docker Compose
```batch
# Start all services in background
tabi up

# View logs
tabi logs -f

# Stop all services
tabi down
```

## 🐳 Docker Integration

### Container Ports
- **HTTP API**: `http://localhost:8080`
- **MQTT Broker**: `localhost:1883`

### Volumes
- `config.json` is automatically mounted into the container
- Logs are accessible via `tabi logs`

### Health Checks
```batch
# Check if API is responding
curl http://localhost:8080/hello-world

# Check system status
curl http://localhost:8080/status

# View configuration
curl http://localhost:8080/blinds/config
```

## 🔧 Troubleshooting

### Docker Issues

**"Docker is not running"**
```batch
# Solution 1: Start Docker Desktop
# - Open Docker Desktop from Start Menu
# - Wait for Docker to fully start

# Solution 2: Restart Docker service
net stop com.docker.service
net start com.docker.service
```

**"Image not found"**
```batch
# Build the image first
tabi build

# Or clean build if previous build failed
tabi build --clean
```

**Port conflicts (8080 or 1883 already in use)**
```batch
# Check what's using the ports
netstat -an | findstr :8080
netstat -an | findstr :1883

# Stop conflicting services or change ports in config.json
```

### Script Execution Issues

**"Execution Policy" errors in PowerShell**
```powershell
# Temporarily allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single execution
PowerShell -ExecutionPolicy Bypass -File .\tabi.ps1 help
```

**"Bash not found" errors**
```batch
# Install Git for Windows (includes Git Bash)
# Download from: https://git-scm.com/download/win

# Or use WSL
wsl --install

# Or use PowerShell version instead
.\tabi.ps1 help
```

### Configuration Issues

**MQTT connection failures**
```batch
# Check MQTT credentials
tabi setup-mqtt

# Restart after changing MQTT settings
tabi restart

# Test MQTT from inside container
tabi shell
mosquitto_pub -h localhost -t test -m "hello"
```

**API not responding**
```batch
# Check container status
tabi status

# View detailed logs
tabi logs

# Restart container
tabi restart
```

## 🚦 Environment-Specific Instructions

### Windows 10 Home
- Docker Desktop requires WSL2
- Enable WSL2 and install a Linux distribution
- Use `wsl --set-default-version 2`

### Windows 11
- Native Docker Desktop support
- All features work out of the box

### Windows Server
- Use Docker EE or Docker Desktop
- May require additional Windows features

### Corporate Networks
- Configure Docker Desktop proxy settings
- May need to disable antivirus real-time scanning for project folder
- Check firewall settings for ports 8080 and 1883

## 🎯 Performance Tips

### Docker Optimization
```batch
# Increase Docker memory allocation (Docker Desktop Settings)
# Recommended: 4GB+ for development

# Use SSD storage for better I/O performance
# Move Docker data to SSD if needed
```

### Windows-Specific
```batch
# Disable Windows Defender real-time scanning for project folder
# Add exclusion: C:\git\tabi-backend

# Use Windows Terminal for better console experience
# Install from Microsoft Store
```

## 📁 File Structure for Windows

```
C:\git\tabi-backend\
├── tabi.bat                 # Main CLI (Batch)
├── tabi.ps1                 # Main CLI (PowerShell)  
├── dev.bat                  # Quick development shortcut
├── Makefile                 # Make commands (if make available)
├── scripts/
│   ├── build.bat           # Windows build script
│   ├── run.bat             # Windows run script
│   ├── build.sh            # Linux build script (for Git Bash)
│   ├── run.sh              # Linux run script (for Git Bash)
│   └── create-mqtt-user.sh # MQTT setup
├── config.json             # Application configuration
├── docker-compose.yml      # Docker Compose configuration
└── README.md               # Main documentation
```

## 🆘 Getting Help

### Built-in Help
```batch
tabi help                   # Show all commands
tabi version                # Version and system info
tabi docs                   # Documentation links
```

### System Information
```batch
# Check system capabilities
tabi version

# Test all connectivity
tabi test

# View system status
tabi status
```

### Common Commands Cheatsheet
```batch
# Setup
tabi init                   # First-time setup
dev.bat                     # Quick development start

# Daily use  
tabi dev                    # Start development
tabi logs -f                # Watch logs
tabi restart                # Restart after changes
tabi stop                   # Stop services

# Troubleshooting
tabi status                 # Check system
tabi test                   # Test connectivity
tabi clean                  # Clean everything
tabi build --clean          # Rebuild from scratch
```

## 🔗 Useful Links

- [Docker Desktop for Windows](https://docs.docker.com/desktop/windows/)
- [Git for Windows](https://git-scm.com/download/win)
- [Windows Terminal](https://aka.ms/terminal)
- [WSL2 Installation](https://docs.microsoft.com/en-us/windows/wsl/install)
- [PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)

---

*For Linux/macOS instructions, see the main [README.md](README.md)*