# Kubectl Cheat Sheet

Commonly used `kubectl` commands for managing your Kubernetes cluster.

## 1. Inspecting Resources

| Command | Description |
| :--- | :--- |
| `kubectl get pods` | List all pods in the default namespace |
| `kubectl get pods -A` | List pods in all namespaces |
| `kubectl get pods -n <namespace>` | List pods in a specific namespace |
| `kubectl get services` | List all services |
| `kubectl get deployments` | List all deployments |
| `kubectl get nodes` | List all nodes in the cluster |
| `kubectl describe pod <pod-name>` | Show detailed state of a specific pod |
| `kubectl get hpa` | List Horizontal Pod Autoscalers |

## 2. Logs & Debugging

| Command | Description |
| :--- | :--- |
| `kubectl logs <pod-name>` | Print the logs for a pod |
| `kubectl logs -f <pod-name>` | Stream logs for a pod (follow) |
| `kubectl logs -l app=<label> --follow` | Stream logs for all pods with a specific label |
| `kubectl exec -it <pod-name> -- /bin/sh` | Open an interactive shell inside a pod |
| `kubectl top pod` | Show CPU/Memory usage of pods (requires metrics-server) |

## 3. Applying & Deleting Resources

| Command | Description |
| :--- | :--- |
| `kubectl apply -f <filename.yaml>` | Create or update resources from a file |
| `kubectl delete -f <filename.yaml>` | Delete resources defined in a file |
| `kubectl delete pod <pod-name>` | Delete a specific pod |
| `kubectl delete namespace <ns-name>` | Delete an entire namespace (and everything in it) |

## 4. Connectivity & Port Forwarding

| Command | Description |
| :--- | :--- |
| `kubectl port-forward svc/<svc-name> <local-port>:<remote-port>` | Forward a local port to a service |
| `kubectl cluster-info` | Display cluster information |
| `kubectl config get-contexts` | List available cluster contexts |
| `kubectl config use-context <context-name>` | Switch to a different cluster context |

## 5. Troubleshooting Tips

- **Pod stuck in `Pending`?** Run `kubectl describe pod <name>` and look at the "Events" section at the bottom.
- **Service not reachable?** Check endpoints with `kubectl get endpoints <svc-name>`.
- **Image not pulling?** Ensure your `imagePullPolicy` is set correctly (e.g., `Never` for local images).
