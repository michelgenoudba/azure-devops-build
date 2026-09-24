# AZ-400 Domain Mapping

How the work in this repository maps to the [skills measured for Exam AZ-400](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-400).
Weightings and sub-skills below are Microsoft's published list as of mid-2026 — check the official study guide
again closer to exam day, since blueprints do shift.

Legend: ✅ practiced hands-on in this project · ⚠️ partially touched · ❌ not covered — a real gap, study from theory.

## 1. Design and implement processes and communications (10–15%)

| Skill | Status | Notes |
|---|---|---|
| Traceability / flow of work | ✅ | Azure Boards work items linked to every commit/PR — automatic `AB#<id>`, manual Hyperlink where needed (Phase 08) |
| Feedback cycles, notifications, GitHub Issues | ❌ | Not used — this project didn't route feedback through Issues or notification rules |
| Integration for tracking work (Boards + GitHub) | ✅ | [ADR 0013](decisions/0013-host-source-control-on-github-not-azure-repos.md) — GitHub for code, Boards for work tracking, wired together |
| Dashboards: cycle time, time to recovery, lead time | ⚠️ | Only deployment frequency was built ([evidence](evidence/08-dora-dashboard.png)) — lead time and MTTR dashboards not attempted |
| Metrics/queries: planning, dev, testing, security, delivery, operations | ⚠️ | Delivery metric done; the other five categories weren't turned into dashboards, even though the underlying data (scan results, alert history) exists |
| Wikis, process diagrams, Markdown/Mermaid | ✅ | This README's architecture diagram |
| Release documentation, release notes, API docs | ❌ | Not automated or written |
| Automate documentation from Git history | ❌ | Not attempted |
| Webhooks | ❌ | Not configured |
| Boards ↔ GitHub integration | ✅ | Same as above — ADR 0013 plus the Phase 08 linking work |
| GitHub/Azure DevOps ↔ Teams integration | ❌ | Not covered |

## 2. Design and implement a source control strategy (10–15%)

| Skill | Status | Notes |
|---|---|---|
| Branching strategy (trunk-based, feature, release) | ✅ | [ADR 0002](decisions/0002-trunk-based-branching.md) — trunk-based, short-lived branches |
| PR workflow, branch policies/protection | ✅ | Protected `main`, PR-gated merges throughout |
| Large file management (Git LFS, git-fat) | ❌ | Not needed at this repo's scale, not practiced |
| Repo scaling (Scalar, cross-repo sharing) | ❌ | Not applicable at this scale, not practiced |
| Repository permissions | ⚠️ | Used implicitly (GitHub repo access) but never deliberately designed/documented |
| Tags | ❌ | No git tagging or release-tagging strategy used |
| Recover/remove data from source control | ❌ | Deliberately avoided — this project's own rule is to never rewrite pushed history |

## 3. Design and implement build and release pipelines (50–55%)

This is over half the exam, and where this project has both its deepest coverage and its biggest gaps.

