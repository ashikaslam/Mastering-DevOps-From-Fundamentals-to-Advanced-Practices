# Module 9 — Docker Installation and Networking on AWS EC2

**Course:** Mastering DevOps — From Fundamentals to Advanced Practices (Ostad)

---

## Objectives

- Install Docker on AWS EC2 (Ubuntu 22.04)
- Configure non-root Docker access for the `ubuntu` user
- Run `hello-world` to verify the setup
- Explore 4 Docker network drivers: Bridge, Host, None, Custom Bridge

---

## Part 1 — Docker Installation

```bash
# 1. Update packages
sudo apt-get update -y && sudo apt-get upgrade -y

# 2. Install Docker
sudo apt-get install -y docker.io

# 3. Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# 4. Add ubuntu user to docker group (no sudo needed)
sudo usermod -aG docker ubuntu
newgrp docker

# 5. Verify installation
docker run hello-world
```

---

## Part 2 — Docker Networking

### List existing networks
```bash
docker network ls
```

---

### 2.1 Default Bridge Network

Default network used when no `--network` flag is given. Containers communicate by IP only — no DNS.

```bash
# Inspect the default bridge
docker network inspect bridge

# Run two containers
docker run -d --name container-A alpine sleep infinity
docker run -d --name container-B alpine sleep infinity

# Get container-A's IP, then ping it from container-B
docker inspect container-A --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker exec container-B ping -c 4 <container-A-IP>

# Cleanup
docker stop container-A container-B && docker rm container-A container-B
```

---

### 2.2 Host Network

Container shares the EC2 host's network stack directly. No port mapping needed.

```bash
# Run Nginx on host network
docker run -d --name nginx-host --network host nginx:latest

# Test it
curl -I http://localhost:80

# Cleanup
docker stop nginx-host && docker rm nginx-host
```

> Ensure EC2 Security Group has port **80** open inbound.

---

### 2.3 None Network

Container has zero network access — loopback interface only.

```bash
# Run isolated container
docker run -it --rm --name isolated --network none alpine sh

# Inside the container:
ip addr show        # only loopback (lo) visible
ping -c 3 8.8.8.8  # fails — network unreachable
ping -c 3 127.0.0.1 # works — loopback only
exit
```

---

### 2.4 Custom Bridge Network

User-defined bridge with **automatic DNS** — containers reach each other by name.

```bash
# Create the network
docker network create --driver bridge my-custom-network

# Run two containers on it
docker run -d --name container1 --network my-custom-network alpine sleep infinity
docker run -d --name container2 --network my-custom-network alpine sleep infinity

# Ping by container NAME (DNS works here)
docker exec container1 ping -c 4 container2
docker exec container2 ping -c 4 container1

# Cleanup
docker stop container1 container2
docker rm container1 container2
docker network rm my-custom-network
```

---

## Network Driver Summary

| Driver | DNS | Isolation | Use Case |
|--------|-----|-----------|----------|
| Default Bridge | ✗ | Moderate | Quick testing |
| Host | N/A | None | High-performance workloads |
| None | N/A | Maximum | Air-gapped / batch jobs |
| Custom Bridge | ✓ | Good | Multi-container apps (recommended) |

---

## Screenshots

| # | File | Description |
|---|------|-------------|
| 1 | `screenshots/hello_world.png` | `docker run hello-world` output |
| 2 | `screenshots/bridge_inspect.png` | `docker network inspect bridge` |
| 3 | `screenshots/host_nginx.png` | Nginx on host network — curl HTTP 200 |
| 4 | `screenshots/none_network.png` | Only loopback visible, ping fails |
| 5 | `screenshots/custom_bridge_ping.png` | DNS ping between container1 & container2 |

---

*Module 9 Assignment — Ostad DevOps Course*
