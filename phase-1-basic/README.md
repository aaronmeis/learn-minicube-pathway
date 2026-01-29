# Phase 1: Basic - MCP Server + Single Agent

Deploy RabbitMQ (the MCP message broker) and one Python agent worker on
Docker Desktop's built-in Kubernetes. The agent consumes tasks from a queue
and processes math expressions or text operations. No extra tools beyond
Docker Desktop are required.

See [ARCHITECTURE.md](ARCHITECTURE.md) for diagrams and component details.
See [TESTING.md](TESTING.md) for all verification and testing methods.

---

## Prerequisites

Install the following tools before running the setup script. Everything runs
locally -- no cloud accounts needed.

| Tool | Purpose | Install (Windows) | Install (macOS) |
|------|---------|-------------------|-----------------|
| [Docker Desktop](https://docs.docker.com/get-docker/) | Container runtime + K8s | `winget install Docker.DockerDesktop` | `brew install --cask docker` |
| [Python 3.10+](https://www.python.org/downloads/) | Interactive CLI tool | `winget install Python.Python.3.12` | `brew install python@3.12` |

> **Enable Kubernetes:** In Docker Desktop, go to **Settings > Kubernetes >
> Enable Kubernetes** and click **Apply & Restart**. Wait for the green
> indicator in the system tray. This gives you `kubectl` and a single-node
> cluster with no extra installs.

---

## Quick Start

### 1. Run the setup script

The setup script handles everything: pre-flight checks, building the Docker
image, and deploying all Kubernetes resources. Everything runs locally -- no
external registries or cloud services required.

**PowerShell (Windows):**
```powershell
.\phase-1-basic\setup.ps1
```

**Bash (Linux / macOS):**
```bash
chmod +x phase-1-basic/setup.sh
./phase-1-basic/setup.sh
```

The script will:
1. Verify Docker Desktop and Kubernetes are running
2. Build the `agent:1.1` image locally
3. Apply all K8s manifests (namespace, secret, RabbitMQ, agent)
4. Wait for pods to be healthy
5. Print next steps

### 2. Verify pods are running

```bash
kubectl get pods -n task-system
```

Expected output:
```
NAME                        READY   STATUS    RESTARTS   AGE
rabbitmq-xxxxxxxxx-xxxxx    1/1     Running   0          60s
agent-xxxxxxxxx-xxxxx       1/1     Running   0          30s
```

---

## Using the Interactive CLI

The CLI lets you submit tasks and see results directly in your terminal.

### 1. Port-forward RabbitMQ

```bash
kubectl port-forward -n task-system svc/rabbitmq-svc 5672:5672
```

### 2. Launch the CLI (in a separate terminal)

```bash
pip install pika
python phase-1-basic/agent/cli.py
```

### 3. Interact

```
=== Task Distribution System (Phase 1) ===

  [1] Math expression
  [2] Text operation
  [3] Send batch test
  [q] Quit

> 1
  Enter expression (e.g. factorial(10), sqrt(144), 2**16): factorial(10)
  [sent] {"type": "math", "expr": "factorial(10)"}
  [result] MATH RESULT: factorial(10) = 3628800
```

Option **[3] Send batch test** sends all 6 sample tasks and prints each result
inline -- no need to check `kubectl logs` separately.

---

## Alternative: RabbitMQ Management UI

For a browser-based view of queues and messages:

```bash
kubectl port-forward -n task-system svc/rabbitmq-svc 15672:15672
```

Open http://localhost:15672 (login: `admin` / `secret`).

Agent logs are also available via:

```bash
kubectl logs -n task-system -l app=agent --follow
```

---

## Sample Tasks

| Task JSON | Expected Output |
|-----------|-----------------|
| `{"type":"math","expr":"factorial(10)"}` | `3628800` |
| `{"type":"math","expr":"sqrt(144)"}` | `12` |
| `{"type":"math","expr":"2**16"}` | `65536` |
| `{"type":"text","operation":"reverse","value":"kubernetes"}` | `setenrebuk` |
| `{"type":"text","operation":"upper","value":"hello world"}` | `HELLO WORLD` |
| `{"type":"text","operation":"length","value":"minikube"}` | `8` |

---

## Cleanup

```bash
kubectl delete namespace task-system
```

---

## Next Steps

Move on to **Phase 2** to add a second agent replica, a React frontend, and a
Flask API gateway.
