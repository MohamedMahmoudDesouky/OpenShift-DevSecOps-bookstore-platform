# Professional CI Pipeline (SonarCloud + Trivy + Smoke + CIS)

This repository uses a production-grade GitHub Actions CI pipeline designed for DevSecOps workflows.
The pipeline integrates code quality analysis, container security scanning, manual approval gates, and Kubernetes CIS benchmarks.

The workflow is triggered on pushes and pull requests and is suitable for enterprise environments.

---
## Pipeline Overview

The CI pipeline performs the following high-level stages:

- Manual approval gate for production

- Static code analysis with SonarCloud

- Docker image build and vulnerability scanning with Trivy

- Kubernetes CIS benchmark validation using kube-bench

- Artifact generation for security and compliance reports

 ## Workflow Triggers

- The pipeline runs automatically on:

- Push events to main and test branches

- Pull requests targeting the main branch

## Environment Configuration

Global environment variables:

- Docker registry: docker.io

##### Secrets required:

- SONAR_TOKEN

- DOCKERHUB_USERNAME

- DOCKERHUB_TOKEN

- GITHUB_TOKEN (provided by GitHub Actions)

## Jobs Description
1. Approval Gate (Production Protection)

This job enforces manual approval before production execution.

###### Triggered when:

- A pull request targets main

- A direct push is made to main

- Uses GitHub Environments with required reviewers

- Ensures controlled production deployments

## 2. SonarCloud Code Quality Scan

This job performs static analysis and quality checks.

Key actions:

- Full repository checkout with Git history

- Python 3.11 setup

- Optional dependency installation

- SonarCloud scan execution

- Fetches metrics via SonarCloud API:

- Vulnerabilities

- Code smells

- Test coverage

- Security rating

- Generates a sonar-report.json file

- Uploads the report as a workflow artifact

## 3. Build and Scan Docker Images

This job builds and scans Docker images for multiple services using a matrix strategy.

Services included:

- Backend service

- Frontend service

Steps performed per service:

- Docker Buildx setup

- Docker Hub authentication

- Image metadata extraction

- Docker image build

- Trivy vulnerability scan (non-blocking)

- Push image to Docker Hub using commit SHA tag

This enables:

- Parallel builds

- Consistent tagging

- Early vulnerability detection

## 4. Kubernetes CIS Benchmark (kube-bench)

This job validates Kubernetes cluster security against CIS benchmarks.

Actions performed:

- Install kubectl and Minikube

- Start a local Kubernetes cluster

- Run kube-bench using Docker

- Generate reports in:

- JSON format

- Human-readable text format

- Upload CIS benchmark reports as artifacts

This ensures compliance with Kubernetes security best practices.

## Optional / Disabled Jobs

The following jobs are included but commented out for future use:

#### Smoke Tests

- Deploys application to Minikube

Verifies:

- MySQL

- Redis

- Backend health endpoint

- Uses Kubernetes manifests

- Performs HTTP health checks

## Argo CD Continuous Deployment

- Updates Kubernetes manifests with new image tags

- Commits changes back to the repository

- Enables GitOps-based CD workflow

## Artifacts Generated

The pipeline uploads the following artifacts:

SonarCloud analysis report

Kubernetes CIS benchmark reports

These artifacts can be downloaded from the GitHub Actions workflow run.

## Security & DevSecOps Highlights

Manual production approval

Static code analysis

Container image vulnerability scanning

Kubernetes CIS compliance checks

Immutable image tagging

GitOps-ready design

## Intended Use Cases

Enterprise CI/CD pipelines

DevSecOps projects

Kubernetes-based microservices

Security-focused cloud-native platforms


