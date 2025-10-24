@echo off
setlocal enabledelayedexpansion

REM Build script for Tabi Backend - Windows Version
REM Optimized Docker image build with advanced features

REM Colors for Windows
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

REM Variables
set IMAGE_NAME=tabi-backend
set TAG=latest
set DOCKERFILE=Dockerfile

echo %BLUE%🔨 Tabi Backend - Build Script%NC%
echo ==================================

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Error: Docker is not running%NC%
    exit /b 1
)

REM Check required files
if not exist "%DOCKERFILE%" (
    echo %RED%❌ Error: %DOCKERFILE% not found%NC%
    exit /b 1
)

if not exist "config.json" (
    echo %YELLOW%⚠️  Warning: config.json not found, using default configuration%NC%
)

echo %BLUE%📋 Build Information:%NC%
echo   - Image: %IMAGE_NAME%:%TAG%
echo   - Dockerfile: %DOCKERFILE%
echo   - Context: %CD%

REM Clean builds if requested
if "%1"=="--clean" (
    echo %YELLOW%🧹 Cleaning previous images...%NC%
    docker rmi %IMAGE_NAME%:%TAG% 2>nul
    docker builder prune -f
)

REM Build the image
echo %BLUE%🔨 Building Docker image...%NC%
docker build --tag %IMAGE_NAME%:%TAG% --file %DOCKERFILE% --progress=plain .

REM Check if build was successful
if %errorlevel% equ 0 (
    echo.
    echo %GREEN%✅ Build completed successfully%NC%

    REM Show image information
    for /f "tokens=*" %%i in ('docker images %IMAGE_NAME%:%TAG% --format "{{.Size}}" 2^>nul') do set IMAGE_SIZE=%%i
    echo %GREEN%📦 Image size: !IMAGE_SIZE!%NC%

    REM Show layers if verbose
    if "%1"=="--verbose" (
        echo %BLUE%📋 Image layers:%NC%
        docker history %IMAGE_NAME%:%TAG% --no-trunc
    )
    if "%2"=="--verbose" (
        echo %BLUE%📋 Image layers:%NC%
        docker history %IMAGE_NAME%:%TAG% --no-trunc
    )

    echo.
    echo %BLUE%🚀 Useful commands:%NC%
    echo   # Run container:
    echo     docker run -p 8080:8080 -p 1883:1883 %IMAGE_NAME%:%TAG%
    echo.
    echo   # With docker-compose:
    echo     docker-compose up
    echo.
    echo   # View logs:
    echo     docker logs tabi-backend
    echo.
    echo   # Testing MQTT:
    echo     docker exec tabi-backend mosquitto_pub -t test -m "hello"
) else (
    echo %RED%❌ Error in build%NC%
    exit /b 1
)
