@echo off
setlocal enabledelayedexpansion

REM Tabi Backend - Windows CLI Wrapper
REM Provides Windows-compatible interface for all project operations

set PROJECT_NAME=Tabi Backend
set PROJECT_VERSION=1.0.0
set SCRIPTS_DIR=%~dp0scripts

REM Colors for Windows (limited support)
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set CYAN=[96m
set NC=[0m

REM Check if Docker is available
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Docker is not installed or not in PATH%NC%
    echo Please install Docker Desktop from: https://docs.docker.com/get-docker/
    exit /b 1
)

REM Main command dispatcher
if "%1"=="" goto show_help
if "%1"=="help" goto show_help
if "%1"=="--help" goto show_help
if "%1"=="-h" goto show_help
if "%1"=="version" goto show_version
if "%1"=="--version" goto show_version
if "%1"=="-v" goto show_version
if "%1"=="docs" goto show_docs

REM Check if scripts directory exists (except for help/version)
if not exist "%SCRIPTS_DIR%" (
    echo %RED%❌ Scripts directory not found: %SCRIPTS_DIR%%NC%
    echo Make sure you're running this from the project root
    exit /b 1
)

REM Command routing
if "%1"=="build" goto build_cmd
if "%1"=="start" goto start_cmd
if "%1"=="stop" goto stop_cmd
if "%1"=="restart" goto restart_cmd
if "%1"=="status" goto status_cmd
if "%1"=="dev" goto dev_cmd
if "%1"=="init" goto init_cmd
if "%1"=="logs" goto logs_cmd
if "%1"=="shell" goto shell_cmd
if "%1"=="test" goto test_cmd
if "%1"=="up" goto up_cmd
if "%1"=="down" goto down_cmd
if "%1"=="ps" goto ps_cmd
if "%1"=="clean" goto clean_cmd
if "%1"=="setup-mqtt" goto setup_mqtt_cmd

REM Fallback - pass through to run.sh via Git Bash
bash "%SCRIPTS_DIR%\run.sh" %*
exit /b %errorlevel%

:show_help
echo.
echo %BLUE%╔══════════════════════════════════════════════════════════════╗%NC%
echo %BLUE%║                    %CYAN%🏠 Tabi Backend CLI%BLUE%                     ║%NC%
echo %BLUE%║                %YELLOW%Smart Blinds Control System%BLUE%               ║%NC%
echo %BLUE%║                      %GREEN%Version %PROJECT_VERSION%%BLUE%                      ║%NC%
echo %BLUE%╚══════════════════════════════════════════════════════════════╝%NC%
echo.
echo %CYAN%🚀 Available Commands:%NC%
echo.
echo %YELLOW%📦 Build ^& Development:%NC%
echo   %GREEN%build%NC%           Build Docker image
echo   %GREEN%build --clean%NC%   Clean build (remove cache)
echo   %GREEN%dev%NC%             Start development environment
echo   %GREEN%clean%NC%           Clean all containers and images
echo.
echo %YELLOW%🎮 Container Management:%NC%
echo   %GREEN%start%NC%           Start the application
echo   %GREEN%stop%NC%            Stop the application
echo   %GREEN%restart%NC%         Restart the application
echo   %GREEN%status%NC%          Show system status
echo.
echo %YELLOW%📋 Monitoring ^& Debugging:%NC%
echo   %GREEN%logs%NC%            Show application logs
echo   %GREEN%logs -f%NC%         Follow logs in real-time
echo   %GREEN%shell%NC%           Open shell in container
echo   %GREEN%test%NC%            Run connectivity tests
echo.
echo %YELLOW%🐳 Docker Compose:%NC%
echo   %GREEN%up%NC%              Start all services (docker-compose up -d)
echo   %GREEN%down%NC%            Stop all services (docker-compose down)
echo   %GREEN%ps%NC%              Show running services
echo.
echo %YELLOW%🔐 Security ^& Setup:%NC%
echo   %GREEN%setup-mqtt%NC%      Create MQTT user credentials
echo   %GREEN%init%NC%            Initialize project (first-time setup)
echo.
echo %YELLOW%ℹ️  Information:%NC%
echo   %GREEN%help%NC%            Show this help message
echo   %GREEN%version%NC%         Show version information
echo   %GREEN%docs%NC%            Show documentation links
echo.
echo %CYAN%💡 Examples:%NC%
echo   %BLUE%tabi build ^&^& tabi start%NC%     # Build and start
echo   %BLUE%tabi dev%NC%                       # Quick development start
echo   %BLUE%tabi logs -f%NC%                   # Watch logs
echo   %BLUE%tabi test%NC%                      # Test system
echo.
exit /b 0

:show_version
echo.
echo %BLUE%╔══════════════════════════════════════════════════════════════╗%NC%
echo %BLUE%║                    %CYAN%🏠 Tabi Backend CLI%BLUE%                     ║%NC%
echo %BLUE%║                %YELLOW%Smart Blinds Control System%BLUE%               ║%NC%
echo %BLUE%║                      %GREEN%Version %PROJECT_VERSION%%BLUE%                      ║%NC%
echo %BLUE%╚══════════════════════════════════════════════════════════════╝%NC%
echo.
echo %CYAN%📊 System Information:%NC%
echo   Project: %PROJECT_NAME%
echo   Version: %PROJECT_VERSION%
echo   Scripts Directory: %SCRIPTS_DIR%
echo   Platform: Windows
echo.
echo %CYAN%🔧 Dependencies:%NC%

docker --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%i in ('docker --version 2^>nul') do echo   ✅ Docker: %%i
) else (
    echo   ❌ Docker: Not installed
)

