### Integrated Demo Project: Task Distribution System with Agents and Monitoring

A distributed task processing system running on Docker Desktop's built-in
Kubernetes. Users submit math or text-processing tasks, a RabbitMQ message
broker (MCP Server) queues them, and Python agent workers process and return
results. Everything runs locally -- no cloud accounts or external services.

The system demonstrates Kubernetes orchestration, messaging, scaling, and
observability through three progressive phases.

---

#### Project Structure

```
phase-1-basic/      MCP Server (RabbitMQ) + single agent worker
phase-2-medium/     Add second agent, React frontend, Flask API
phase-3-advanced/   Prometheus + Grafana monitoring, autoscaling
```

Each phase folder contains:
- `ARCHITECTURE.md` -- diagrams and component details
- `README.md` -- setup instructions (Phase 1)
- `TESTING.md` -- verification methods (Phase 1)

---

#### Phase 1: Basic -- MCP Server + Single Agent

Deploy RabbitMQ and one Python agent worker. Test via an interactive CLI or
the RabbitMQ Management UI.

- **Components**: RabbitMQ pod, Python agent (pika + sympy)
- **Concepts**: Messaging basics, secrets, pod networking, ClusterIP services
- **See**: [phase-1-basic/README.md](phase-1-basic/README.md)

#### Phase 2: Medium -- Second Agent + Frontend UI

Scale to two agent replicas for load-balanced processing. Add a React frontend
and Flask API gateway for browser-based task submission and result display.

- **Components**: React frontend, Flask API, 2x agent replicas, results queue
- **Concepts**: Multi-replica scaling, services, full-stack integration
- **See**: [phase-2-medium/ARCHITECTURE.md](phase-2-medium/ARCHITECTURE.md)

#### Phase 3: Advanced -- Monitoring + Autoscaling

Add Prometheus and Grafana for real-time dashboards. Enable Horizontal Pod
Autoscaling (HPA) and optionally KEDA for queue-length-based scaling.

- **Components**: Prometheus, Grafana, HPA, KEDA (optional)
- **Concepts**: Observability, custom dashboards, event-driven scaling
- **See**: [phase-3-advanced/ARCHITECTURE.md](phase-3-advanced/ARCHITECTURE.md)

---

#### Prerequisites

| Tool | Purpose | Install (Windows) | Install (macOS) |
|------|---------|-------------------|-----------------|
| [Docker Desktop](https://docs.docker.com/get-docker/) | Container runtime + K8s | `winget install Docker.DockerDesktop` | `brew install --cask docker` |
| [Python 3.10+](https://www.python.org/downloads/) | Interactive CLI tool | `winget install Python.Python.3.12` | `brew install python@3.12` |

> **Enable Kubernetes:** In Docker Desktop, go to **Settings > Kubernetes >
> Enable Kubernetes** and click **Apply & Restart**. This gives you `kubectl`
> and a single-node cluster with no extra installs.

#### Quick Start (Phase 1)

```powershell
.\phase-1-basic\setup.ps1
```

See [phase-1-basic/README.md](phase-1-basic/README.md) for full instructions.
