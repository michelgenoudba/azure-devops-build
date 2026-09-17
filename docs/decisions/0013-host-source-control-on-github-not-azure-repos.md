# 13. Host source control on GitHub, not Azure Repos

## Status
Accepted (retroactive — documents a decision already in effect since project start)

## Context
Azure DevOps offers a fully native option for this project: Azure Repos for git hosting, Azure Boards for work item tracking, and Azure Pipelines for CI/CD, all inside one product with no cross-platform integration required. This project instead hosts its source on GitHub (`github.com/michelgenoudba/azure-devops-build`) while still using Azure Boards for work items and Azure Pipelines for CI/CD, bridged via the Azure Pipelines GitHub App. That split has been in place from the first commit but was never formally written down, so this ADR captures the reasoning after the fact.

The two realistic options were:

1. **Fully unified on Azure DevOps** — Azure Repos + Azure Boards + Azure Pipelines, no external integration needed.
2. **Split: GitHub for source, Azure DevOps for Boards + Pipelines** — the option actually in use, requiring the GitHub App bridge and the `AB#<id>` convention in commit messages to link commits back to Azure Boards work items.

A third option, fully unified on GitHub (GitHub Actions instead of Azure Pipelines, GitHub Projects instead of Azure Boards), was also considered and rejected — see Alternatives Considered.

## Decision
Host source control on GitHub. Keep Azure Boards for work item tracking and Azure Pipelines for CI/CD, connected to the GitHub repository through the Azure Pipelines GitHub App, which posts pipeline results back as GitHub commit statuses and PR checks. Commit messages reference Azure Boards work items with `AB#<id>` to preserve traceability across the two platforms.

## Rationale

**Portfolio visibility.** This is an AZ-400 study project intended to be shown to others (recruiters, reviewers, teammates). A public GitHub repository is trivially shareable with a plain URL; Azure Repos is typically locked behind an Azure DevOps organization and its own access model, which is a much higher-friction ask of anyone reviewing the work.

**Native security tooling.** GitHub's Dependabot and CodeQL are first-party features of the platform with no separate licensing or configuration surface beyond the repository's own settings. Setting these up during Phase 06 was a same-day, no-extra-tooling exercise specifically because the repo already lived on GitHub. Achieving equivalent automated dependency and code scanning on Azure Repos would mean either Azure Pipelines' own scanning tasks or a separate third-party integration — more moving parts for the same outcome.

**Broader familiarity and ecosystem.** GitHub's PR review UI, branch protection rules, and general workflow are the default reference point for most engineers outside a Microsoft-centric shop, which matters both for collaboration and for demonstrating transferable skills rather than tooling specific to one vendor.

**Deliberately keeping Azure Boards and Azure Pipelines in the loop.** The project's whole purpose is AZ-400 exam preparation, and Azure Boards/Azure Pipelines are directly examined services. Moving fully to GitHub (Actions + Projects) would remove hands-on practice with exactly the tools the exam covers, so the split — rather than a full move to GitHub — was the right compromise.

## Alternatives Considered

**Fully unified on Azure DevOps (Azure Repos + Boards + Pipelines).** Rejected. This removes all cross-platform friction and the need for the GitHub App bridge or the `AB#` convention, and it's plausibly what an enterprise Azure DevOps shop would actually run day to day. But it forfeits the portfolio-shareability and native Dependabot/CodeQL benefits described above, and this project weighs those higher given its purpose is partly a public-facing demonstration of skills, not just internal delivery.

**Fully unified on GitHub (GitHub Actions + GitHub Projects, no Azure DevOps).** Rejected. This would be the more natural pairing with GitHub-hosted source (no bridge, no dual-tool linking convention), and GitHub Actions is a fine CI/CD engine in its own right. But AZ-400 is specifically an Azure Boards/Azure Pipelines exam — building this project entirely on GitHub Actions and Projects would mean skipping hands-on practice with the actual services being studied, which defeats the project's purpose.

## Consequences

**Positive:**
- Free, first-party dependency and code scanning (Dependabot, CodeQL) with zero additional setup cost.
- The repository is easy to share and review outside an Azure DevOps organization.
- Direct hands-on practice with both ecosystems' review/PR conventions.

**Negative — real friction encountered during this project:**
- A pipeline's own `trigger:`/`pr:` YAML doesn't automatically govern GitHub branch protection's view of "required checks" — this required deliberate configuration and was the root cause of two separate incidents this project (`terraform-apply` and `ci-build`'s `CanaryProd`/`PromoteProd` stages both ran on pull requests when they should only have run after merge to `main`, because Azure Pipelines defaults to building PRs from any branch when no `pr:` block is declared).
- The two platforms' "which PR/pipeline is this?" mental model doesn't always align cleanly — early in this project there was genuine confusion about whether the PR and its checks lived in Azure Repos or GitHub, since a first-time viewer of the Azure DevOps project sees an empty Azure Repos repo unless they know to look at the GitHub Pipelines integration instead.
- Traceability between a commit and its Azure Boards work item depends entirely on the human discipline of including `AB#<id>` in every commit message — nothing enforces this automatically the way a single-platform setup might.

On balance, this friction is itself judged to be worthwhile exam-relevant experience: many real organizations run exactly this kind of hybrid setup (source on GitHub, work tracking and pipelines on Azure DevOps), and understanding its rough edges firsthand — rather than avoiding them by picking the frictionless unified option — is directly useful preparation.