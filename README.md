*This project has been created as part of the 42 curriculum by zasoulai.*

# Inception

## Description

**Inception** is a System Administration project from the 42 curriculum.  
Its goal is to broaden knowledge of Docker by setting up a small, complete web infrastructure composed of multiple services, each running in its own container, all orchestrated with Docker Compose inside a virtual machine.

The mandatory stack consists of:

- **NGINX** – the only public entry point, configured with TLSv1.2 / TLSv1.3 only (port 443)
- **WordPress + php-fpm** – application layer (no nginx inside the container)
- **MariaDB** – database server (no nginx inside the container)

Two Docker volumes persist data:
- one for the WordPress database
- one for the WordPress website files

All containers communicate through a dedicated user-defined Docker network and are configured to restart automatically on failure.

The project requires writing custom Dockerfiles based on the penultimate stable version of Alpine or Debian (no pre-built official images for the services themselves) and managing the entire stack via a Makefile and a `docker-compose.yml` file.

## Project description

### Use of Docker and sources included in the project

The entire infrastructure is built and run with **Docker** and **Docker Compose**.  
All images are created from scratch using custom Dockerfiles located under `srcs/requirements/`.  
Configuration files, entrypoint scripts, and certificates are also versioned in the repository.  
Sensitive data (passwords, database credentials, domain name, etc.) is never hard-coded; it is supplied through an `.env` file (which must never be committed) and, when required, Docker secrets.

Main design choices:
- One service = one container (strict separation of concerns)
- Custom Dockerfiles only (no `FROM nginx`, `FROM wordpress`, `FROM mariadb`, etc.)
- Named volumes backed by bind mounts under `/home/zasoulai/data` so data survives container recreation and is visible on the host
- User-defined bridge network for inter-container communication
- Automatic restart policy (`restart: always` or `unless-stopped`)
- TLS termination exclusively on NGINX; internal traffic stays unencrypted inside the private network

### Virtual Machines vs Docker

| Aspect              | Virtual Machines                          | Docker Containers                     |
|---------------------|-------------------------------------------|---------------------------------------|
| Isolation level     | Full hardware virtualization (hypervisor) | Process + filesystem isolation (namespaces + cgroups) |
| Resource overhead   | High (full guest OS)                      | Very low (shares host kernel)         |
| Startup time        | Minutes                                   | Seconds                               |
| Portability         | Heavy disk images                         | Lightweight images                    |
| Use case in project | The whole project runs **inside** a VM for isolation and reproducibility | Services themselves are containerized |

Docker was chosen because it offers fast, lightweight, reproducible service isolation while still satisfying the school’s requirement that the whole environment lives inside a virtual machine.

### Secrets vs Environment Variables

| Approach            | Pros                                      | Cons                                  | Usage in project                     |
|---------------------|-------------------------------------------|---------------------------------------|--------------------------------------|
| Environment variables (`.env`) | Simple, widely supported by Compose      | Visible in `docker inspect`, process list, logs | Domain name, non-critical config, database names |
| Docker Secrets      | Encrypted at rest (Swarm), never written to image layers, mounted as files | Requires Swarm mode or extra tooling | Passwords and highly sensitive credentials when the subject allows/requires it |

In this project environment variables are used for most configuration; secrets are preferred for passwords whenever the evaluation criteria demand stricter handling.

### Docker Network vs Host Network

| Mode                | Description                               | Why it was / was not used            |
|---------------------|-------------------------------------------|--------------------------------------|
| Host network        | Container shares the host’s network stack | **Forbidden** by the subject (`network: host` is prohibited) |
| User-defined bridge | Isolated virtual network managed by Docker | **Used**. Containers talk to each other by service name; only NGINX publishes port 443 to the outside |

A custom bridge network guarantees isolation, DNS resolution by service name, and compliance with the subject rules (no `--link`, no host networking).

### Docker Volumes vs Bind Mounts

| Type                | Description                               | Usage in project                     |
|---------------------|-------------------------------------------|--------------------------------------|
| Named Docker volume | Managed by Docker, stored under `/var/lib/docker/volumes` | Declared in `docker-compose.yml` so volumes appear in `docker volume ls` |
| Bind mount          | Direct mapping of a host directory into the container | Backing store for the named volumes, located under `/home/zasoulai/data` so data is easy to inspect and backup on the host |

The combination satisfies both the subject requirement (volumes must exist) and practical needs (data lives in a predictable host path).

## Instructions

### Prerequisites
- A Linux virtual machine (Debian or Ubuntu recommended)
- Docker Engine and Docker Compose plugin installed
- GNU Make
- Your 42 zasoulai configured in the Makefile / `.env`

### Installation

```bash
git clone <repository-url> inception
cd inception
```