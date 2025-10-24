# Tabi Backend - PowerShell CLI Wrapper
# Provides Windows PowerShell interface for all project operations

param(
    [Parameter(Position=0)]
    [string]$Command = "help",

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments = @()
)

# Project configuration
$ProjectName = "Tabi Backend"
$ProjectVersion = "1.0.0"
$ScriptsDir = Join-Path $PSScriptRoot "scripts"

# Color functions for better output
function Write-ColorText {
    param(
        [string]$Text,
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )
    $originalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $originalColor
}

function Write-Success {
    param([string]$Message)
    Write-ColorText "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-ColorText "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-ColorText "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-ColorText "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Header {
    param([string]$Message)
    Write-ColorText $Message -ForegroundColor Blue
}

# Banner function
function Show-Banner {
    Write-Host ""
    Write-ColorText "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-ColorText "║                    🏠 Tabi Backend CLI                     ║" -ForegroundColor Blue
    Write-ColorText "║                Smart Blinds Control System               ║" -ForegroundColor Blue
    Write-ColorText "║                      Version $ProjectVersion                      ║" -ForegroundColor Blue
    Write-ColorText "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

# Check dependencies
function Test-Dependencies {
    $dockerAvailable = $false
    $composeAvailable = $false

    try {
        $null = docker --version 2>$null
        $dockerAvailable = $true
    } catch {
        $dockerAvailable = $false
    }

    try {
        $null = docker-compose --version 2>$null
        $composeAvailable = $true
    } catch {
        $composeAvailable = $false
    }

    return @{
        Docker = $dockerAvailable
        Compose = $composeAvailable
    }
}

# Check if Docker is running
function Test-DockerRunning {
    try {
        $null = docker info 2>$null
        return $true
    } catch {
        return $false
    }
}

# Show help
function Show-Help {
    Show-Banner
    Write-ColorText "🚀 Available Commands:" -ForegroundColor Cyan
    Write-Host ""

    Write-ColorText "📦 Build & Development:" -ForegroundColor Yellow
    Write-Host "  build           Build Docker image"
    Write-Host "  build --clean   Clean build (remove cache)"
    Write-Host "  dev             Start development environment"
    Write-Host "  clean           Clean all containers and images"
    Write-Host ""

    Write-ColorText "🎮 Container Management:" -ForegroundColor Yellow
    Write-Host "  start           Start the application"
    Write-Host "  stop            Stop the application"
    Write-Host "  restart         Restart the application"
    Write-Host "  status          Show system status"
    Write-Host ""

    Write-ColorText "📋 Monitoring & Debugging:" -ForegroundColor Yellow
    Write-Host "  logs            Show application logs"
    Write-Host "  logs -f         Follow logs in real-time"
    Write-Host "  shell           Open shell in container"
    Write-Host "  test            Run connectivity tests"
    Write-Host ""

    Write-ColorText "🐳 Docker Compose:" -ForegroundColor Yellow
    Write-Host "  up              Start all services (docker-compose up -d)"
    Write-Host "  down            Stop all services (docker-compose down)"
    Write-Host "  ps              Show running services"
    Write-Host ""

    Write-ColorText "🔐 Security & Setup:" -ForegroundColor Yellow
    Write-Host "  setup-mqtt      Create MQTT user credentials"
    Write-Host "  init            Initialize project (first-time setup)"
    Write-Host ""

    Write-ColorText "ℹ️  Information:" -ForegroundColor Yellow
    Write-Host "  help            Show this help message"
    Write-Host "  version         Show version information"
    Write-Host "  docs            Show documentation links"
    Write-Host ""

    Write-ColorText "💡 Examples:" -ForegroundColor Cyan
    Write-Host "  .\tabi.ps1 build; .\tabi.ps1 start     # Build and start"
    Write-Host "  .\tabi.ps1 dev                          # Quick development start"
    Write-Host "  .\tabi.ps1 logs -f                      # Watch logs"
    Write-Host "  .\tabi.ps1 test                         # Test system"
    Write-Host ""
}

# Show version information
function Show-Version {
    Show-Banner
    Write-ColorText "📊 System Information:" -ForegroundColor Cyan
    Write-Host "  Project: $ProjectName"
    Write-Host "  Version: $ProjectVersion"
    Write-Host "  Scripts Directory: $ScriptsDir"
    Write-Host "  Platform: Windows PowerShell"
    Write-Host ""

    Write-ColorText "🔧 Dependencies:" -ForegroundColor Cyan
    $deps = Test-Dependencies

    if ($deps.Docker) {
        $dockerVersion = (docker --version 2>$null) -replace '.*version ([^,]+).*','$1'
        Write-Success "Docker: $dockerVersion"
    } else {
        Write-Error "Docker: Not installed"
    }

    if ($deps.Compose) {
        $composeVersion = (docker-compose --version 2>$null) -replace '.*version ([^,\s]+).*','$1'
        Write-Success "Docker Compose: $composeVersion"
    } else {
        Write-Error "Docker Compose: Not installed"
    }

    if (Get-Command curl -ErrorAction SilentlyContinue) {
        Write-Success "curl: Available"
    } else {
        Write-Warning "curl: Not available (optional)"
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Success "Git: Available"
    } else {
        Write-Warning "Git: Not available (recommended)"
    }

    Write-Host ""
}

# Show documentation
function Show-Docs {
    Write-ColorText "📚 Documentation & Resources:" -ForegroundColor Cyan
    Write-Host ""
    Write-ColorText "📖 Project Documentation:" -ForegroundColor Yellow
    Write-Host "  Main README:        .\README.md"
    Write-Host "  Scripts README:     .\scripts\README.md"
    Write-Host "  MQTT Setup Guide:   .\SIMPLE_MQTT_SETUP.md"
    Write-Host ""
    Write-ColorText "🌐 API Endpoints (when running):" -ForegroundColor Yellow
    Write-Host "  Health Check:       http://localhost:8080/hello-world"
    Write-Host "  System Status:      http://localhost:8080/blinds/status"
    Write-Host "  Configuration:      http://localhost:8080/blinds/config"
    Write-Host "  Rooms List:         http://localhost:8080/blinds/rooms"
    Write-Host ""
    Write-ColorText "🔗 Control Endpoints:" -ForegroundColor Yellow
    Write-Host "  Control by ID:      POST /blinds/id/{id}/{action}"
    Write-Host "  Control by Room:    POST /blinds/room/{room}/{action}"
    Write-Host "  Control All:        POST /blinds/all/{action}"
    Write-Host "  Actions: OPEN, CLOSE, STOP"
    Write-Host ""
    Write-ColorText "🐳 Docker & MQTT:" -ForegroundColor Yellow
    Write-Host "  HTTP Port:          8080"
    Write-Host "  MQTT Port:          1883"
    Write-Host "  Config File:        .\config.json"
    Write-Host ""
}

# Execute shell script with error handling
function Invoke-ShellScript {
    param(
        [string]$ScriptPath,
        [string[]]$ScriptArguments = @()
    )

    if (!(Test-Path $ScriptPath)) {
        Write-Error "Script not found: $ScriptPath"
        return $false
    }

    try {
        if (Get-Command bash -ErrorAction SilentlyContinue) {
            # Use bash if available (Git Bash)
            $argString = ($ScriptArguments -join ' ')
            $process = Start-Process -FilePath "bash" -ArgumentList @($ScriptPath, $argString) -Wait -NoNewWindow -PassThru
        } elseif (Get-Command wsl -ErrorAction SilentlyContinue) {
            # Use WSL if available
            $argString = ($ScriptArguments -join ' ')
            $process = Start-Process -FilePath "wsl" -ArgumentList @("bash", $ScriptPath, $argString) -Wait -NoNewWindow -PassThru
        } else {
            Write-Error "Bash not available. Please install Git for Windows or WSL."
            return $false
        }

        return $process.ExitCode -eq 0
    } catch {
        Write-Error "Failed to execute script: $($_.Exception.Message)"
        return $false
    }
}

# Development environment setup
function Start-DevEnvironment {
    Write-Header "🛠️  Starting development environment..."

    # Check if Docker is running
    if (!(Test-DockerRunning)) {
        Write-Error "Docker is not running. Please start Docker Desktop."
        return
    }

    # Build if needed
    $imageExists = docker images tabi-backend:latest --format "{{.Repository}}:{{.Tag}}" | Select-String "tabi-backend:latest"
    if (!$imageExists) {
        Write-Warning "📦 Building application first..."
        $buildScript = Join-Path $ScriptsDir "build.sh"
        if (!(Invoke-ShellScript $buildScript)) {
            Write-Error "Build failed!"
            return
        }
    }

    # Start services
    Write-Info "🚀 Starting services..."
    $runScript = Join-Path $ScriptsDir "run.sh"
    if (Invoke-ShellScript $runScript @("start")) {
        Start-Sleep 3
        Invoke-ShellScript $runScript @("status")

        Write-Host ""
        Write-Success "✅ Development environment ready!"
        Write-ColorText "💡 Useful commands:" -ForegroundColor Cyan
        Write-Host "  .\tabi.ps1 logs -f   # Follow logs"
        Write-Host "  .\tabi.ps1 test      # Test API"
        Write-Host "  .\tabi.ps1 shell     # Container shell"
    }
}

# Initialize project
function Initialize-Project {
    Write-Header "🚀 Initializing Tabi Backend project..."
    Write-Host ""

    # Check dependencies
    Write-Info "1. Checking dependencies..."
    $deps = Test-Dependencies

    if (!$deps.Docker) {
        Write-Error "Docker is required but not installed"
        Write-Warning "💡 Install Docker from: https://docs.docker.com/get-docker/"
        return
    }
    Write-Success "Docker is available"

    if (!(Test-DockerRunning)) {
        Write-Error "Docker is not running"
        Write-Warning "💡 Please start Docker Desktop"
        return
    }
    Write-Success "Docker is running"

    # Setup MQTT credentials
    Write-Info "2. Setting up MQTT credentials..."
    $mqttScript = Join-Path $ScriptsDir "create-mqtt-user.sh"
    if (Test-Path $mqttScript) {
        Invoke-ShellScript $mqttScript
    } else {
        Write-Warning "MQTT setup script not found"
    }

    # Build application
    Write-Info "3. Building application..."
    $buildScript = Join-Path $ScriptsDir "build.sh"
    if (!(Invoke-ShellScript $buildScript)) {
        Write-Error "Build failed!"
        return
    }

    # Start application
    Write-Info "4. Starting application..."
    $runScript = Join-Path $ScriptsDir "run.sh"
    if (Invoke-ShellScript $runScript @("start")) {
        Write-Host ""
        Write-Success "✅ Initialization complete!"
        Write-ColorText "🎉 Tabi Backend is now running" -ForegroundColor Cyan
        Write-Host ""
        Write-ColorText "📋 Quick commands:" -ForegroundColor Yellow
        Write-Host "  .\tabi.ps1 status    # Check system status"
        Write-Host "  .\tabi.ps1 test      # Run connectivity tests"
        Write-Host "  .\tabi.ps1 logs -f   # View logs"
        Write-Host ""
    }
}

# Main command dispatcher
function Invoke-TabiCommand {
    param([string]$Cmd, [string[]]$Args)

    # Check scripts directory exists (except for help/version/docs)
    if ($Cmd -notin @("help", "version", "docs", "--help", "-h", "--version", "-v")) {
        if (!(Test-Path $ScriptsDir)) {
            Write-Error "Scripts directory not found: $ScriptsDir"
            Write-Warning "Make sure you're running this from the project root"
            return
        }
    }

    switch ($Cmd) {
        { $_ -in @("help", "--help", "-h") } {
            Show-Help
        }
        { $_ -in @("version", "--version", "-v") } {
            Show-Version
        }
        "docs" {
            Show-Docs
        }
        "dev" {
            Start-DevEnvironment
        }
        "init" {
            Initialize-Project
        }
        { $_ -in @("build", "start", "stop", "restart", "status", "logs", "shell", "test", "clean", "up", "down", "ps") } {
            $runScript = Join-Path $ScriptsDir "run.sh"
            if ($Cmd -eq "build") {
                $buildScript = Join-Path $ScriptsDir "build.sh"
                Invoke-ShellScript $buildScript $Args
            } elseif ($Cmd -in @("up", "down", "ps")) {
                # Docker Compose shortcuts
                switch ($Cmd) {
                    "up" {
                        Write-Header "🐳 Starting all services with Docker Compose..."
                        Invoke-ShellScript $runScript @("compose", "up", "-d")
                    }
                    "down" {
                        Write-Header "🐳 Stopping all services..."
                        Invoke-ShellScript $runScript @("compose", "down")
                    }
                    "ps" {
                        Write-Header "🐳 Showing running services..."
                        docker-compose ps
                    }
                }
            } else {
                Invoke-ShellScript $runScript ($Cmd, $Args)
            }
        }
        "setup-mqtt" {
            $mqttScript = Join-Path $ScriptsDir "create-mqtt-user.sh"
            Write-Header "🔐 Setting up MQTT authentication..."
            Invoke-ShellScript $mqttScript
        }
        default {
            # Fallback - pass through to run.sh
            $runScript = Join-Path $ScriptsDir "run.sh"
            Invoke-ShellScript $runScript ($Cmd, $Args)
        }
    }
}

# Main execution
try {
    # Check for Docker availability
    $deps = Test-Dependencies
    if (!$deps.Docker -and $Command -notin @("help", "version", "docs", "--help", "-h", "--version", "-v")) {
        Write-Error "Docker is not installed or not in PATH"
        Write-Warning "Please install Docker Desktop from: https://docs.docker.com/get-docker/"
        exit 1
    }

    # Execute command
    Invoke-TabiCommand $Command $Arguments

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
