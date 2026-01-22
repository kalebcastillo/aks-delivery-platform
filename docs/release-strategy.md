# TECHNICAL PROJECT PLAN
## AKS Application Delivery Platform

## 1. Project Scope & Constraints

### Objective
Build and operate a Kubernetes-based application delivery platform on Azure Kubernetes Service (AKS), focusing on infrastructure provisioning, deployment safety, automation, observability, and cost control.

### Constraints
- Single Kubernetes cluster (dev-focused)
- Single application
- One deployment strategy (blue-green or canary)
- GitOps-based delivery
- Finishable within ~3 weeks
- Minimal long-running cloud cost

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Cloud Provider | Azure |
| Kubernetes | AKS |
| IaC | Terraform |
| Container Registry | Azure Container Registry |
| CI | GitHub Actions |
| CD / GitOps | Argo CD |
| Observability | Prometheus + Grafana |
| Application | FastAPI (simple HTTP service) |
| Automation | Bash + Python |

## 3. Repository Structure

```
aks-app-delivery-platform/
├── terraform/
│   ├── modules/
│   └── environments/
├── app/
├── k8s/
│   ├── base/
│   └── overlays/
├── automation/
│   └── python/
├── scripts/
│   └── bash/
├── docs/
└── .github/workflows/
```

## 4. Phase 1 — Infrastructure Provisioning (AKS)

### Objective
Provision all required Azure infrastructure using Terraform.

### Tasks
- Create resource group(s)
- Provision virtual network and subnets
- Deploy AKS cluster with managed node pool(s)
- Create Azure Container Registry
- Configure Terraform remote state
- Output cluster connection details

### Requirements
- No manual Azure Portal configuration beyond initial auth
- Infrastructure must be fully destroyable and reproducible

### Deliverables
- Terraform modules for AKS, networking, and ACR
- Environment-specific configuration (dev)
- Verified cluster access via kubectl

### Signals this sends
- Infrastructure-as-Code discipline
- Comfort with cloud-native Kubernetes provisioning

## 5. Phase 2 — Application Containerization

### Objective
Prepare a simple, containerized application suitable for Kubernetes delivery testing.

### Application Characteristics
- HTTP-based FastAPI service
- /health endpoint
- Configurable via environment variables
- Deterministic behavior (no external dependencies)

### Tasks
- Define Dockerfile
- Build container image locally
- Push image to ACR
- Validate container startup and health behavior

### Deliverables
- Versioned container image
- Application runnable locally and in cluster

### Signals this sends
- Understanding of container lifecycle
- Focus on operability, not app complexity

## 6. Phase 3 — Kubernetes Deployment (GitOps Model)

### Objective
Deploy the application to AKS using declarative Kubernetes manifests managed via GitOps.

### Tasks
- Define Kubernetes namespace(s)
- Create base manifests that support blue/green Deployments and Service-based traffic switching:
  - Deployment or Rollout
  - Service
  - ConfigMaps / Secrets
- Configure resource requests and limits
- Configure liveness and readiness probes
- Install and configure Argo CD
- Register application repository with Argo CD

### Constraints
- No imperative deployments from CI
- Git is the source of truth for cluster state

### Deliverables
- Application deployed via Argo CD
- Successful sync and reconciliation
- Drift detection verified

### Signals this sends
- GitOps fluency
- Declarative Kubernetes mindset

## 7. Phase 4 — Application Delivery Strategy (Blue/Green)

### Objective
Implement a production-style blue/green deployment strategy that allows validation of a new version before promotion, with explicit traffic switching and fast rollback.

### Strategy Selection
- **Blue/Green deployment**
- **Manual promotion**
- Single cluster, GitOps-driven

### Core Design
- Two Kubernetes Deployments:
  - **Blue Deployment**: current active version serving production traffic
  - **Green Deployment**: new version deployed for validation
- Two Kubernetes Services:
  - **Active Service**: routes live traffic to either blue or green via label selector
  - **Preview Service**: always routes traffic to green for validation and smoke testing

### Where the Logic Lives
- Deployment behavior (blue vs green): Kubernetes manifests
- Traffic switching: Kubernetes Service selector
- Promotion and rollback: Git changes reconciled by Argo CD
- Validation gates: scripts and human decision-making

### Promotion Flow
1. CI builds a new container image
2. Git is updated to deploy the image to the **green Deployment**
3. Argo CD deploys green alongside blue
4. Smoke tests are run against the **preview Service**
5. Manual Git change updates the **active Service selector** from blue → green
6. Argo CD reconciles the change and switches live traffic
7. *(Optional)* Blue Deployment is scaled down after promotion

### Rollback Flow
- Manual Git change switches the active Service selector back to blue
- Argo CD reconciles the change immediately
- No redeploy or rebuild required

