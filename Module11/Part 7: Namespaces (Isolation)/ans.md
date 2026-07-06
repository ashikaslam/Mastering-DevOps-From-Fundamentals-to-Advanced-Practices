# Part 7: Namespaces (Logical Isolation within a Cluster)

In production multi-tenant environments, isolating workloads is crucial to ensure that different development teams, staging setups, or microservices do not clash or accidentally modify each other's compute footprints. This section demonstrates how **Kubernetes Namespaces** establish logical, virtual boundary isolation within a single shared physical cluster.

---

## 1. Creating and Verifying a Custom Boundary

We provisioned a dedicated, isolated partition named `dev-team` to segregate our experimental resources from the default active workspace.

### Creation Command:
```bash
kubectl create namespace dev-team
```

### Active Namespaces Audit:
```bash
kubectl get namespaces
```

### Cluster Space Discovery Output:
```text
NAME              STATUS   AGE
default           Active   45m
dev-team          Active   9s
kube-node-lease   Active   45m
kube-public       Active   45m
kube-system       Active   45m
```
*Observation: The workspace container array successfully shows our newly initialized `dev-team` partition ready to isolate workloads independently.*

---

## 2. Deploying a Workload inside the Isolated Workspace

We drafted a standalone pod blueprint (`dev-pod.yaml`) and instructed the API control plane to route the resource instantiation directly inside our virtual wall boundary.

```bash
kubectl apply -f dev-pod.yaml --namespace=dev-team
```
**Output Capture:** `pod/dev-nginx-pod created`

---

## 3. Testing Context and Isolation Limits

To prove that the resources are genuinely segmented, we executed scoping queries inside both default and targeted logical environments.

### Isolation Test 1: Querying the Default Namespace Context
```bash
kubectl get pods
```
**Output Stream:**
```text
NAME                                READY   STATUS    RESTARTS   AGE
config-test-pod                     1/1     Running   0          21m
nginx-deployment-6cfc469d6d-27cml   1/1     Running   0          14m
nginx-deployment-6cfc469d6d-62qls   1/1     Running   0          13m
nginx-deployment-6cfc469d6d-94pdz   1/1     Running   0          14m
nginx-deployment-6cfc469d6d-gzm5p   1/1     Running   0          14m
nginx-deployment-6cfc469d6d-qlgwx   1/1     Running   0          13m
```
*Result: Our newly created `dev-nginx-pod` is invisible here. The default context has absolutely no structural knowledge of its existence.*

### Isolation Test 2: Targeted Querying inside the `dev-team` Context
```bash
kubectl get pods --namespace=dev-team
```
**Output Stream:**
```text
NAME            READY   STATUS    RESTARTS   AGE
dev-nginx-pod   1/1     Running   0          15s
```
*Result: The deployment target successfully exists and executes in its own sandboxed layer without bleeding into other default environments.*

---

## 4. Automatic Cascading Clean Up

Namespaces simplify resource lifecycles. By terminating the boundary parent entity, Kubernetes safely drops all internal sub-resources recursively in a cascading manner.

```bash
kubectl delete namespace dev-team
```
**Output Capture:** `namespace "dev-team" deleted`

---

## Summary Observation (For Report)
> **Observation:** The practical lab run proves the declarative isolation limits of Kubernetes Namespaces. Resources housed inside `--namespace=dev-team` ran completely hidden from default target planes, preventing cross-tenant interference. The automated cascading cleanup via parent namespace deletion also demonstrates how easy it is to manage multi-tenant lifecycles cleanly.