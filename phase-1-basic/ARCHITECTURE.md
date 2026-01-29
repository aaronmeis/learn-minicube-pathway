# Phase 1: Basic - Architecture

## Overview

Deploy the RabbitMQ message broker (MCP Server) and a single Python agent worker
on Docker Desktop's built-in Kubernetes. Tasks are published to a RabbitMQ queue,
consumed by the agent, and results are returned via a reply queue or a general
results queue.

## Architecture Diagram

```
+------------------Docker Desktop Kubernetes-------------------+
|                                                               |
|   +-------------------+        +----------------------+       |
|   |   RabbitMQ Pod    |        |    Agent Pod         |       |
|   |   (MCP Server)    |        |    (Python Worker)   |       |
|   |                   |        |                      |       |
|   |  Port 5672 (AMQP) |<------>|  pika consumer       |       |
|   |  Port 15672 (Mgmt)|        |  sympy processor     |       |
|   |                   |        |  result publisher     |       |
|   +-------------------+        +----------------------+       |
|          |                                                    |
|   +------+--------+                                           |
|   | rabbitmq-svc   |                                          |
|   | ClusterIP:5672 |                                          |
|   | ClusterIP:15672|                                          |
|   +----------------+                                          |
|                                                               |
+---------------------------------------------------------------+
        |
        | kubectl port-forward
        v
  +-------------------+
  | Developer         |
  | - CLI (cli.py)    |  <-- port 5672
  | - RabbitMQ Mgmt   |  <-- port 15672
  +-------------------+
```

## Flow Diagram

```
Developer submits task via CLI or RabbitMQ Management UI
        |
        v
  +-----------+     AMQP      +--------+
  | "tasks"   | ------------> | Agent  |
  |  queue    |   consume     | Worker |
  +-----------+               +--------+
                                  |
                                  | process (sympy eval,
                                  |          text operations)
                                  v
                          +---------------+
                          | Result routes |
                          | to either:    |
                          +-------+-------+
                                  |
                   +--------------+--------------+
                   |                             |
                   v                             v
           reply_to queue                 "results" queue
           (CLI gets result               (general output)
            inline)
```

## Components

| Component      | Image                       | Purpose                              |
|----------------|-----------------------------|--------------------------------------|
| RabbitMQ       | rabbitmq:3.13-management    | Message broker with management UI    |
| Agent Worker   | agent:1.1 (built locally)   | Consumes tasks, processes math/text, publishes results |

## Kubernetes Resources

| Resource       | Name              | Type        | Notes                          |
|----------------|-------------------|-------------|--------------------------------|
| Namespace      | task-system       | Namespace   | Isolates all phase-1 resources |
| Secret         | rabbitmq-secret   | Opaque      | Stores username/password       |
| Deployment     | rabbitmq          | Deployment  | 1 replica, management enabled  |
| Service        | rabbitmq-svc      | ClusterIP   | Exposes 5672 + 15672           |
| Deployment     | agent             | Deployment  | 1 replica, connects to broker  |

## Network

- Agent connects to RabbitMQ via `rabbitmq-svc:5672` (ClusterIP DNS)
- Developer accesses Management UI via `kubectl port-forward` (port 15672)
- CLI connects to RabbitMQ via `kubectl port-forward` (port 5672)
- No external ingress required in this phase