docker-compose --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%i in ('docker-compose --version 2^>nul') do echo   ✅ Docker Compose: %%i
) else (
    echo   ❌ Docker Compose: Not installed
)

curl --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ curl: Available
) else (
    echo   ⚠️  curl: Not available (optional)
)

git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ Git (with Bash): Available
) else (
    echo   ⚠️  Git Bash: Not available (recommended for scripts)
)

echo.
exit /b 0

:show_docs
echo %CYAN%📚 Documentation ^& Resources:%NC%
echo.
echo %YELLOW%📖 Project Documentation:%NC%
echo   Main README:        .\README.md
echo   Scripts README:     .\scripts\README.md
echo   MQTT Setup Guide:   .\SIMPLE_MQTT_SETUP.md
echo.
echo %YELLOW%🌐 API Endpoints (when running):%NC%
echo   Health Check:       http://localhost:8080/hello-world
echo   System Status:      http://localhost:8080/blinds/status
echo   Configuration:      http://localhost:8080/blinds/config
echo   Rooms List:         http://localhost:8080/blinds/rooms
echo.
echo %YELLOW%🔗 Control Endpoints:%NC%
echo   Control by ID:      POST /blinds/id/{id}/{action}
echo   Control by Room:    POST /blinds/room/{room}/{action}
echo   Control All:        POST /blinds/all/{action}
echo   Actions: OPEN, CLOSE, STOP
echo.
echo %YELLOW%🐳 Docker ^& MQTT:%NC%
echo   HTTP Port:          8080
echo   MQTT Port:          1883
echo   Config File:        .\config.json
echo.
exit /b 0

:build_cmd
echo %BLUE%🔨 Building Docker image...%NC%
bash "%SCRIPTS_DIR%\build.sh" %2 %3 %4 %5
exit /b %errorlevel%

:start_cmd
echo %GREEN%▶️  Starting application...%NC%
bash "%SCRIPTS_DIR%\run.sh" start
exit /b %errorlevel%

:stop_cmd
echo %RED%⏹️  Stopping application...%NC%
bash "%SCRIPTS_DIR%\run.sh" stop
exit /b %errorlevel%

:restart_cmd
echo %YELLOW%🔄 Restarting application...%NC%
bash "%SCRIPTS_DIR%\run.sh" restart
exit /b %errorlevel%

