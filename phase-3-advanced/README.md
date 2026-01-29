# Phase 3: Advanced - Monitoring + Autoscaling

Phase 3 adds full observability and automatic scaling to the distributed task system.

## New Components

- **Prometheus** - Scrapes and stores metrics from the cluster.
- **Grafana** - Dashboarding tool for visualizing system health and throughput.
- **Horizontal Pod Autoscaling (HPA)** - Automatically scales agent replicas (between 2-4) based on CPU utilization.

## Quick Start

### 1. Ensure Phase 2 is Running
Phase 3 builds on Phase 2. Ensure your pods are running in the `task-system` namespace.

### 2. Deploy Phase 3 Resources
Run the following commands from the project root:

```powershell
kubectl apply -f phase-3-advanced/k8s/monitoring.yaml
kubectl apply -f phase-3-advanced/k8s/hpa.yaml
```

This will create a new `monitoring` namespace and deploy Prometheus, Grafana, and the HPA.

## Verification

### 1. Check Component Health
All pods should be `Running`:

```powershell
kubectl get pods -A
```

Check the HPA status:
```powershell
kubectl get hpa -n task-system
```
> [!NOTE]
> It may take a minute for the HPA to collect enough metrics to show the current CPU usage.

### 2. Access Dashboards

#### Grafana
Port-forward Grafana to access the web UI:
```powershell
kubectl port-forward -n monitoring svc/grafana-svc 3001:3000
```
Open **http://localhost:3001** in your browser.

#### RabbitMQ Management UI
```powershell
kubectl port-forward -n task-system svc/rabbitmq-svc 15672:15672
```
Open **http://localhost:15672** (admin / secret).

### 3. Test Autoscaling
1. Open the UI at **http://localhost:30080**.
2. Submit a large number of complex math tasks (e.g., `factorial(1000)`).
3. Watch the HPA scale the agent replicas:
   ```powershell
   kubectl get hpa -n task-system --watch
   ```
   Or monitor the pods:
   ```powershell
   kubectl get pods -n task-system -l app=agent --watch
   ```
