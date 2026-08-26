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