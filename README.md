# claude-tasks

Task tracking for git repos as plain Markdown files, with a
[Claude Code](https://claude.com/claude-code) plugin that keeps the files up to
date while you work. There is no database and no service.

- Each repo keeps its open tasks in `.tasks/xxxxx-slug.md`, one file per task.
- **Done = deleted** in the commit that resolves the task. Git history is the
  archive.
- Cross-repo dependencies are written `other-repo#Tm3xaj` (same owner) or
  `owner/repo#Tm3xaj`, resolved to whichever local clone has that remote.
- Only repos that contain `.tasks/` are touched.

The file format and the manual workflow are in
[`skills/tasks/README.template.md`](skills/tasks/README.template.md), which is
copied into each repo as `.tasks/README.md`.

## What the plugin does

- **Session start, resume, after compaction:** a hook lists the repo's open
  tasks, so Claude knows the context without being told.
- **During work:** Claude proposes promoting ad-hoc work to a task when it
  outgrows the session (unfinished, deferred, scope grew, recurring). It
  keeps the current task's *Decisions / Ruled out / State / Next* up to date
  at checkpoints.
- **Closing:** the task file is deleted in the fix commit.
- **Planning:** "plan my week" scans every repo under `~/src` and ranks the
  open tasks by status, due date and dependencies.

## Install

```sh
claude plugin marketplace add nikicat/claude-tasks
claude plugin install tasks@nikicat-tasks
```

To start tracking a repo, ask Claude to "set up tasks here", or run
`mkdir .tasks` yourself and copy the README template into it.

Requires `jq` and `git`.

## License

MIT
