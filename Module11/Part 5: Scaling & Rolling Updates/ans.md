# Pod Verification Inspection

```bash
kubectl get pods
```

**Cluster Runtime Output:**

```
NAME                                READY   STATUS    RESTARTS   AGE
config-test-pod                     1/1     Running   0          6m49s
nginx-deployment-65666b7f6f-27hrx   1/1     Running   0          17m
nginx-deployment-65666b7f6f-4wmps   1/1     Running   0          11s
nginx-deployment-65666b7f6f-55bgt   1/1     Running   0          17m
nginx-deployment-65666b7f6f-78n6h   1/1     Running   0          17m
nginx-deployment-65666b7f6f-7jjzf   1/1     Running   0          11s
```

**Observation:** Kubernetes created 2 additional pods instantaneously (aged 11s), safely distributing compute requirements over 5 fully active running instances.

---

# 2. Zero-Downtime Rolling Updates (Upgrading Image Version)

To update the application layer safely, we initiated a rolling update by changing the container image configuration from the older stable build `nginx:1.25.1` to the newer minor update release `nginx:1.26.1`.

### Image Update Command

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.26.1
```

### Live Rollout Status Tracking

To verify that traffic was not interrupted, we monitored the step-by-step rollout loop engine:

```bash
kubectl rollout status deployment/nginx-deployment
```

**Live CLI Log Streams:**

```
Waiting for deployment "nginx-deployment" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deployment" rollout to finish: 4 of 5 updated replicas are available...
deployment "nginx-deployment" successfully rolled out
```

### Architectural Breakdown

Kubernetes follows a rolling orchestration model:

1. It spins up a new pod with the `nginx:1.26.1` version.
2. Once the new pod passes its readiness checks, Kubernetes routes production traffic to it.
3. Simultaneously, it safely drains and terminates an older `nginx:1.25.1` pod replica.
4. This loop continues until all 5 replicas are upgraded cleanly without dropping any user requests.

---

# 3. Post-Upgrade Verification

We inspected the production specification layout metadata inside our active deployment scheme to cross-verify the underlying image tag version.

### Command

```bash
kubectl describe deployment nginx-deployment | grep -i image
```

**Definitive Execution Output:**

```
    Image:         nginx:1.26.1
```