| Skill | Status | Notes |
|---|---|---|
| Package management strategy (GitHub Packages, Azure Artifacts, SemVer/CalVer) | ❌ | Container images go to ACR but with no deliberate versioning strategy — a real gap |
| Pipeline artifact versioning | ⚠️ | Terraform plan artifacts are passed between stages, but not versioned as a strategy |
| Quality/release gates | ✅ | Trivy scan, HTML validation, Lighthouse CI thresholds all gate the pipeline |
| Testing strategy: unit, integration, load tests | ❌ | This project is infra-heavy with a static site — no app-level test suite exists |
| Code coverage analysis | ❌ | Not applicable — no test suite to cover |
| Deployment automation tool selection (GitHub Actions vs Azure Pipelines) | ✅ | Deliberately chose Azure Pipelines with GitHub as source ([ADR 0013](decisions/0013-host-source-control-on-github-not-azure-repos.md)) |
| Runner/agent infrastructure | ✅ | Self-hosted agent VM in the private VNet, Terraform-provisioned |
| GitHub ↔ Azure Pipelines integration | ✅ | Whole project is built this way |
| Pipeline trigger rules | ✅ | Path filters, branch triggers across `ci-build`, `terraform-scan-gate`, `terraform-apply` |
| YAML pipelines | ✅ | Every pipeline in this repo is YAML-native |
| Job execution order, parallelism, multi-stage pipelines | ✅ | `ci-build`'s Build → DeployStaging → CanaryProd → PromoteProd flow |
| Complex pipeline scenarios (hybrid, VM templates, self-hosted agents) | ⚠️ | Self-hosted agent yes; hybrid/VM template scenarios not explored |
| Reusable pipeline elements (YAML templates, task groups, variable groups) | ❌ | Every pipeline is a standalone file — no template reuse was built, a real gap given how much the exam weights this |
| Checks and approvals via YAML environments | ✅ | `environment: infra` approval gate on Terraform apply, staging→prod approval gate |
| Deployment strategy: blue-green, canary, ring, progressive exposure | ⚠️ | Canary done and evidenced ([ADR 0010](decisions/0010-canary-deployment-for-prod.md)); blue-green, ring, progressive exposure not attempted |
| Feature flags, A/B testing | ❌ | Not covered — no Azure App Configuration Feature Manager usage |
| Dependency deployment ordering | ⚠️ | Handled implicitly via Terraform module dependencies, not deliberately designed as a pipeline concern |
| Minimizing downtime (load balancing, rolling deployment, slots) | ⚠️ | Canary approach reduces blast radius but deployment slots/rolling strategy specifics weren't explored |
| Hotfix path | ❌ | Not documented |
| Resiliency strategy for deployment | ⚠️ | Approval gates act as a safety net, but no formal rollback/resiliency plan exists |
| Container/binary/script deployment | ✅ | Docker + Helm to AKS |
| Database deployment tasks | ❌ | N/A — no database in this project, but worth studying since the exam covers it |
| IaC strategy, source control, test/deploy automation | ✅ | Terraform throughout, PR-time plan gate, approval-gated apply |
| Desired state config (Bicep, Azure Automation State Config, Machine Config) | ❌ | This project uses Terraform exclusively — Bicep and native Azure config-management tools weren't touched, worth reviewing since the exam names them explicitly |
| Azure Deployment Environments (self-service) | ❌ | Not covered |
| Monitor pipeline health (failure rate, duration, flaky tests) | ⚠️ | Lived through plenty of real failures this project, but never built a formal pipeline-health dashboard |
| Optimize pipeline cost/time/performance/reliability | ⚠️ | Practiced cost hygiene (stopping AKS/VM between sessions) but no systematic pipeline optimization exercise |
| Pipeline concurrency optimization | ❌ | Not covered |
| Artifact/dependency retention strategy | ❌ | Not covered |
| Classic-to-YAML pipeline migration | ❌ | N/A — this project started YAML-native |

## 4. Develop a security and compliance plan (10–15%)

