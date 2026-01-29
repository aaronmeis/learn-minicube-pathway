# Phase 2: Medium - Architecture

## Overview

Add a second agent replica for load-balanced task processing, a React frontend
for browser-based task submission, and a Flask API gateway that bridges
the frontend to RabbitMQ. Results flow back through a dedicated results queue.

## Architecture Diagram

```
+------------------------Docker Desktop Kubernetes-------------------------+
|                                                                           |
|  +----------------+    +----------------+    +---------------------+      |
|  | Frontend Pod   |    |  API Pod       |    |   RabbitMQ Pod      |      |
|  | (React + Nginx)|    |  (Flask)       |    |   (MCP Server)      |      |
|  |                |--->|                |--->|                     |      |
|  | NodePort:30080 |    | POST /task     |    |  "tasks" queue      |      |
|  |                |<---|                |<---|  "results" queue    |      |
|  +----------------+    | GET /results   |    +---------------------+      |
|                        +----------------+             |    |              |
|                                                       |    |              |
|                                          +------------+    +-----------+  |
|                                          |                             |  |
|                                   +------+------+          +----------+  |
|                                   | Agent Pod 1 |          |Agent Pod 2|  |
|                                   | (Python)    |          |(Python)   |  |
|                                   | replica 1   |          |replica 2  |  |
|                                   +-------------+          +-----------+  |
|                                                                           |
+---------------------------------------------------------------------------+
        |
        | kubectl port-forward / NodePort
        v
  +------------+
  | User       |
  | (Browser)  |
  | React UI   |
  +------------+
```

## Flow Diagram

```
User submits task via React UI
        |
        v
  Flask API (POST /task)
        |
        v
  RabbitMQ "tasks" queue
        |
   (competing consumers)
   /                 \
  v                   v
Agent 1             Agent 2
  |                   |
  v                   v
Process task       Process task
  |                   |
  v                   v
  RabbitMQ "results" queue
        |
        v
  Flask API (GET /results)
        |
        v
  React UI displays result
```

## Components (added in this phase)

| Component      | Image                       | Purpose                              |
|----------------|-----------------------------|--------------------------------------|
| Frontend       | frontend:1.0 (React+Nginx)  | Browser UI for task submission       |
| Flask API      | api:1.0 (Flask)             | REST gateway to RabbitMQ             |
| Agent (x2)     | agent:2.0                   | Upgraded with result publishing      |
