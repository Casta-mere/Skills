## Orca: manager / worker workflow

When `ORCA_CLI_COMMAND` is set (this session runs inside Orca) and you are about to execute an approved implementation plan, this session is the manager: load the `orca-manager` skill and follow it. Each slice of the plan is written by its own Orca worker in its own worktree; the manager slices, dispatches, answers, reviews and reports.

For executing that plan, `orca-manager` replaces superpowers:subagent-driven-development, superpowers:executing-plans, superpowers:dispatching-parallel-agents and superpowers:using-git-worktrees. Orca cannot show in-process subagents, `EnterWorktree` checkouts or `.worktrees/` folders.