| Skill | Status | Notes |
|---|---|---|
| Entra service principals vs. managed identities | ✅ | Workload identity federation used for AKS → Key Vault access |
| GitHub auth (Apps, GITHUB_TOKEN, PATs) | ⚠️ | Used a PAT for the Power BI Analytics connection (Phase 08); GitHub Apps not explored |
| Azure DevOps service connections and PATs | ✅ | OIDC-based service connection used from the very first pipeline |
| GitHub permissions and roles | ❌ | Not deliberately designed |
| Azure DevOps permissions and security groups | ❌ | Not deliberately designed |
| Access levels (stakeholder, outside collaborator) | ❌ | Not explored — single-user project |
| Projects/teams configuration in Azure DevOps | ⚠️ | Single project, single team — not exercised at scale |
| Secrets/keys/certificates via Key Vault | ✅ | Key Vault module, network ACLs hardened, workload identity access |
| Secretless auth (workload identity federation / OIDC) | ✅ | Core theme throughout — pipelines and AKS both use OIDC/workload identity over static secrets |
| Managing sensitive files during deployment (secure files) | ❌ | Not covered — `.gitignore` keeps secrets out, but Azure Pipelines' secure files feature wasn't used |
| Preventing leakage of sensitive information | ✅ | `.gitignore` for `*.pem`/`*.tfvars`, enforced as a standing project rule |
| Security/compliance scanning strategy | ✅ | Trivy (dependency, container, IaC), Dependabot |
| Microsoft Defender for Cloud DevOps Security | ✅ | Configured in Phase 06 |
| GitHub Advanced Security (GHAS) | ❌ | Not set up — a real gap, since the exam covers this explicitly for both GitHub and Azure DevOps |
| Defender + GHAS integration | ❌ | Not covered — depends on GHAS above |
| Container scanning, CodeQL | ⚠️ | Trivy covers container scanning; CodeQL was not configured |
| Dependabot alerts | ✅ | Enabled and evidenced in Phase 06 |

## 5. Implement an instrumentation strategy (5–10%)

| Skill | Status | Notes |
|---|---|---|
| Azure Monitor + Log Analytics integration | ✅ | Central to Phase 07 |
| Application Insights telemetry | ✅ | JS SDK instrumentation on the static site |
| VM Insights, Storage/Network monitoring | ❌ | Not covered — only Container Insights and App Insights were used |
| Container Insights | ✅ | Wired to the Log Analytics workspace at AKS creation |
| Monitoring/insights in GitHub | ❌ | Not covered — monitoring lives entirely on the Azure side of this project |
| Alerts for GitHub Actions / Azure Pipelines events | ❌ | The 5 alerts built are app/infra alerts, not pipeline-execution alerts — a distinction worth knowing for the exam |
| Infra performance indicators (CPU, memory, disk, network) | ✅ | Resource-pressure alert, thresholds set relative to Kubernetes limits ([ADR 0014](decisions/0014-limit-relative-thresholds-for-monitoring-alerts.md)) |
| Analyze metrics: usage and app performance | ✅ | Latency and HTTP error rate alerts |
| Distributed tracing via Application Insights | ⚠️ | Basic JS SDK telemetry only — this is a single static site, so true distributed tracing across services wasn't exercised |
| KQL queries | ✅ | All 5 scheduled query alerts are hand-written KQL |

## Where to focus remaining study time

The project is strongest in IaC, pipeline mechanics, canary deployment, security scanning, and monitoring/KQL —
domains 3, 4, and 5 where real hands-on work happened. The clearest gaps, roughly in order of exam weight:

- **Package management and pipeline artifact versioning** (domain 3) — never designed a SemVer/CalVer strategy or used GitHub Packages/Azure Artifacts feeds.
- **Reusable pipeline elements** (domain 3) — every pipeline here is a standalone YAML file; templates, task groups, and variable groups were never practiced.
- **Application-level testing and code coverage** (domain 3) — this project has no unit/integration/load test suite to exercise.
- **GitHub Advanced Security / CodeQL** (domain 4) — Defender for Cloud DevOps Security was configured, but GHAS itself wasn't.
- **Bicep and native Azure config-management tools** (domain 3) — this project is Terraform-only; the exam names Bicep and Azure Automation State Configuration explicitly.
- **Feature flags, blue-green/ring deployments, database deployment tasks** (domain 3) — deployment strategy was explored via canary only.
- **DevOps-specific dashboards beyond deployment frequency** (domain 1) — lead time, MTTR, and testing/security/operations metrics weren't built as dashboards, even though most of the underlying data already exists in this project.

Sources:
- [Study guide for Exam AZ-400](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-400)
- [Exam AZ-400 certification page](https://learn.microsoft.com/en-us/credentials/certifications/exams/az-400/)