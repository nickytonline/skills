---
name: mergiraf-first
version: 1.0.0
description: Resolve Git merge, rebase, cherry-pick, or revert conflicts with Mergiraf as a deterministic first pass before using agent reasoning on remaining merge conflicts.
user-invocable: true
argument-hint: "[merge conflict or Git operation]"
---

# Mergiraf First

Use deterministic conflict resolution before spending agent context reasoning about a merge conflict.

## Workflow

1. Ensure Mergiraf is installed:

   ```bash
   command -v mergiraf >/dev/null 2>&1 || "${SKILL_DIR}/scripts/install-mergiraf.sh"
   ```

2. If you are **about to start** a merge, rebase, cherry-pick, or revert, check whether Mergiraf is already configured and applicable as Git's merge driver.

   Check the driver configuration:

   ```bash
   git config --get merge.mergiraf.driver
   ```

   For files involved in the operation, check the applicable merge attribute where practical:

   ```bash
   git check-attr merge -- <file>
   ```

   If Mergiraf is already active, run the Git operation normally. Git will give Mergiraf the deterministic first pass. Do not run `mergiraf solve` again on conflicts from that same operation just for the sake of running it.

3. If conflicts **already exist** and Mergiraf was not active for the operation, list unresolved files:

   ```bash
   git diff --name-only --diff-filter=U
   ```

   Run Mergiraf on each appropriate unresolved file:

   ```bash
   mergiraf solve <file>
   ```

4. Recheck unresolved paths:

   ```bash
   git diff --name-only --diff-filter=U
   ```

5. Review Mergiraf's resolutions. A syntactically valid merge is not necessarily semantically correct.

6. Use agent reasoning only for conflicts that remain. Understand the intent of both sides. Never blindly choose `ours`, `theirs`, or concatenate both versions.

7. Run the project's available validation before continuing the interrupted Git operation. Use relevant tests, type checking, linting, formatting, and/or builds.

## Guardrails

- Do not modify the user's Git configuration.
- Do not abort an in-progress Git operation unless the user asks or continuing safely is impossible.
- Do not commit unrelated changes.
- Do not push unless the surrounding user task requires it.
- Preserve compatible behavior from both sides of a conflict whenever possible.
