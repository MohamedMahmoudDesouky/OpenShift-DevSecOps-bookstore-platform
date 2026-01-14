# 📁 Scripts Directory – Bookstore DevSecOps Automation
This directory contains a set of Bash scripts to automate the build, scan, deploy, and validate workflow for the Bookstore application on Minikube, following DevSecOps best practices.

All scripts are non-blocking by design (unless explicitly failing on critical errors) to support iterative local development while still enforcing security and compliance checks.

## 📜 Scripts Overview
| Script                      | Purpose |
|----------------------------|--------|
| `check-prerequisites.sh`   | Validates required tools, versions, and Minikube context |
| `build-images.sh`          | Builds container images with Podman and loads them into Minikube |
| `scan-images.sh`           | Scans images for vulnerabilities, generates SBOMs, and checks for secrets |
| `run-local.sh`             | Deploys the app to Minikube using Kustomize and configures Ingress |
| `validate-security.sh`     | Verifies runtime security controls (e.g., NetworkPolicies) |
| `cleanup.sh`               | Deletes the `bookstore` namespace and stops Minikube |

## ▶️ Recommended Workflow
### 1. Verify your environment
./scripts/check-prerequisites.sh

### 2. Build container images (uses Podman)
./scripts/build-images.sh

### 3. Scan for vulnerabilities & secrets
./scripts/scan-images.sh

### 4. Deploy to Minikube
./scripts/run-local.sh

### 5. Validate security posture at runtime
./scripts/validate-security.sh

### 6. Clean up when done
./scripts/cleanup.sh

##### 💡 All scripts assume you're in the root of the project and that your Minikube cluster is configured with the minikube context.
---
## 🔒 Security & Compliance Features
- ✅ Non-root user enforcement in all containers
- ✅ Image size limit (backend ≤ 150MB)
- ✅ Trivy vulnerability scanning (blocks on HIGH/CRITICAL CVEs)
- ✅ SBOM generation (SPDX JSON format)
- ✅ Secret detection in source code
- ✅ Runtime validation of NetworkPolicies and pod isolation
---
## ⚙️ Requirements
#### Ensure the following tools are installed with minimum versions:

- Podman ≥ 4.0.0
- Trivy ≥ 0.45.0
- kubectl ≥ 1.27.0
- Minikube ≥ 1.32.0
- jq ≥ 1.6
- Git ≥ 2.30.0
###### Your kubectl context must be set to minikube.

###### Run ./scripts/check-prerequisites.sh to verify automatically.
---
## 🌐 Accessing the Application
After running ./scripts/run-local.sh:

1- Add this line to your /etc/hosts:-  
$(minikube ip) bookstore.local

2- Open in your browser:
→ http://bookstore.local

###### The script will print exact instructions during execution.
---
## 🧹 Cleanup
To fully reset your environment:
```bash
./scripts/cleanup.sh
```
This deletes the bookstore namespace and stops the Minikube VM.

###### Note: It does not delete built images or reports—those can be removed manually if needed.