:status_cmd
echo %CYAN%📊 System Status:%NC%
bash "%SCRIPTS_DIR%\run.sh" status
exit /b %errorlevel%

:dev_cmd
echo %BLUE%🛠️  Starting development environment...%NC%
REM Check if image exists, build if not
docker images tabi-backend:latest --format "{{.Repository}}:{{.Tag}}" | findstr "tabi-backend:latest" >nul
if %errorlevel% neq 0 (
    echo %YELLOW%📦 Building application first...%NC%
    bash "%SCRIPTS_DIR%\build.sh"
    if %errorlevel% neq 0 exit /b %errorlevel%
)
echo %CYAN%🚀 Starting services...%NC%
bash "%SCRIPTS_DIR%\run.sh" start
timeout 3 >nul
bash "%SCRIPTS_DIR%\run.sh" status
echo.
echo %GREEN%✅ Development environment ready!%NC%
echo %CYAN%💡 Useful commands:%NC%
echo   tabi logs -f   # Follow logs
echo   tabi test      # Test API
echo   tabi shell     # Container shell
exit /b 0

:init_cmd
echo %BLUE%🚀 Initializing Tabi Backend project...%NC%
echo.
echo %CYAN%1. Checking dependencies...%NC%
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Docker is required but not installed%NC%
    echo %YELLOW%💡 Install Docker from: https://docs.docker.com/get-docker/%NC%
    exit /b 1
)
echo %GREEN%✅ Docker is available%NC%

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Docker is not running%NC%
    echo %YELLOW%💡 Please start Docker Desktop%NC%
    exit /b 1
)
echo %GREEN%✅ Docker is running%NC%

echo %CYAN%2. Setting up MQTT credentials...%NC%
if exist "%SCRIPTS_DIR%\create-mqtt-user.sh" (
    bash "%SCRIPTS_DIR%\create-mqtt-user.sh"
) else (
    echo %YELLOW%⚠️  MQTT setup script not found%NC%
)

echo %CYAN%3. Building application...%NC%
bash "%SCRIPTS_DIR%\build.sh"
if %errorlevel% neq 0 exit /b %errorlevel%

echo %CYAN%4. Starting application...%NC%
bash "%SCRIPTS_DIR%\run.sh" start

echo.
echo %GREEN%✅ Initialization complete!%NC%
echo %CYAN%🎉 Tabi Backend is now running%NC%
echo.
echo %YELLOW%📋 Quick commands:%NC%
echo   tabi status    # Check system status
echo   tabi test      # Run connectivity tests
echo   tabi logs -f   # View logs
echo.
exit /b 0

:logs_cmd
echo %CYAN%📋 Application Logs:%NC%
bash "%SCRIPTS_DIR%\run.sh" logs %2 %3 %4 %5
exit /b %errorlevel%

:shell_cmd
echo %CYAN%💻 Opening container shell...%NC%
bash "%SCRIPTS_DIR%\run.sh" shell
exit /b %errorlevel%

:test_cmd
echo %BLUE%🧪 Running tests...%NC%
bash "%SCRIPTS_DIR%\run.sh" test
exit /b %errorlevel%

:up_cmd
echo %BLUE%🐳 Starting with Docker Compose...%NC%
bash "%SCRIPTS_DIR%\run.sh" compose up -d
exit /b %errorlevel%

:down_cmd
echo %RED%🐳 Stopping Docker Compose services...%NC%
bash "%SCRIPTS_DIR%\run.sh" compose down
exit /b %errorlevel%

:ps_cmd
echo %CYAN%🐳 Running services:%NC%
docker-compose ps
exit /b %errorlevel%

:clean_cmd
echo %RED%🧹 Cleaning containers and images...%NC%
bash "%SCRIPTS_DIR%\run.sh" clean
exit /b %errorlevel%

:setup_mqtt_cmd
echo %BLUE%🔐 Setting up MQTT authentication...%NC%
bash "%SCRIPTS_DIR%\create-mqtt-user.sh"
exit /b %errorlevel%