### Capacity Behavior
- Blue and green may run concurrently during promotion
- Pod resource requests are sized so:
  - blue fits within the initial node pool
  - adding green temporarily creates scheduling pressure
- Cluster autoscaler adds nodes as needed
- Capacity changes are observable via node count before and after promotion

### Deliverables
- Working blue/green deployment
- Manual promotion and rollback validated
- Preview-based validation without impacting live traffic

### Signals this sends
- Understanding of real-world release safety patterns
- Clear separation of deployment, validation, and promotion
- Practical GitOps-based promotion model


## 8. Phase 5 — CI Pipeline (Build & Promote)

### Objective
Automate image build and promotion while preserving GitOps boundaries.

### Pipeline Responsibilities
- Build container images
- Run basic validation checks
- Push images to ACR
- Update deployment references in Git
- Trigger Argo CD reconciliation

### Constraints
- CI must not apply manifests directly to cluster
- Deployment occurs via GitOps only

### Deliverables
- Functional GitHub Actions pipeline
- Versioned images and deployments

### Signals this sends
- CI/CD separation of concerns
- Modern delivery pipeline design

## 9. Phase 6 — Observability Stack

### Objective
Implement basic but meaningful observability for cluster and application.

### Tasks
- Install Prometheus stack
- Configure metrics scraping
- Deploy Grafana
- Create dashboards:
  - Cluster health
  - Application performance
- Configure minimal alerting

### Deliverables
- Prometheus collecting metrics
- Grafana dashboards populated with live data

### Signals this sends
- Operational awareness
- Ability to reason about system health post-deploy

## 11. Bash Automation (Operational Guardrails)

### Purpose
Use Bash to implement fast, lightweight guardrails that validate environment readiness, deployment safety, and capture cluster state using existing CLI tools.

### Scripts & Usage

**Environment Bootstrap**  
Purpose: Verify required tooling, cloud authentication, and Kubernetes context are correctly configured on the local machine.  
When used: After cloning the repository, switching machines, or before performing any infrastructure or deployment actions.

**Pre-Deployment Validation**  
Purpose: Confirm the target cluster and namespace are in a healthy, stable state before triggering a deployment or rollout.  
When used: Immediately before merging or promoting changes that cause a deployment.

**Operational Snapshot**  
Purpose: Capture a point-in-time snapshot of cluster, application, and rollout state for debugging or verification.  
When used: Before and after deployments, or during failures or degraded states.

**Teardown Helper (Optional)**  
Purpose: Safely coordinate application shutdown and infrastructure destruction while preventing accidental deletions.  
When used: When intentionally tearing down the environment for cost control or reset.

### Deliverables
- Small, focused Bash scripts
- Scripts rely on standard CLIs (kubectl, az, terraform)
- Clear documentation of intent and usage

### Signals this sends
- Practical shell scripting proficiency
- Awareness of operational safety and guardrails


## 12. Python Automation (Operational Tooling)

### Purpose
Use Python to automate a single operational task that requires structured logic or API interaction beyond what is practical in Bash.

### Script Scope
Implement one Python script that interacts with Azure or Kubernetes APIs.

Examples (choose one):
- Cluster health audit
- Deployment or rollout helper
- Azure cost reporting utility

### Script Definition
Purpose: Programmatically collect, evaluate, or act on operational data from cloud or Kubernetes APIs.  
When used: Run on demand when deeper validation, reporting, or orchestration is required.

### Requirements
- Uses official Azure or Kubernetes SDKs
- CLI-driven
- Focused on operational value

### Deliverables
- One Python script with a single responsibility
- Brief documentation describing purpose and usage

### Signals this sends
- Ability to build internal DevOps tooling
- Clear distinction between Bash and Python use cases


## 12. Phase 9 — Documentation

### Objective
Document the system clearly for reuse and demonstration.

### Documentation Requirements
- Architecture overview
- Deployment flow
- Delivery strategy explanation
- Rollback procedure
- Cost control approach
- Known limitations

### Deliverables
- README
- Architecture diagram
- Supporting docs

### Signals this sends
- Professional engineering habits
- Ability to communicate technical systems clearly

## 13. Execution Timeline

| Week | Focus |
|---|---|
| Week 1 | Terraform + AKS + App |
| Week 2 | GitOps + Delivery Strategy + CI |
| Week 3 | Observability + Bash + Python + Docs |

## 14. Completion Criteria

The project is complete when:
- Infrastructure is reproducible and destroyable
- Application deploys via GitOps
- Deployment strategy works and rolls back cleanly
- Metrics and dashboards are functional
- Bash and Python automation are demonstrated
- Documentation reflects actual system behavior
