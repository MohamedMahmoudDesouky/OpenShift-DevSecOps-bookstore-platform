## Project Overview

An **advanced difficulty** enterprise-grade 4-tier web application for managing a bookstore inventory. This project implements **DevSecOps best practices** including container security scanning, multi-stage builds, and production-ready configurations for **OpenShift 4.18**.


## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              DevSecOps Pipeline                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│   │   Source    │───▶│    Build    │───▶│   Trivy     │───▶│   Deploy    │         │
│   │    Code     │    │   Images    │    │    Scan     │    │  OpenShift  │         │
│   └─────────────┘    └─────────────┘    └──────┬──────┘    └─────────────┘         │
│                                                 │                                    │
│                                          ┌──────▼──────┐                            │
│                                          │  Security   │                            │
│                                          │   Report    │                            │
│                                          └─────────────┘                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              OpenShift 4.18 Cluster                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│   │   Frontend   │───▶│   Backend    │───▶│    Redis     │───▶│   Database   │     │
│   │   (Nginx)    │    │  (Node.js)   │    │   (Cache)    │    │   (MySQL)    │     │
│   │   Port: 8080 │    │  Port: 3000  │    │  Port: 6379  │    │  Port: 3306  │     │
│   └──────┬───────┘    └──────┬───────┘    └──────────────┘    └──────┬───────┘     │
│          │                   │                                        │              │
│          ▼                   ▼                                        ▼              │
│   ┌──────────────┐    ┌──────────────┐                        ┌──────────────┐     │
│   │    Route     │    │   Ingress    │                        │     PVC      │     │
│   │   (TLS)      │    │  Controller  │                        │   (10Gi)     │     │
│   └──────────────┘    └──────────────┘                        └──────────────┘     │
│                                                                                      │
│   ┌──────────────────────────────────────────────────────────────────────────┐     │
│   │                        Security & Observability                           │     │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐          │     │
│   │  │   Trivy    │  │  Network   │  │  Pod Sec   │  │  Resource  │          │     │
│   │  │  Scanner   │  │  Policies  │  │  Standards │  │   Quotas   │          │     │
│   │  └────────────┘  └────────────┘  └────────────┘  └────────────┘          │     │
│   └──────────────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Technology Stack

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Frontend** | Nginx + Alpine | 1.24 | Static file serving, reverse proxy |
| **Backend** | Node.js + Express | 18 LTS | REST API, business logic |
| **Cache** | Redis | 7.0 | Session storage, query caching |
| **Database** | MySQL | 8.0 | Persistent data storage |
| **Security** | Trivy | Latest | Container vulnerability scanning |
| **Container** | Podman | 4.x | OCI-compliant container runtime |
| **Orchestration** | OpenShift | 4.18 | Enterprise Kubernetes platform |

## Core Requirements (Mandatory)

### 1. Application Requirements

| Requirement | Description | Validation |
|-------------|-------------|------------|
| **CRUD Operations** | Full Create, Read, Update, Delete for books | All API endpoints working |
| **Data Validation** | Input validation on all fields (ISBN format, price range) | Invalid data rejected with proper errors |
| **Error Handling** | Graceful error handling with proper HTTP status codes | No 500 errors for invalid input |
| **API Documentation** | OpenAPI/Swagger documentation | Accessible at `/api/docs` |
| **Logging** | Structured JSON logging with correlation IDs | Logs searchable and traceable |

### 2. Container Requirements

| Requirement | Description | Validation |
|-------------|-------------|------------|
| **Multi-stage Builds** | Separate build and runtime stages | Image size < 150MB for backend |
| **Non-root User** | All containers run as non-root (UID > 1000) | `USER` directive in Dockerfile |
| **Read-only Filesystem** | Containers use read-only root filesystem where possible | `readOnlyRootFilesystem: true` |
| **No Latest Tags** | All images use specific version tags | No `:latest` tags allowed |
| **Minimal Base Images** | Use Alpine or distroless base images | No full OS images (Ubuntu, CentOS) |

### 3. Security Requirements (Trivy)

| Requirement | Description | Validation |
|-------------|-------------|------------|
| **Zero Critical CVEs** | No critical vulnerabilities in images | Trivy scan passes |
| **Zero High CVEs** | No high vulnerabilities (or documented exceptions) | Trivy scan with `--severity HIGH,CRITICAL` |
| **SBOM Generation** | Software Bill of Materials for each image | SBOM file generated |
| **Secret Scanning** | No hardcoded secrets in images | Trivy secret scan passes |
| **IaC Scanning** | Kubernetes manifests scanned for misconfigurations | Trivy config scan passes |

### 4. OpenShift Requirements

| Requirement | Description | Validation |
|-------------|-------------|------------|
| **Resource Limits** | CPU and memory limits on all pods | No unbounded resources |
| **Health Probes** | Liveness, readiness, and startup probes | All probes configured |
| **Pod Disruption Budget** | PDB for high availability | PDB applied for backend |
| **Horizontal Pod Autoscaler** | Auto-scaling based on CPU/memory | HPA configured |
| **Network Policies** | Restrict pod-to-pod communication | Only allowed traffic permitted |
| **Pod Security Standards** | Restricted security context | Passes `restricted` PSS |


## Prerequisites

### Required Tools

```bash
# Check all prerequisites
./scripts/check-prerequisites.sh
```

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| Podman | 4.0+ | Container runtime |
| Trivy | 0.45+ | Security scanning |
| OpenShift CLI (`oc`) | 4.14+ | Cluster management |
| Git | 2.30+ | Version control |
| jq | 1.6+ | JSON processing |

