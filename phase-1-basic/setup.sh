#!/usr/bin/env bash
# Phase 1 Setup Script - Linux / macOS
# Deploys RabbitMQ (MCP Server) and Agent worker to Docker Desktop Kubernetes.
#
# Prerequisites:
#   - Docker Desktop running with Kubernetes enabled
#     (Settings > Kubernetes > Enable Kubernetes)
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "=== Phase 1: Basic - MCP Server + Single Agent ==="
echo ""

# --- Pre-flight checks ---
echo "[1/5] Checking prerequisites..."

missing=()
for cmd in kubectl docker; do
    if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
    fi
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing required tools: ${missing[*]}"
    echo "Install Docker Desktop: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
    echo "ERROR: Kubernetes is not running."
    echo "Enable it in Docker Desktop: Settings > Kubernetes > Enable Kubernetes"
    exit 1
fi

# Switch to docker-desktop context if available
if kubectl config get-contexts -o name 2>/dev/null | grep -q "docker-desktop"; then
    kubectl config use-context docker-desktop &>/dev/null
    echo "  Using docker-desktop context."
fi

echo "  All prerequisites met."

# --- Build Agent image ---
echo "[2/5] Building agent:1.1 Docker image..."
docker build -t agent:1.1 "$SCRIPT_DIR/agent"
echo "  Image agent:1.1 built."

# --- Apply K8s manifests ---
echo "[3/5] Deploying Kubernetes resources..."

K8S_DIR="$SCRIPT_DIR/k8s"
kubectl apply -f "$K8S_DIR/namespace.yaml"
kubectl apply -f "$K8S_DIR/rabbitmq-secret.yaml"
kubectl apply -f "$K8S_DIR/rabbitmq-deployment.yaml"
kubectl apply -f "$K8S_DIR/rabbitmq-service.yaml"

echo "  RabbitMQ resources applied."

# --- Wait for RabbitMQ ---
echo "[4/5] Waiting for RabbitMQ to be ready (up to 120s)..."
kubectl wait --namespace task-system \
    --for=condition=ready pod \
    -l app=rabbitmq \
    --timeout=120s

echo "  RabbitMQ is ready."

# --- Deploy Agent ---
echo "[5/5] Deploying Agent worker..."
kubectl apply -f "$K8S_DIR/agent-deployment.yaml"

if kubectl wait --namespace task-system \
    --for=condition=ready pod \
    -l app=agent \
    --timeout=60s 2>/dev/null; then
    echo "  Agent is ready."
else
    echo "  WARNING: Agent pod not ready yet. It may still be starting."
    echo "  Check status:  kubectl get pods -n task-system"
fi

# --- Summary ---
echo ""
echo "=== Setup Complete ==="
echo ""
kubectl get pods -n task-system
echo ""
echo "--- Next steps ---"
echo "  1. Port-forward RabbitMQ:  kubectl port-forward -n task-system svc/rabbitmq-svc 5672:5672"
echo ""
echo "  2. Launch the CLI:         pip install pika"
echo "                             python $SCRIPT_DIR/agent/cli.py"
echo ""
echo "  Other commands:"
echo "  RabbitMQ UI:        kubectl port-forward -n task-system svc/rabbitmq-svc 15672:15672"
echo "                      Then browse to http://localhost:15672  (admin / secret)"
echo "  View agent logs:    kubectl logs -n task-system -l app=agent --follow"
echo "  Tear down:          kubectl delete namespace task-system"
echo ""
