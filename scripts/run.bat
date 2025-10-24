@echo off
setlocal enabledelayedexpansion

REM Run script for Tabi Backend - Windows Version
REM Container management and development utilities

REM Colors for Windows
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

REM Variables
set CONTAINER_NAME=tabi-backend
set IMAGE_NAME=tabi-backend:latest
set HTTP_PORT=8080
set MQTT_PORT=1883

echo %BLUE%🚀 Tabi Backend - Run Script%NC%
echo ===============================

REM Show help if no arguments
if "%1"=="" goto show_help

REM Command dispatcher
if "%1"=="start" goto start_container
if "%1"=="stop" goto stop_container
if "%1"=="restart" goto restart_container
if "%1"=="logs" goto show_logs
if "%1"=="status" goto show_status
if "%1"=="shell" goto open_shell
if "%1"=="test" goto test_api
if "%1"=="clean" goto clean_all
if "%1"=="compose" goto compose_cmd
if "%1"=="help" goto show_help

echo %RED%❌ Unknown command: %1%NC%
echo.
goto show_help

:show_help
echo %BLUE%Usage: %0 [COMMAND]%NC%
echo.
echo Available commands:
echo   start     - Start container
echo   stop      - Stop container
echo   restart   - Restart container
echo   logs      - View container logs
echo   logs -f   - Follow logs in real-time
echo   status    - Show system status
echo   shell     - Open shell in container
echo   test      - Test API and MQTT
echo   clean     - Clean containers and images
echo   compose   - Use docker-compose (up/down/logs)
echo   help      - Show this help
echo.
echo Examples:
echo   %0 start
echo   %0 logs -f
echo   %0 compose up -d
exit /b 0

:check_docker
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Error: Docker is not running%NC%
    exit /b 1
)
exit /b 0

:check_image
docker images %IMAGE_NAME% --format "{{.Repository}}:{{.Tag}}" | findstr "%IMAGE_NAME%" >nul
if %errorlevel% neq 0 (
    echo %YELLOW%⚠️  Image %IMAGE_NAME% not found%NC%
    echo %BLUE%💡 Run: .\scripts\build.bat first%NC%
    exit /b 1
)
exit /b 0

:start_container
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

call :check_image
if %errorlevel% neq 0 exit /b %errorlevel%

echo %BLUE%🚀 Starting container...%NC%

REM Stop existing container if running
docker ps -q -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    echo %YELLOW%⚠️  Stopping existing container...%NC%
    docker stop %CONTAINER_NAME% >nul
)

REM Remove existing container
docker ps -aq -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    docker rm %CONTAINER_NAME% >nul
)

REM Start new container
docker run -d --name %CONTAINER_NAME% -p %HTTP_PORT%:8080 -p %MQTT_PORT%:1883 -v "%CD%\config.json:/app/config.json:ro" --restart unless-stopped %IMAGE_NAME%

if %errorlevel% equ 0 (
    echo %GREEN%✅ Container started successfully%NC%
    echo %BLUE%📡 API available at: http://localhost:%HTTP_PORT%%NC%
    echo %BLUE%🔗 MQTT Broker at: localhost:%MQTT_PORT%%NC%
) else (
    echo %RED%❌ Failed to start container%NC%
    exit /b 1
)
exit /b 0

:stop_container
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

echo %BLUE%🛑 Stopping container...%NC%
docker ps -q -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    docker stop %CONTAINER_NAME%
    echo %GREEN%✅ Container stopped%NC%
) else (
    echo %YELLOW%⚠️  Container is not running%NC%
)
exit /b 0

:restart_container
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

call :check_image
if %errorlevel% neq 0 exit /b %errorlevel%

call :stop_container
timeout 2 >nul
call :start_container
exit /b 0

:show_logs
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

docker ps -q -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    echo %BLUE%📋 Container logs:%NC%
    docker logs %2 %3 %4 %5 %CONTAINER_NAME%
) else (
    echo %RED%❌ Container is not running%NC%
    exit /b 1
)
exit /b 0

:show_status
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

echo %BLUE%📊 System Status:%NC%
echo.

