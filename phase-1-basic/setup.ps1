# Phase 1 Setup Script - Windows PowerShell
# Deploys RabbitMQ (MCP Server) and Agent worker to Docker Desktop Kubernetes.
#
# Prerequisites:
#   - Docker Desktop running with Kubernetes enabled
#     (Settings > Kubernetes > Enable Kubernetes)
#
# Usage:
#   .\setup.ps1

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "=== Phase 1: Basic - MCP Server + Single Agent ===" -ForegroundColor Cyan
Write-Host ""

# --- Pre-flight checks ---
Write-Host "[1/5] Checking prerequisites..." -ForegroundColor Yellow

$missing = @()
foreach ($cmd in @("kubectl", "docker")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        $missing += $cmd
    }
}
if ($missing.Count -gt 0) {
    Write-Host "ERROR: Missing required tools: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "Install Docker Desktop: winget install Docker.DockerDesktop" -ForegroundColor Red
    exit 1
}

# Verify Kubernetes is reachable
$clusterCheck = kubectl cluster-info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Kubernetes is not running." -ForegroundColor Red
    Write-Host "Enable it in Docker Desktop: Settings > Kubernetes > Enable Kubernetes" -ForegroundColor Red
    exit 1
}

# Switch to docker-desktop context if available
$contexts = kubectl config get-contexts -o name 2>&1
if ($contexts -match "docker-desktop") {
    kubectl config use-context docker-desktop 2>&1 | Out-Null
    Write-Host "  Using docker-desktop context." -ForegroundColor Green
}

Write-Host "  All prerequisites met." -ForegroundColor Green

# --- Build Agent image ---
Write-Host "[2/5] Building agent:1.1 Docker image..." -ForegroundColor Yellow
docker build -t agent:1.1 "$ScriptDir\agent"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Image agent:1.1 built." -ForegroundColor Green

# --- Apply K8s manifests ---
Write-Host "[3/5] Deploying Kubernetes resources..." -ForegroundColor Yellow

$k8sDir = "$ScriptDir\k8s"
kubectl apply -f "$k8sDir\namespace.yaml"
kubectl apply -f "$k8sDir\rabbitmq-secret.yaml"
kubectl apply -f "$k8sDir\rabbitmq-deployment.yaml"
kubectl apply -f "$k8sDir\rabbitmq-service.yaml"

Write-Host "  RabbitMQ resources applied." -ForegroundColor Green

# --- Wait for RabbitMQ ---
Write-Host "[4/5] Waiting for RabbitMQ to be ready (up to 120s)..." -ForegroundColor Yellow
kubectl wait --namespace task-system `
    --for=condition=ready pod `
    -l app=rabbitmq `
    --timeout=120s

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: RabbitMQ did not become ready in time." -ForegroundColor Red
    Write-Host "Check logs:  kubectl logs -n task-system -l app=rabbitmq" -ForegroundColor Red
    exit 1
}
Write-Host "  RabbitMQ is ready." -ForegroundColor Green

# --- Deploy Agent ---
Write-Host "[5/5] Deploying Agent worker..." -ForegroundColor Yellow
kubectl apply -f "$k8sDir\agent-deployment.yaml"

kubectl wait --namespace task-system `
    --for=condition=ready pod `
    -l app=agent `
    --timeout=60s

if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Agent pod not ready yet. It may still be starting." -ForegroundColor Yellow
    Write-Host "Check status:  kubectl get pods -n task-system" -ForegroundColor Yellow
} else {
    Write-Host "  Agent is ready." -ForegroundColor Green
}

# --- Summary ---
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
kubectl get pods -n task-system
Write-Host ""
Write-Host "--- Next steps ---" -ForegroundColor Yellow
Write-Host "  1. Port-forward RabbitMQ:  kubectl port-forward -n task-system svc/rabbitmq-svc 5672:5672" -ForegroundColor White
Write-Host ""
Write-Host "  2. Launch the CLI:         pip install pika" -ForegroundColor White
Write-Host "                             python $ScriptDir\agent\cli.py" -ForegroundColor White
Write-Host ""
Write-Host "  Other commands:" -ForegroundColor Yellow
Write-Host "  RabbitMQ UI:        kubectl port-forward -n task-system svc/rabbitmq-svc 15672:15672"
Write-Host "                      Then browse to http://localhost:15672  (admin / secret)"
Write-Host "  View agent logs:    kubectl logs -n task-system -l app=agent --follow"
Write-Host "  Tear down:          kubectl delete namespace task-system"
Write-Host ""