### Required Knowledge

- [ ] Container fundamentals (Dockerfile, multi-stage builds)
- [ ] Kubernetes concepts (Deployments, Services, ConfigMaps, Secrets)
- [ ] OpenShift specifics (Routes, SecurityContextConstraints)
- [ ] Security best practices (CVE remediation, least privilege)
- [ ] Networking (Network Policies, TLS termination)

## Project Structure

```
bookstore-project/
├── README.md                       # This file
├── SECURITY.md                     # Security policy and CVE handling
├── frontend/
│   ├── Dockerfile                  # Multi-stage build
│   ├── Dockerfile.dev              # Development image
│   ├── nginx.conf                  # Hardened nginx configuration
│   ├── security-headers.conf       # Security headers
│   └── html/
│       ├── index.html
│       ├── style.css
│       └── app.js
├── backend/
│   ├── Dockerfile                  # Multi-stage build
│   ├── Dockerfile.dev              # Development image
│   ├── package.json
│   ├── package-lock.json           # Locked dependencies
│   ├── server.js
│   ├── .dockerignore
│   └── .trivyignore                # CVE exceptions (documented)
├── database/
│   ├── Dockerfile
│   └── init.sql
├── openshift/
│   ├── base/                       # Base configurations
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── pvc.yaml
│   │   ├── mysql-deployment.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   └── route.yaml
│   ├── overlays/
│   │   ├── dev/                    # Development environment
│   │   │   └── kustomization.yaml
│   │   └── prod/                   # Production environment
│   │       └── kustomization.yaml
│   ├── security/
│   │   ├── network-policies.yaml   # Network isolation
│   │   ├── pod-security.yaml       # Pod security standards
│   │   └── resource-quotas.yaml    # Resource limits
│   └── autoscaling/
│       ├── hpa.yaml                # Horizontal Pod Autoscaler
│       └── pdb.yaml                # Pod Disruption Budget
├── scripts/
│   ├── check-prerequisites.sh      # Validate environment
│   ├── build-images.sh             # Build all images
│   ├── scan-images.sh              # Trivy security scan
│   ├── run-local.sh                # Local development
│   ├── deploy-openshift.sh         # Production deployment
│   ├── validate-security.sh        # Security validation
│   └── cleanup.sh                  # Cleanup resources
├── security/
│   ├── trivy-config.yaml           # Trivy configuration
│   ├── .trivyignore                # Global CVE exceptions
│   └── reports/                    # Scan reports (gitignored)
└── docs/
    ├── API.md                      # API documentation
    ├── DEPLOYMENT.md               # Deployment guide
    └── SECURITY.md                 # Security documentation
```

## Quick Start

### Phase 1: Build and Scan

```bash
# 1. Check prerequisites
./scripts/check-prerequisites.sh

# 2. Build all images
./scripts/build-images.sh

# 3. Security scan (MANDATORY - must pass before deployment)
./scripts/scan-images.sh

# 4. Review security report
cat security/reports/scan-summary.txt
```

### Phase 2: Local Development

```bash
# Run locally with Podman
./scripts/run-local.sh

# Test application
curl http://localhost:8080
curl http://localhost:3000/api/health
curl http://localhost:3000/api/books
```

### Phase 3: Deploy to OpenShift

```bash
# Login to OpenShift
oc login <cluster-url>

# Validate security before deployment
./scripts/validate-security.sh

# Deploy application
./scripts/deploy-openshift.sh

# Verify deployment
oc get pods -l app=bookstore
oc get route bookstore -o jsonpath='{.spec.host}'
```


**Total Possible: 130 points** (60 core + 70 bonus)

## API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/health` | Liveness check | None |
| GET | `/api/ready` | Readiness check (includes DB/Redis) | None |
| GET | `/api/books` | Get all books (paginated) | None |
| GET | `/api/books/:id` | Get book by ID | None |
| POST | `/api/books` | Add new book | API Key |
| PUT | `/api/books/:id` | Update book | API Key |
| DELETE | `/api/books/:id` | Delete book | API Key |
| GET | `/api/metrics` | Prometheus metrics | None |

## Security Scanning with Trivy

### Running Security Scans

```bash
# Full security scan
./scripts/scan-images.sh

# Scan specific image
trivy image --severity HIGH,CRITICAL bookstore-backend:latest

# Generate SBOM
trivy image --format spdx-json -o sbom.json bookstore-backend:latest

# Scan Kubernetes manifests
trivy config openshift/

# Scan for secrets
trivy fs --scanners secret .
```


```bash
# Check security context
oc get pod <pod-name> -o yaml | grep -A 20 securityContext

# Verify network policies
oc get networkpolicy -l app=bookstore

# Check for CVEs
trivy image <image-name> --severity HIGH,CRITICAL
```

### Application Issues

```bash
# Check all pods
oc get pods -l app=bookstore -o wide

# View logs with correlation
oc logs deployment/backend | jq 'select(.correlationId == "xxx")'

# Test internal connectivity
oc exec deployment/backend -- nc -zv mysql 3306
oc exec deployment/backend -- nc -zv redis 6379
```

### Performance Issues

```bash
# Check HPA status
oc get hpa bookstore-backend

# View resource usage
oc top pods -l app=bookstore

# Check Redis cache hit rate
oc exec deployment/redis -- redis-cli INFO stats | grep hits
```

