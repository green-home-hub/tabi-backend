@echo off
setlocal enabledelayedexpansion

REM Tabi Backend - Development Shortcut
REM Quick development environment setup for Windows

REM Colors for Windows
set GREEN=[92m
set BLUE=[94m
set YELLOW=[93m
set RED=[91m
set NC=[0m

echo %BLUE%🛠️  Tabi Backend - Development Mode%NC%
echo ===================================

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Docker is not running. Please start Docker Desktop.%NC%
    pause
    exit /b 1
)

REM Check if image exists, build if not
echo %BLUE%📦 Checking Docker image...%NC%
docker images tabi-backend:latest --format "{{.Repository}}:{{.Tag}}" | findstr "tabi-backend:latest" >nul
if %errorlevel% neq 0 (
    echo %YELLOW%🔨 Image not found. Building...%NC%
    call scripts\build.bat
    if %errorlevel% neq 0 (
        echo %RED%❌ Build failed!%NC%
        pause
        exit /b 1
    )
)

REM Start the development environment
echo %BLUE%🚀 Starting development environment...%NC%
call scripts\run.bat start

REM Wait a moment for startup
timeout 3 >nul

REM Show status
call scripts\run.bat status

echo.
echo %GREEN%✅ Development environment ready!%NC%
echo.
echo %YELLOW%📋 Quick Commands:%NC%
echo   tabi logs -f     - Follow logs
echo   tabi test        - Run tests
echo   tabi shell       - Container shell
echo   tabi stop        - Stop services
echo.
echo %BLUE%🌐 API Available at: http://localhost:8080%NC%
echo %BLUE%📡 MQTT Broker at: localhost:1883%NC%
echo.

pause
