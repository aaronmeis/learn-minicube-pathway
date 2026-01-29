# Phase 3: Advanced - Architecture

## Overview

Add full observability with Prometheus + Grafana dashboards, enable Horizontal
Pod Autoscaling (HPA) for agent workers, and optionally integrate KEDA for
queue-length-based scaling. Simulate load to see the system scale in real time.

## Architecture Diagram

```
+---------------------------Docker Desktop Kubernetes---------------------------+
|                                                                               |
|  +----------+  +----------+  +-----------+  +-------------+  +------------+  |
|  | Frontend |  | Flask API|  | RabbitMQ  |  | Agent Pods  |  | Metrics    |  |
|  | (React)  |->| (Flask)  |->| (MCP)     |->| (2-4 reps)  |  | Server     |  |
|  +----------+  +----------+  +-----------+  +-------------+  +------------+  |
|                                  |  |              |               |           |
|                                  |  | metrics      | metrics      | CPU/mem   |
|                                  v  v              v               v           |
|                              +-----------------------------------+            |
|                              |        Prometheus                 |            |
|                              |  (scrapes all pod metrics)        |            |
|                              +-----------------------------------+            |
|                                            |                                  |
|                                            v                                  |
|                              +-----------------------------------+            |
|                              |          Grafana                  |            |
|                              |  - K8s pod dashboard              |            |
|                              |  - RabbitMQ queue depth           |            |
|                              |  - Agent task throughput          |            |
|                              |  - CPU / Memory usage             |            |
|                              +-----------------------------------+            |
|                                                                               |
|  +------------------+    +------------------+                                 |
|  | HPA              |    | KEDA (optional)  |                                 |
|  | cpu-percent: 50% |    | RabbitMQ scaler  |                                 |
|  | min: 2, max: 4   |    | queue-length     |                                 |
|  +------------------+    +------------------+                                 |
|                                                                               |
+-------------------------------------------------------------------------------+
        |
        | port-forward Grafana :3000
        v
  +------------+
  | Developer  |
  | Grafana    |
  | Dashboards |
  +------------+
```

## Monitoring Flow

```
Agent Pods expose /metrics  ----+
RabbitMQ Prometheus exporter ---+--> Prometheus ---> Grafana Dashboards
Metrics Server (CPU/mem) ------+         |
                                          v
                                    HPA / KEDA
                                    (autoscale agents)
```

## Components (added in this phase)

| Component      | Deployment               | Purpose                              |
|----------------|--------------------------|--------------------------------------|
| Metrics Server | kubectl apply (manifest)  | CPU/memory metrics for HPA           |
| Prometheus     | Helm (prometheus-community)| Scrape and store time-series metrics |
| Grafana        | Helm (grafana)            | Dashboard visualization              |
| HPA            | kubectl autoscale         | Scale agents on CPU usage            |
| KEDA           | Helm (optional)           | Scale agents on queue length         |

## Key Grafana Dashboards

1. **Kubernetes Pods** - CPU, memory, restarts per pod
2. **RabbitMQ Overview** - Queue depth, publish/consume rates, connections
3. **Task Throughput** - Custom agent metrics: tasks processed/sec, processing time
4. **Autoscaler Activity** - Current vs desired replicas over time
