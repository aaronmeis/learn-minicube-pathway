# Phase 2: Medium - Frontend + API + Load-Balanced Agents

Phase 2 builds on the basic RabbitMQ + agent setup from Phase 1 by adding:

- **React Frontend** - Browser UI for submitting tasks and viewing results
- **Flask API Gateway** - REST API that bridges the frontend to RabbitMQ
- **2x Agent Replicas** - Competing consumers for load-balanced task processing
- **Results Queue** - Dedicated queue for collecting processed results

## Architecture

```
Browser (localhost:30080)
    |
    v
Frontend Pod (React + Nginx)
    |  nginx proxies /api/* to Flask
    v
API Pod (Flask)
    |  POST /task  -> publishes to "tasks" queue
    |  GET /results -> reads from "results" queue
    v
RabbitMQ Pod
    |
    +--> Agent Pod 1 (competing consumer)
    +--> Agent Pod 2 (competing consumer)
    |
    v
"results" queue -> API -> Frontend
```

## Prerequisites

- Docker Desktop with Kubernetes enabled
- PowerShell (Windows)

## Quick Start

```powershell
cd phase-2-medium
.\setup.ps1
```

> [!IMPORTANT]
> **Progressive Build**: The `setup.ps1` script is designed to build ON TOP of Phase 1. It will not destroy your existing RabbitMQ instance; instead, it will update the `agent` deployment and add the API and Frontend components.

The script will:
1. Build Docker images for the `agent:2.0`, `api:1.0`, and `frontend:1.0`.
2. Ensure the `task-system` namespace exists.
3. Update the existing `agent` deployment to 2 replicas and the 2.0 image.
4. Deploy the API and Frontend resources.
5. Wait for all pods to become ready.

Once complete, open **http://localhost:30080** in your browser.

## Components

| Component | Image | Replicas | Port | Purpose |
|-----------|-------|----------|------|---------|
| RabbitMQ | rabbitmq:3.13-management | 1 | 5672, 15672 | Message broker |
| API | api:1.0 | 1 | 5000 | REST gateway |
| Agent | agent:2.0 | 2 | - | Task processor |
| Frontend | frontend:1.0 | 1 | 80 (NodePort 30080) | Browser UI |

## Using the UI

1. Select **Math** or **Text** task type
2. Enter an expression (e.g., `factorial(10)`) or text value
3. Click **Submit Task**
4. Click **Fetch Results** to see processed results
5. Results show which agent pod processed each task (load balancing visible)

## Useful Commands

```powershell
# Check pod status
kubectl get pods -n task-system

# View agent logs (see load balancing)
kubectl logs -n task-system -l app=agent --follow

# View API logs
kubectl logs -n task-system -l app=api --follow

# RabbitMQ management UI
kubectl port-forward -n task-system svc/rabbitmq-svc 15672:15672
# Then open http://localhost:15672  (admin / secret)

# Tear down
kubectl delete namespace task-system
```

## What's New vs Phase 1

| Feature | Phase 1 | Phase 2 |
|---------|---------|---------|
| Task submission | CLI only | Browser UI |
| API layer | None | Flask REST API |
| Agent replicas | 1 | 2 (load balanced) |
| Results | Logs only | Dedicated queue + UI display |
| Result attribution | None | Pod hostname shown |
