#!/usr/bin/env bash
#
# Module 14 - Automated deployment of a 3-tier app (frontend / backend / MongoDB)
# onto a local kind cluster.
#
set -euo pipefail

CLUSTER_NAME="module14-cluster"
KUBE_CONTEXT="kind-${CLUSTER_NAME}"
KUBECONFIG_PATH="${HOME}/.kube/config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 0. Preflight
# ---------------------------------------------------------------------------
for bin in kind kubectl docker; do
  command -v "$bin" >/dev/null 2>&1 || die "'$bin' is not installed or not on PATH."
done
docker info >/dev/null 2>&1 || die "Docker daemon is not running."

# Reject minikube's kubectl shim. If /usr/local/bin/kubectl is a symlink to the
# minikube binary, minikube answers as kubectl and pins every request to the
# minikube apiserver (e.g. 192.168.49.2:8443) no matter which context is
# selected - so kubeconfig looks correct while nothing can reach the kind cluster.
is_minikube_shim() { [[ "$(basename "$(readlink -f "$1")")" == "minikube" ]]; }

KUBECTL="$(command -v kubectl)"
if is_minikube_shim "${KUBECTL}"; then
  for candidate in "${HOME}/.local/bin/kubectl" /usr/bin/kubectl; do
    if [[ -x "${candidate}" ]] && ! is_minikube_shim "${candidate}"; then
      KUBECTL="${candidate}"
      break
    fi
  done
  if is_minikube_shim "${KUBECTL}"; then
    die "'kubectl' resolves to minikube's shim (${KUBECTL} -> minikube), which forces all
  traffic to the minikube apiserver and cannot reach the kind cluster.
  Install a real kubectl ahead of it on PATH, e.g.:
    curl -fsSLo ~/.local/bin/kubectl https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl
    chmod +x ~/.local/bin/kubectl"
  fi
  log "Note: 'kubectl' is minikube's shim - using ${KUBECTL} instead"
fi

# ---------------------------------------------------------------------------
# 1. Clean stale kube state
#    A leftover KUBECONFIG env var or a cached discovery response from an old
#    Minikube IP makes kubectl talk to a dead API server. Drop both.
# ---------------------------------------------------------------------------
log "Clearing stale kubeconfig environment and cache"
unset KUBECONFIG || true
rm -rf "${HOME}/.kube/cache"
mkdir -p "${HOME}/.kube"

# ---------------------------------------------------------------------------
# 2. Create the kind cluster if it does not already exist
# ---------------------------------------------------------------------------
if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  log "Cluster '${CLUSTER_NAME}' already exists - skipping creation"
else
  log "Creating kind cluster '${CLUSTER_NAME}' (1 control-plane + 2 workers)"
  kind create cluster --name "${CLUSTER_NAME}" --config "${SCRIPT_DIR}/kind-config.yaml"
fi

# ---------------------------------------------------------------------------
# 3. Export kubeconfig + select the context
# ---------------------------------------------------------------------------
log "Exporting kubeconfig to ${KUBECONFIG_PATH}"
kind export kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_PATH}"

log "Switching kubectl context to '${KUBE_CONTEXT}'"
"${KUBECTL}" config use-context "${KUBE_CONTEXT}"

log "Waiting for all nodes to become Ready"
"${KUBECTL}" wait --for=condition=Ready nodes --all --timeout=180s

# ---------------------------------------------------------------------------
# 4. Apply the manifests, in dependency order
# ---------------------------------------------------------------------------
log "Applying manifests"
for manifest in \
  secrets.yaml \
  pvc.yaml \
  database-deployment.yaml \
  backend-deployment.yaml \
  frontend-deployment.yaml \
  services.yaml
do
  echo "  - ${manifest}"
  "${KUBECTL}" apply -f "${SCRIPT_DIR}/${manifest}"
done

# ---------------------------------------------------------------------------
# 5. Wait for the workloads to roll out
# ---------------------------------------------------------------------------
log "Waiting for deployments to roll out"
for deploy in database-deployment backend-deployment frontend-deployment; do
  "${KUBECTL}" rollout status "deployment/${deploy}" --timeout=300s
done

# ---------------------------------------------------------------------------
# 6. Report cluster state
# ---------------------------------------------------------------------------
log "Nodes"
"${KUBECTL}" get nodes

log "Pods"
"${KUBECTL}" get pods -o wide

log "Services"
"${KUBECTL}" get svc

log "Deployment complete"
echo "Frontend is reachable at: http://localhost:30080"
