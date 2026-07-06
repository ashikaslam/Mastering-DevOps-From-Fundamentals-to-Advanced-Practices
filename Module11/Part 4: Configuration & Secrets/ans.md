# Part 4: Configuration & Secrets (ConfigMaps & Secrets)

In this section, we manage application-level configurations and sensitive credentials securely within Kubernetes. This is achieved by separating our environment variables from our application container blueprint using **ConfigMaps** (for non-sensitive data) and **Secrets** (for confidential data like databases and API keys).

---

## 1. Declarative Resource Manifests

We created three independent resource manifests inside our project folder to handle configurations, sensitive passwords, and the compute unit (Pod) that consumes them.

### A. Non-Sensitive Configurations (`app-config.yaml`)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: "blue"
  APP_MODE: "production"
```

### B. Confidential Credentials (`app-secret.yaml`)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
stringData:
  DB_PASSWORD: "SuperSecretPassword123"
```
*Note: Using `stringData` allows us to define raw strings which Kubernetes automatically encodes into base64 format natively upon injection into the cluster.*

### C. Pod Specification with Environment Binding (`config-pod.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-test-pod
spec:
  containers:
  - name: test-container
    image: nginx:1.25.1
    env:
    # Binding data from ConfigMap
    - name: MY_APP_COLOR
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_COLOR
    # Binding data from Secret
    - name: MY_DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: DB_PASSWORD
```

---

## 2. Resource Application & Execution

We applied all three configurations simultaneously into our default namespace within the active Minikube cluster:

```bash
kubectl apply -f app-config.yaml -f app-secret.yaml -f config-pod.yaml
```

### Execution Status:
```text
configmap/app-config created
secret/app-secret created
pod/config-test-pod created
```

---

## 3. Verification & Runtime Inspection

To verify that the configuration maps and secure keys were correctly decrypted and bound to our runtime container environment, we executed a remote inspection query inside the running shell environment of `config-test-pod`.

### Command:
```bash
kubectl exec config-test-pod -- env | grep -E "MY_APP_COLOR|MY_DB_PASSWORD"
```

### Output:
```text
MY_APP_COLOR=blue
MY_DB_PASSWORD=SuperSecretPassword123
```

---

## Summary Observation (For Report)
> **Observation:** The execution confirms that Kubernetes decoupled environment injection is fully operational. The application container successfully referenced the external `ConfigMap` and `Secret` schemas, pulling the plain parameters into its internal system memory profile at startup. This isolates sensitive configurations cleanly from code manifests, satisfying modern GitOps and cloud-native security principles.