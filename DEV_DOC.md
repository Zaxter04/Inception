# Developer Documentation

This document describes how a developer can set up, build, launch and maintain the project.

## 1. Set up the environment from scratch

### Prerequisites

- A Linux host or virtual machine (Debian / Ubuntu recommended)
- Docker Engine (24+)
- Docker Compose v2 plugin
- GNU Make
- OpenSSL (for TLS certificates)
- `sudo` privileges (for `/etc/hosts` and data directories)

Install on Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin make openssl
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # then log out / log in
```

Verify:

```bash
docker --version
docker compose version
make --version
```

### Configuration files and secrets

1. Clone / copy the project.
2. Create the environment file (never commit real secrets):

   ```bash
   cp srcs/.env.example srcs/.env   # or generate it via the Makefile
   ```

   Typical variables:

   - `DOMAIN_NAME=<login>.42.fr`
   - `MYSQL_DATABASE`, `MYSQL_USER`, …
   - `WORDPRESS_ADMIN_USER`, `WORDPRESS_ADMIN_EMAIL`, …
   - `WORDPRESS_USER`, `WORDPRESS_USER_EMAIL`, …

3. Create the secrets directory (passwords only, one value per file):

   ```
   secrets/
   ├── mysql_root_password.txt
   ├── mysql_password.txt
   ├── wp_admin_password.txt
   └── wp_user_password.txt
   ```

   The Makefile usually generates random strong passwords automatically on the first `make`.

4. Domain resolution

   Add to `/etc/hosts` (on the machine that will resolve the domain):

   ```
   127.0.0.1  <login>.42.fr
   ```

### Data directories

Persistent data is stored on the host (or inside the VM) under a path defined in the Makefile / compose file, commonly:

- `/home/<user>/data/wordpress`
- `/home/<user>/data/mariadb`

These directories are created automatically by `make` with the correct ownership.

## 2. Build and launch the project

The recommended way is through the Makefile:

```bash
make          # equivalent to make up / make all
```

This will:

1. Create required data directories and secrets (if missing)
2. Generate a self-signed TLS certificate for the domain
3. Build the three custom Docker images from the Dockerfiles under `srcs/requirements/`
4. Start the stack with Docker Compose

Useful Makefile targets:

| Target     | Description                                      |
|------------|--------------------------------------------------|
| `make` / `make up` | Build + start                                    |
| `make build` | Build images only                                |
| `make stop`  | Stop running containers                          |
| `make down`  | Stop and remove containers & networks            |
| `make clean` | Remove containers, images, networks (keep volumes) |
| `make fclean`| Full reset including volumes / data              |
| `make re`    | `fclean` + `up`                                  |
| `make status`| Show container status                            |
| `make logs`  | Follow logs of all services                      |

Direct Docker Compose usage (from `srcs/` or with `-f`):

```bash
docker compose -f srcs/docker-compose.yml up -d --build
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f
```

## 3. Manage containers and volumes

- List running containers: `docker compose … ps` or `make status`
- Enter a container: `docker compose … exec <service> sh` (or `bash`)
- View logs of one service: `docker compose … logs -f <service>`
- Restart a single service: `docker compose … restart <service>`

Volumes:

- WordPress files (themes, plugins, uploads, `wp-content`) → named volume or bind-mount (usually under `/home/.../data/wordpress`)
- MariaDB data (`/var/lib/mysql`) → named volume or bind-mount (usually under `/home/.../data/mariadb`)

Because the volumes are bind-mounted to host directories, data survives:

- `docker compose down`
- container recreation
- image rebuilds

Only `make fclean` (or an explicit `docker volume rm` / removal of the host data directories) deletes the data.

## 4. Where project data is stored and how it persists

| Data                     | Location on host (typical)          | Inside container              | Persistence mechanism      |
|--------------------------|-------------------------------------|-------------------------------|----------------------------|
| WordPress site files     | `/home/<user>/data/wordpress`       | `/var/www/html`               | Bind mount / named volume  |
| MariaDB database files   | `/home/<user>/data/mariadb`         | `/var/lib/mysql`              | Bind mount / named volume  |
| TLS certificates         | `secrets/` or generated at build    | `/etc/nginx/ssl` (or similar) | File mount                 |
| Secrets (passwords)      | `secrets/*.txt`                     | `/run/secrets/...`            | Docker secrets (tmpfs)     |
| Configuration            | `srcs/.env` + conf files            | Injected at runtime           | Environment / files        |

Key points:

- The Docker network is private; only NGINX publishes port 443 to the host.
- MariaDB and WordPress communicate only over the internal Docker network (service names resolve to container IPs).
- On first start the entrypoint scripts of MariaDB and WordPress initialise the database and install WordPress using the values from `.env` and the secrets.
- Subsequent starts reuse the already-initialised data volumes, so content, users and settings remain intact.

## Quick verification checklist for developers

```bash
# 1. Status
make status

# 2. Logs
make logs

# 3. Reach the site
curl -k https://<login>.42.fr

# 4. Inspect volumes
docker volume ls
ls -la /home/<user>/data/

# 5. Enter MariaDB (example)
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p
```

For deeper debugging, architecture details, Docker best practices and evaluation tips, refer to the comments inside the Dockerfiles, the `docker-compose.yml` and the Makefile.
