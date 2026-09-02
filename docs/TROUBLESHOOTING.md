## Git operations failing inside a OneDrive-synced folder (2026-08-26)

**Symptom:** `git checkout main` repeatedly failed with
`Deletion of directory '.github' failed. Should I try again? (y/n)`, looping
indefinitely even after answering `y`. Separately, `git checkout main && git
pull` failed with `fatal: Unable to create '.../.git/index.lock': File
exists.` — a stale lock left behind by the interrupted checkout attempt.

**What didn't fix it:**
- Deleting the stale `.git/index.lock` manually — the lock came back
  immediately on the next operation.
- Closing and reopening VS Code — ruled out its Git extension/file watchers
  as the sole cause.
- Pausing OneDrive sync via the system tray — ruled out active syncing as
  the sole cause.
- Running the same commands from a plain Command Prompt outside VS Code —
  ruled out VS Code's integrated terminal specifically.

**Root cause:** the local clone lived inside a OneDrive-synced folder
(`OneDrive\Documents\work\...`). OneDrive's "Files On-Demand" virtualization
layer stays active at the filesystem level even while sync is paused, and
interferes with Git's rapid directory delete/recreate operations during a
checkout. Repeated failed/interrupted attempts eventually left the local
repo in a genuinely inconsistent state (stuck mid-merge on the wrong branch,
with files showing as simultaneously staged-new and unstaged-deleted).

**Fix:** stopped trying to repair the broken local clone in place — nothing
was at risk, since the actual work was already safely merged into `main` on
GitHub via the PR. Did a fresh `git clone` into a plain local folder outside
OneDrive (`C:\dev\azure-devops-build`) and moved active work there instead.
Confirmed clean via the Explorer tree: correct file locations, no stray
duplicates, no merge-in-progress state.

**Takeaway:** cloud-sync folders (OneDrive, Dropbox, Google Drive) and local
Git repositories don't mix well — the sync client's virtualization/locking
behavior conflicts with Git's own file operations, especially on `.git`
internals and directories with rapid churn. Moving forward, all local repo
work happens under `C:\dev\`, not inside a synced folder. Worth remembering
before phase 02, since Terraform generates much heavier local file churn
(`.terraform/`, state files) that would hit this same friction constantly.

## AKS cluster creation — three deploy-time errors on first attempt

**Symptom:** `terraform apply` on the AKS module failed three times in a
row with different errors before succeeding.

**Errors and fixes, in order:**

1. `The VM size of Standard_B2s is not allowed in your subscription in
   location 'switzerlandnorth'` — Azure restricts which VM sizes are
   available per subscription/region combination; the classic `B2s`
   wasn't on the list, but the newer `Standard_B2s_v2` was. Fixed by
   switching the VM size.

2. `ServiceCidrOverlapExistingSubnetsCidr` — Azure CNI requires an
   explicit Kubernetes Service CIDR that does not overlap the VNet's own
   address space, even though service addresses are virtual. The
   provider default (10.0.0.0/16) collided with our VNet (also
   10.0.0.0/16). Fixed by explicitly setting `service_cidr =
   "10.100.0.0/16"` and `dns_service_ip = "10.100.0.10"`.

3. `ErrCode_InsufficientVCPUQuota` for `standardBsv2Family` — the
   subscription had a 0-vCPU quota limit for the entire Bsv2 burstable
   family in this region (confirmed via `az vm list-usage --location
   switzerlandnorth`), separate from the SKU-availability issue in step
   1. Fixed by switching both node pools to `Standard_D2s_v4`, a size
   both allowed in the region and in a VM family with real quota
   headroom (10 vCPUs total regional limit; the cluster uses 4).

**Lesson:** `az vm list-usage --location <region>` is the fastest way to
see actual, real quota per VM family before guessing at a size — worth
running early on any new subscription/region rather than iterating
through apply failures.

## Azure AD RBAC setup for AKS — four issues along the way

**Symptom:** Adding AAD RBAC to the AKS module and getting `kubectl`
working against it took several iterations.

**Errors and fixes, in order:**

1. `An argument named "managed" is not expected here.` — the `managed`
   argument was removed from the `azurerm` provider in v4.x once Azure
   retired the legacy AAD integration mode. Fixed by removing the line.

2. `one of admin_group_object_ids,tenant_id must be specified` — the
   provider requires an explicit `tenant_id` (deliberately not using an
   AAD admin group, to keep access per-identity). Fixed by adding a
   `data "azurerm_client_config" "current"` source and setting
   `tenant_id = data.azurerm_client_config.current.tenant_id`.

3. `kubelogin is not installed` — `az aks install-cli` had been run in a
   terminal (VS Code's integrated terminal) whose PATH didn't pick up the
   newly-installed binary. Fixed by rerunning it from a fresh, standalone
   terminal window and confirming with `where.exe kubelogin`.

4. Perpetual `upgrade_settings` diff on `terraform plan` — AKS applies
   default `upgrade_settings` (`max_surge = "10%"`) to node pools on
   creation even when never declared in config, causing Terraform to
   show the same phantom diff on every future plan. Fixed by explicitly
   declaring `upgrade_settings { max_surge = "10%" }` on both node pool
   definitions.

**Lesson:** A clean `terraform apply` only proves the config was
accepted — it doesn't prove access actually works. After enabling AAD
RBAC, the real verification is running `kubectl` and seeing a genuine
403 before any role assignment exists, then success after.