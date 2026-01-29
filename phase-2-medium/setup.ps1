# Phase 2 Setup Script - Windows PowerShell
# Deploys React Frontend, Flask API, RabbitMQ, and 2x Agent workers
# to Docker Desktop Kubernetes.
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
Write-Host "=== Phase 2: Medium - Frontend + API + Load-Balanced Agents ===" -ForegroundColor Cyan
Write-Host ""

# --- Pre-flight checks ---
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor Yellow

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

# --- Ensure namespace exists ---
Write-Host "[2/8] Ensuring task-system namespace exists..." -ForegroundColor Yellow
$ErrorActionPreference = "SilentlyContinue"
$nsExists = kubectl get namespace task-system 2>&1
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace task-system
    Write-Host "  Namespace task-system created." -ForegroundColor Green
} else {
    Write-Host "  Namespace task-system already exists. Continuing with progressive update..." -ForegroundColor Green
}
$ErrorActionPreference = "Stop"

# --- Build Docker images ---
Write-Host "[3/8] Building agent:2.0 Docker image..." -ForegroundColor Yellow
docker build -t agent:2.0 "$ScriptDir\agent"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Agent Docker build failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Image agent:2.0 built." -ForegroundColor Green

Write-Host "[4/8] Building api:1.0 Docker image..." -ForegroundColor Yellow
docker build -t api:1.0 "$ScriptDir\api"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: API Docker build failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Image api:1.0 built." -ForegroundColor Green

Write-Host "[5/8] Building frontend:1.0 Docker image..." -ForegroundColor Yellow
docker build -t frontend:1.0 "$ScriptDir\frontend"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Frontend Docker build failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Image frontend:1.0 built." -ForegroundColor Green

# --- Apply K8s manifests ---
Write-Host "[6/8] Deploying Kubernetes resources..." -ForegroundColor Yellow

$k8sDir = "$ScriptDir\k8s"
kubectl apply -f "$k8sDir\namespace.yaml"
kubectl apply -f "$k8sDir\rabbitmq-secret.yaml"
kubectl apply -f "$k8sDir\rabbitmq-deployment.yaml"
kubectl apply -f "$k8sDir\rabbitmq-service.yaml"

Write-Host "  RabbitMQ resources applied." -ForegroundColor Green

# --- Wait for RabbitMQ ---
Write-Host "[7/8] Waiting for RabbitMQ to be ready (up to 120s)..." -ForegroundColor Yellow
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

# --- Deploy API, Agents, and Frontend ---
Write-Host "[8/8] Deploying API, Agents, and Frontend..." -ForegroundColor Yellow

kubectl apply -f "$k8sDir\api-deployment.yaml"
kubectl apply -f "$k8sDir\api-service.yaml"
kubectl apply -f "$k8sDir\agent-deployment.yaml"
kubectl apply -f "$k8sDir\frontend-deployment.yaml"
kubectl apply -f "$k8sDir\frontend-service.yaml"

Write-Host "  Waiting for all pods to be ready (up to 120s)..." -ForegroundColor Yellow

kubectl wait --namespace task-system `
    --for=condition=ready pod `
    -l app=api `
    --timeout=120s

kubectl wait --namespace task-system `
    --for=condition=ready pod `
    -l app=agent `
    --timeout=120s

kubectl wait --namespace task-system `
    --for=condition=ready pod `
    -l app=frontend `
    --timeout=120s

if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Some pods may not be ready yet." -ForegroundColor Yellow
    Write-Host "Check status:  kubectl get pods -n task-system" -ForegroundColor Yellow
} else {
    Write-Host "  All pods are ready." -ForegroundColor Green
}

# --- Summary ---
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
kubectl get pods -n task-system
Write-Host ""
kubectl get svc -n task-system
Write-Host ""
Write-Host "--- Access the UI ---" -ForegroundColor Yellow
Write-Host "  Open in browser:  http://localhost:30080" -ForegroundColor White
Write-Host ""
Write-Host "--- Other commands ---" -ForegroundColor Yellow
Write-Host "  RabbitMQ UI:        kubectl port-forward -n task-system svc/rabbitmq-svc 15672:15672"
Write-Host "                      Then browse to http://localhost:15672  (admin / secret)"
Write-Host "  View agent logs:    kubectl logs -n task-system -l app=agent --follow"
Write-Host "  View API logs:      kubectl logs -n task-system -l app=api --follow"
Write-Host "  Tear down:          kubectl delete namespace task-system"
Write-Host ""
