# 🐳 Podman Build Documentation

This directory contains instructions and context for building the Bookstore application container images using **Podman** — adhering to DevSecOps best practices for security, minimalism, and OpenShift 4.18 compatibility.

✅ All images are built with Podman (rootless-compatible), scanned with Trivy, and validated before deployment.

## 📦 Built Images

The following images are constructed from source in their respective directories:

| Image                | Source Path     | Purpose                                      |
|----------------------|-----------------|----------------------------------------------|
| `bookstore-frontend` | `../frontend/`  | Nginx-based static frontend (port 8080)      |
| `bookstore-backend`  | `../backend/`   | Node.js API server (port 3000)               |
| `bookstore-mysql`    | `../database/`  | MySQL 8.0 database with init script          |

## 🔒 Security & Hardening Implemented

### Frontend (`frontend/Dockerfile`)
- Uses `nginxinc/nginx-unprivileged:1.26-alpine` (non-root base)
- Runs as UID `101` (compliant with OpenShift Restricted SCC)
- Applies pinned CVE-fixed versions of vulnerable packages:
  - `libpng=1.6.53-r0`
  - `libxml2=2.12.10-r0`
- Multi-stage build to isolate build artifacts
- Final image has **no shell**, **no package manager**, and **read-only filesystem readiness**

### Backend (`backend/Dockerfile`)
- Multi-stage build: dependencies installed in build stage only
- **`npm` and `npx` completely removed** from runtime image
- Runs as non-root user **UID `1001`**
- Uses `node:20-alpine` (LTS, minimal)
- `.dockerignore` prevents leakage of secrets, logs, and dev files

### Database (`database/Dockerfile`)
- Based on official `mysql:8.0`
- Initialization via `/docker-entrypoint-initdb.d/init.sql`
- No custom modifications that weaken security

## ▶️ How to Build with Podman

From the **repository root**, run:

```bash
# Build Frontend
podman build -t bookstore-frontend:1.0 -f frontend/Dockerfile frontend

# Build Backend
podman build -t bookstore-backend:1.0 -f backend/Dockerfile backend

# Build Database
podman build -t bookstore-mysql:1.0 -f database/Dockerfile database


💡 Note: These commands work without root privileges if your user is configured for rootless Podman (default on modern systems).

🔍 Validation Steps (Pre-Deployment)
Before deploying to OpenShift, validate each image:

1. Check Running User
podman run --rm bookstore-frontend:1.0 id
# Should return: uid=101(nginx) gid=101(nginx)
podman run --rm bookstore-backend:1.0 id
# Should return: uid=1001 gid=0(root)

2. Scan for Vulnerabilities
trivy image --severity HIGH,CRITICAL bookstore-frontend:1.0
trivy image --severity HIGH,CRITICAL bookstore-backend:1.0
trivy image --severity HIGH,CRITICAL bookstore-mysql:1.0

✅ Success: No output = no critical/high CVEs.

3. Verify Image Size (Optimization)
podman images | grep bookstore
Frontend: ~25–30 MB
Backend: ~120–140 MB (due to Node.js runtime)
MySQL: ~500 MB (expected for DB)
Frontend: ~25–30 MB
Backend: ~120–140 MB (due to Node.js runtime)
MySQL: ~500 MB (expected for DB)
