---
name: orca-manager
description: Use when running inside Orca (ORCA_CLI_COMMAND is set) and an approved implementation plan is about to be executed, or when the user wants each part of the work in its own worktree or session they can watch in Orca
---

# Orca manager

## Overview

You are the manager. Every slice of the approved plan gets its own sibling worktree, made the repo's own way, and a supervised Orca worker: a Claude chat the user can watch in Orca. You slice, dispatch, answer, review and report. You write no slice code and commit nothing in your own checkout. A one-slice plan still gets one worker.

## 1. Slice the plan

Each slice owns disjoint files, has a branch `feat/<TICKET>-<slug>` (or `fix/`) and one acceptance check. A slice that depends on another starts after that one's `worker_done`.

## 2. Make a worktree per slice

Look for the repo's own worktree command: `ls .claude/commands .claude/skills .agent/commands 2>/dev/null | grep -i worktree`

| Found | Do |
|---|---|
| Yes (hrm-service: `/git-worktree`) | Follow it with the branch you chose (`--branch feat/...`). The approved plan is consent for its confirmation questions; answer them yourself. |
| No | `git fetch origin main && git worktree add --no-track -b <branch> ../<repo>-<slug> origin/main` |

Run long installs and builds for all slices in the background. Start a slice's worker only after its setup exits 0.

## 3. Show it in Orca

```bash
orca worktree show --worktree path:<dir>
# selector_not_found means the repo hides external worktrees; once per repo:
orca repo set --repo path:<main checkout> --external-worktree-visibility show
orca worktree set --worktree path:<dir> --parent-worktree path:<main checkout> --workspace-status in-progress
```

## 4. Start the workers

Read Orca's version-matched guide once: `orca skills get orchestration`. Then start every independent slice before waiting:

```bash
orca orchestration run-create --objective "<TICKET> <plan title>" --json
orca orchestration worker-start --run <run_id> --worktree path:<dir> --agent claude \
  --task-title "<slice>" --spec "<spec>" --json
```

The spec is all the worker knows. Write it as:
- **Target:** worktree path and branch
- **Change:** the slice copied from the plan, plus the plan's absolute path (plans are untracked, so the worktree lacks them)
- **Constraints:** files it must not touch; repo rules that apply
- **Acceptance:** commands that must pass; commit on its branch with `[<TICKET>]` in the message; push or open a PR only if the plan says so

## 5. Supervise

```bash
orca orchestration check --run <run_id> --wait --types "worker_done,escalation,question" --timeout-ms 540000 --json
```

- The output can hold several JSON documents: read it with grep, not a single JSON parse.
- `question`: `orca orchestration reply --id <msg_id> --body "<answer>" --json`. Ask the user first when it is their decision.
- `worker_done`: check its `dispatchId` is one of yours, review `git -C <dir> diff origin/main...HEAD`, re-run its acceptance check, then `orca orchestration worker-release --dispatch <id> --json`.
- Then `check --run <run_id> --ack <deliveryId> --wait ...` again. Heartbeats only prove the worker is alive.
- A mid-turn message "You have N orchestration message(s). Run `orca orchestration check ...`" is Orca's nudge: run the check.
- Done when every slice has an outcome and `orca orchestration worker-list --run <run_id> --terminal-state reclaimable --json` reports none.

## 6. Report and clean up

Per slice: outcome, evidence, branch or PR, blockers. Remove a worktree after its branch is merged, or when the user says so: `orca worktree rm --worktree path:<dir>`. It deletes the folder, and the branch when merged, in the background.

## Why not the usual tools

| Thought | Reality |
|---|---|
| "The slices are small, subagents are enough" | In-process subagents are invisible in Orca and share one checkout. Size doesn't change the route. |
| "A new session won't have the plan" | The spec carries the slice and the plan's absolute path. |
| "I'd have to poll to know when it's done" | `check --wait` delivers `worker_done`. |
| "I don't know the orca CLI" | The commands above were tested end to end. |
| superpowers:using-git-worktrees, `EnterWorktree`, `.worktrees/` | Skips the repo's setup (secrets, dependencies), Orca hides it, and it moves you instead of starting a worker. |
| `orca worktree create`, `worker-start --worktree new-child` | Skips the repo's own worktree command, so no secrets or dependencies. |
