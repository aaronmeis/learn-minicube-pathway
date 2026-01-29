# Phase 1: Testing and Verification

Methods to verify the system is working end-to-end after running the setup
script.

---

## 1. Pod Health Check

Confirm both pods are running and ready:

```bash
kubectl get pods -n task-system
```

Expected:
```
NAME                       READY   STATUS    RESTARTS   AGE
rabbitmq-xxxxxxxxx-xxxxx   1/1     Running   0          60s
agent-xxxxxxxxx-xxxxx      1/1     Running   0          30s
```

For more detail on a specific pod (events, env vars, restart reasons):

```bash
kubectl describe pod -n task-system -l app=agent
kubectl describe pod -n task-system -l app=rabbitmq
```

---

## 2. Agent Logs

Watch the agent's stdout in real time. Every task consumed and processed
appears here.

```bash
kubectl logs -n task-system -l app=agent --follow
```

On startup you should see:
```
[*] Connecting to RabbitMQ at rabbitmq-svc:5672 (attempt 1/10)...
[+] Connected to RabbitMQ.
[*] Waiting for tasks on queue 'tasks'. Press CTRL+C to exit.
```

When a task is processed:
```
[*] Received task: {"type": "math", "expr": "factorial(10)"}
[+] MATH RESULT: factorial(10) = 3628800
```

---

## 3. Interactive CLI (recommended)

The most complete test -- sends tasks and shows results inline.

**Terminal 1** -- port-forward RabbitMQ:
```bash
kubectl port-forward -n task-system svc/rabbitmq-svc 5672:5672
```

**Terminal 2** -- run the CLI:
```bash
pip install pika
python phase-1-basic/agent/cli.py
```

Menu options:

| Option | What it does |
|--------|-------------|
| `[1] Math expression` | Enter any sympy expression, get result inline |
| `[2] Text operation` | Pick reverse/upper/lower/length, enter text |
| `[3] Send batch test` | Sends all 6 sample tasks, prints each result |
| `[q] Quit` | Exit the CLI |

Example session:
```
> 1
  Enter expression (e.g. factorial(10), sqrt(144), 2**16): factorial(10)
  [sent] {"type": "math", "expr": "factorial(10)"}
  [result] MATH RESULT: factorial(10) = 3628800
```

---

## 4. RabbitMQ Management UI

Browser-based dashboard for inspecting queues, connections, and message rates.

```bash
kubectl port-forward -n task-system svc/rabbitmq-svc 15672:15672
```

Open http://localhost:15672 (login: `admin` / `secret`).

### What to check

| Tab | What to look for |
|-----|-----------------|
| **Overview** | 1 connection (the agent), message rates |
| **Connections** | Agent's connection from the pod IP |
| **Queues** | `tasks` queue (0 messages if agent is consuming), `results` queue |

### Publish a test message manually

1. Go to **Queues** > **tasks** > **Publish message**
2. Set **Payload** to:
   ```json
   {"type": "math", "expr": "factorial(10)"}
   ```
3. Click **Publish message**
4. Check agent logs -- you should see the result printed

---

## 5. Kubernetes Resource Inspection

### Pod resource usage

```bash
kubectl top pods -n task-system
```

> Requires the metrics-server addon. If not enabled, this will return an error
> which is fine for Phase 1.

### Service and endpoint verification

Confirm the service is routing to the RabbitMQ pod:

```bash
kubectl get svc -n task-system
kubectl get endpoints -n task-system
```

Expected:
```
NAME           TYPE        CLUSTER-IP     PORT(S)              AGE
rabbitmq-svc   ClusterIP   10.x.x.x      5672/TCP,15672/TCP   2m
```

### Secret verification

Confirm the secret exists (values are base64-encoded):

```bash
kubectl get secret rabbitmq-secret -n task-system -o yaml
```

---

## 6. End-to-End Smoke Test Checklist

Run through this after any code or manifest change:

- [ ] `kubectl get pods -n task-system` shows both pods `Running` and `1/1` ready
- [ ] Agent logs show `Connected to RabbitMQ` (no retry loops)
- [ ] RabbitMQ Management UI loads at http://localhost:15672
- [ ] Management UI shows 1 active connection (the agent)
- [ ] Publishing a message via the Management UI produces a result in agent logs
- [ ] CLI `[1] Math expression` returns a result (e.g. `factorial(10)` = `3628800`)
- [ ] CLI `[2] Text operation` returns a result (e.g. `reverse("kubernetes")` = `setenrebuk`)
- [ ] CLI `[3] Send batch test` processes all 6 tasks without errors

---

## Sample Tasks Reference

| Task JSON | Expected Output |
|-----------|-----------------|
| `{"type":"math","expr":"factorial(10)"}` | `3628800` |
| `{"type":"math","expr":"sqrt(144)"}` | `12` |
| `{"type":"math","expr":"2**16"}` | `65536` |
| `{"type":"text","operation":"reverse","value":"kubernetes"}` | `setenrebuk` |
| `{"type":"text","operation":"upper","value":"hello world"}` | `HELLO WORLD` |
| `{"type":"text","operation":"length","value":"minikube"}` | `8` |
