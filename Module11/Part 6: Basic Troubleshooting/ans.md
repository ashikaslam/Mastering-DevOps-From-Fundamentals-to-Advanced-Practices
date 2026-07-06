# Part 6: Basic Troubleshooting (Cluster Inspection & Diagnostic Routines)

In production Kubernetes administration, effectively debugging structural layer anomalies separates minor platform interruptions from extended system outages. This section documents a tactical diagnostic breakdown of cluster state inspection and deliberate error simulation to demonstrate the utility of core telemetry commands.

---

## 1. Global Event Log Analysis

To audit historical orchestration actions, we queried the cluster control-plane logging mechanism, sorting occurrences by execution timestamp.

```bash
kubectl get events --sort-by='.metadata.creationTimestamp'
```

### Insights From Event Stream:
* **Infrastructure Initialization:** Logs successfully validated Node readiness signals (`NodeReady`, `Starting kubelet`).
* **Deployment Evolution History:** Captured our prior rolling update lifecycle where the control plane scaled up the new version container controller (`replicaset/nginx-deployment-6cfc469d6d`), dynamically verified `nginx:1.26.1` image assembly loops, and sequentially issued clean termination signals (`Stopping container nginx`) to legacy structures.

---

## 2. Simulating Structural Failures (`error-pod.yaml`)

We provisioned an intentional failure vector utilizing an invalid repository reference tag to evaluate how the system traps errors.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: faulty-nginx-pod
spec:
  containers:
  - name: nginx-container
    image: nginx:invalid-tag-12345
```

We applied the faulty layout directly to the active cluster environment:
```bash
kubectl apply -f error-pod.yaml
```

---

## 3. Applying Core Troubleshooting Triad Commands

### Diagnostic Command 1: Structural State Verification
```bash
kubectl get pods faulty-nginx-pod
```
**Output Capture:**
```text
NAME               READY   STATUS             RESTARTS   AGE
faulty-nginx-pod   0/1     ImagePullBackOff   0          9s
```
*Analysis: The runtime environment flags an immediate `ImagePullBackOff` loop state, signifying an immutable condition halting compute initialization.*

### Diagnostic Command 2: Detailed Infrastructure Inspection
```bash
kubectl describe pod faulty-nginx-pod
```
**Critical Events Block Harvested:**
```text
Events:
  Type     Reason          Age               From               Message
  ----     ------          ----              ----               -------
  Normal   Scheduled       20s               default-scheduler  Successfully assigned default/faulty-nginx-pod to minikube
  Warning  Failed          16s               kubelet            spec.containers{nginx-container}: Failed to pull image "nginx:invalid-tag-12345": Error response from daemon: manifest for nginx:invalid-tag-12345 not found: manifest unknown: manifest unknown
  Warning  Failed          16s               kubelet            spec.containers{nginx-container}: Error: ErrImagePull
  Normal   SandboxChanged  15s               kubelet            Pod sandbox changed, it will be killed and re-created.
  Normal   BackOff         13s (x3 over 15s) kubelet            spec.containers{nginx-container}: Back-off pulling image "nginx:invalid-tag-12345"
  Warning  Failed          13s (x3 over 15s) kubelet            spec.containers{nginx-container}: Error: ImagePullBackOff
```
*Analysis: The Kubelet daemon leaves explicit tracking logs indicating that Docker registry communication returned a clear upstream error (`manifest unknown`), confirming that the asset image requested does not exist.*

### Diagnostic Command 3: Pod Execution Stream Capture
```bash
kubectl logs faulty-nginx-pod
```
**Output Capture:**
```text
Error from server (BadRequest): container "nginx-container" in pod "faulty-nginx-pod" is waiting to start: trying and failing to pull image
```
*Analysis: Because the container application layers cannot be fetched, the sandbox engine cannot execute runtime tracking (`kubectl logs`), indicating the fault lies squarely within the container image registry lookup space.*

---

## 4. Post-Diagnostic Sanitization

Upon isolating the failure context, we scrubbed the experimental namespace clean:
```bash
kubectl delete -f error-pod.yaml
```

---

## Summary Observation (For Report)
> **Observation:** This troubleshooting cycle confirms our knowledge of production-grade diagnostics. By chaining status identification (`get`), control plane analysis (`describe`), and access inspection (`logs`), we successfully isolated a registry configuration fault down to exact root-causes. The diagnostic trial demonstrates systemic confidence in handling common cluster orchestration problems.