# Multi-Resource Deployment — Nginx on Minikube

## 1. Simple Explanation of the Manifest

**Deployment Component:** Tells Kubernetes to pull the official `nginx:1.25.1` lightweight web server image and ensure that exactly 3 healthy clones (replicas) are running across the cluster at all times.

**Service Component:** Acts as an internal load balancer or "traffic police." It targets any pod with the label `app: nginx` and exposes it on a stable internal IP, routing incoming traffic from port 80 down to the pods.

---

## 2. Deployment Execution & Troubleshooting

### Initial Attempt

We applied the manifest directly to our active Minikube cluster:

```bash
kubectl apply -f nginx-deployment.yaml
```

**Observation:** The components were declared successfully, but checking the pod health showed an `ImagePullBackOff` status. This occurred due to local network latency or Docker Hub query throttling, preventing Minikube from fetching the remote Nginx image directly.

```bash
$ kubectl get pods
NAME                                READY   STATUS             RESTARTS   AGE
nginx-deployment-65666b7f6f-6hc4d   0/1     ImagePullBackOff   0          2m29s
```

### Optimization & Fix Action

To bypass external network bottlenecks, we redirected Minikube to interface directly with our machine's local Docker environment, pulled the image natively, and redeployed:

```bash
# Clean up the pending deployment
kubectl delete -f nginx-deployment.yaml

# Point terminal session to Minikube's Docker daemon
eval $(minikube docker-env)

# Pre-cache the image locally
docker pull nginx:1.25.1

# Re-apply the manifest
kubectl apply -f nginx-deployment.yaml
```

---

## 3. Verification of Healthy Running State

After utilizing the local caching technique, the pods pulled the container image instantly and successfully transitioned into a healthy operating state.

**Command:**

```bash
kubectl get pods
```

**Output:**

```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-65666b7f6f-27hrx   1/1     Running   0          10s
nginx-deployment-65666b7f6f-55bgt   1/1     Running   0          10s
nginx-deployment-65666b7f6f-78n6h   1/1     Running   0          10s
```

**Command:**

```bash
kubectl get service nginx-service
```

**Output:**

```
NAME            TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.108.166.144   <none>        80:30080/TCP   22s
```

---

## 4. Summary Observation

By referencing a single multi-resource configuration file, we successfully launched a 3-replica Nginx application along with a routing Service. Overcoming initial image pull challenges through caching, all three application pods achieved a healthy `Running` status under 10 seconds, proving our declarative design is stable, robust, and correctly balanced.