REM Container status
docker ps -q -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅ Container: RUNNING%NC%
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" -f name=%CONTAINER_NAME%
) else (
    echo %RED%❌ Container: STOPPED%NC%
)

echo.

REM Test connectivity if running
docker ps -q -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    echo %BLUE%🔍 Testing connectivity...%NC%

    REM Test HTTP API
    curl -s "http://localhost:%HTTP_PORT%/hello-world" >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%✅ API HTTP: OK%NC%
    ) else (
        echo %RED%❌ API HTTP: FAILED%NC%
    )

    REM Test MQTT (if mosquitto_pub is available)
    where mosquitto_pub >nul 2>&1
    if %errorlevel% equ 0 (
        timeout 5 mosquitto_pub -h localhost -p %MQTT_PORT% -t test -m "ping" >nul 2>&1
        if %errorlevel% equ 0 (
            echo %GREEN%✅ MQTT Broker: OK%NC%
        ) else (
            echo %RED%❌ MQTT Broker: FAILED%NC%
        )
    ) else (
        echo %YELLOW%⚠️  mosquitto_pub not available for MQTT test%NC%
    )
)
exit /b 0

:open_shell
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

docker ps -q -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    echo %BLUE%💻 Opening shell in container...%NC%
    docker exec -it %CONTAINER_NAME% /bin/sh
) else (
    echo %RED%❌ Container is not running%NC%
    exit /b 1
)
exit /b 0

:test_api
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

docker ps -q -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% neq 0 (
    echo %RED%❌ Container is not running%NC%
    exit /b 1
)

echo %BLUE%🧪 Testing API and MQTT...%NC%
echo.

echo %BLUE%📡 Testing API endpoints:%NC%

REM Hello world
echo|set /p="  - GET /hello-world: "
curl -s "http://localhost:%HTTP_PORT%/hello-world" | findstr "Hello world" >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅%NC%
) else (
    echo %RED%❌%NC%
)

REM Config
echo|set /p="  - GET /blinds/config: "
curl -s "http://localhost:%HTTP_PORT%/blinds/config" | findstr "mqtt" >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅%NC%
) else (
    echo %RED%❌%NC%
)

REM Status
echo|set /p="  - GET /blinds/status: "
curl -s "http://localhost:%HTTP_PORT%/blinds/status" | findstr "rooms" >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅%NC%
) else (
    echo %RED%❌%NC%
)

echo.
echo %BLUE%📨 Testing MQTT (from inside container):%NC%

REM Test MQTT internal
echo|set /p="  - MQTT publish test: "
docker exec %CONTAINER_NAME% mosquitto_pub -h localhost -t test -m "hello" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✅%NC%
) else (
    echo %RED%❌%NC%
)
exit /b 0

:clean_all
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

echo %YELLOW%🧹 Cleaning containers and images...%NC%

REM Stop and remove container
docker ps -aq -f name=%CONTAINER_NAME% | findstr "." >nul
if %errorlevel% equ 0 (
    docker stop %CONTAINER_NAME% 2>nul
    docker rm %CONTAINER_NAME% 2>nul
    echo %GREEN%✅ Container removed%NC%
)

REM Remove image
docker images %IMAGE_NAME% --format "{{.Repository}}:{{.Tag}}" | findstr "%IMAGE_NAME%" >nul
if %errorlevel% equ 0 (
    docker rmi %IMAGE_NAME% 2>nul
    echo %GREEN%✅ Image removed%NC%
)

REM Clean dangling images
docker image prune -f >nul 2>&1
echo %GREEN%✅ Cleanup completed%NC%
exit /b 0

:compose_cmd
call :check_docker
if %errorlevel% neq 0 exit /b %errorlevel%

shift
if "%1"=="" (
    echo %BLUE%📋 Docker-compose commands available:%NC%
    echo   up      - Start services
    echo   up -d   - Start in background
    echo   down    - Stop services
    echo   logs    - View logs
    echo   logs -f - View logs in real-time
    echo.
    echo Example: %0 compose up -d
    exit /b 0
)

echo %BLUE%🐳 Executing: docker-compose %*%NC%
docker-compose %*
exit /b %errorlevel%
