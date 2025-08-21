# Pizzaria App – Zero-Touch Auto-Deploy (Docker + Cron)

This repository contains a small **frontend + backend** app and a **self-updating deploy script**.
It installs Docker, pulls the latest code from GitHub, rebuilds the images, and runs the stack
with Docker Compose. A cron job executes every 5 minutes to keep the server in sync with the repo.

> Target OS: **Ubuntu/Debian** (for other distros, adapt the package installation commands).

---

## What’s inside

- `backend/` — Python app (Dockerfile exposes port `5000`, started via `python app.py`).
- `frontend/` — Nginx serving static files, with `/api` reverse-proxy to `backend:5000`.
- `docker-compose.yml` — Builds `backend` and `frontend`; publishes frontend as the public service.
- `.env.example` — Configure the public port (`APP_PORT`, default `8080`).
- `deploy.sh` — Idempotent installer & deployer:
  - Installs **git**, **docker.io**, and **docker-compose**
  - Clones or updates this repo (fast-forward to remote)
  - Rebuilds images (`docker compose build --pull --no-cache`)
  - Brings the stack up (`docker compose up -d --remove-orphans`)
  - Installs a **cron** entry to run every 5 minutes

---

## Quick start (server)

1) **Prepare directory**
```bash
sudo mkdir -p /opt/pizzaria-app
sudo chown -R "$USER":"$USER" /opt/pizzaria-app
cd /opt/pizzaria-app