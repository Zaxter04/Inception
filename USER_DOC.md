# User Documentation

This document explains, in clear and simple terms, how an end user or administrator can use and manage the stack.

## Services provided by the stack

The stack deploys a complete WordPress website accessible over HTTPS. It provides:

- A public WordPress website
- A WordPress administration panel (`/wp-admin`)
- User authentication and role-based permissions
- Content creation (posts, pages)
- Media upload and management
- Persistent storage of all website and database data

### Components

| Service     | Role                                      |
|-------------|-------------------------------------------|
| **NGINX**   | HTTPS reverse proxy and entry point (port 443) |
| **WordPress + PHP-FPM** | Application layer that runs the CMS |
| **MariaDB** | Database that stores users, posts, settings and media metadata |

All user data survives container restarts and rebuilds (as long as volumes are not deleted).

## Start and stop the project

From the root of the repository:

| Action                          | Command          |
|---------------------------------|------------------|
| Build images and start everything | `make` or `make up` |
| Stop containers (keep data)     | `make stop`      |
| Stop and remove containers/networks (keep volumes) | `make down` |
| Full clean (remove containers, images, networks; keep volumes) | `make clean` |
| Complete reset (also remove volumes / data) | `make fclean` |

After `make` / `make up` finishes, the website is ready.

## Access the website and the administration panel

- **Website**: `https://<your-login>.42.fr`  
  (or the domain defined in your `.env` / Makefile)

- **Administration panel**: `https://<your-login>.42.fr/wp-admin`

If the project runs inside a virtual machine, you may need an SSH tunnel or SOCKS proxy from the host (see `DEV_DOC.md`). Accept the self-signed certificate warning the first time you connect.

## Locate and manage credentials

Credentials are never hard-coded in source files.

- Non-secret configuration (domain, database name, usernames, emails) lives in `srcs/.env`.
- Passwords are stored as Docker secrets (files under a `secrets/` directory) and are mounted at runtime inside the containers at `/run/secrets/`.

Typical files:

- WordPress administrator username → defined in `.env` (`WORDPRESS_ADMIN_USER` or equivalent)
- WordPress administrator password → secret file (e.g. `wp_admin_password`)
- Regular WordPress user → defined in `.env` + corresponding secret
- MariaDB root / application user passwords → corresponding secret files

To change a password after the first run you must update the secret (or `.env`) and re-initialise the data (`make fclean && make`), because WordPress and MariaDB only read the credentials on first initialisation.

Inside the WordPress admin panel you can:

1. Log in with the administrator account
2. Go to **Users → All Users**
3. Create, edit or change roles of any user

## Check that the services are running correctly

1. **Containers status**
   ```bash
   make status
   # or
   docker compose -f srcs/docker-compose.yml ps
   ```
   All services should be `Up` (and preferably `healthy` if health-checks are defined).

2. **Website accessibility**
   - Open `https://<your-login>.42.fr` in a browser
   - The site must load over HTTPS

3. **Administrator login**
   - Open `https://<your-login>.42.fr/wp-admin`
   - Log in with the administrator credentials
   - You should reach the WordPress dashboard

4. **Content creation test**
   - From the dashboard create a new post, publish it
   - Verify it appears on the public site

5. **Persistence test** (optional)
   - Create content
   - Run `make down && make up`
   - Confirm the content is still present

If any of the above fails, check the container logs:

```bash
docker compose -f srcs/docker-compose.yml logs
```
