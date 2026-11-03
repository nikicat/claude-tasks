# Tasks

Open tasks for this repo, one Markdown file each. A closed task is a deleted
file, and git history is the archive. There is no tool or database: edit the
files by hand, or let Claude Code do it with the
[tasks plugin](https://github.com/nikicat/claude-tasks).

## File

`NNNN-short-slug.md`. The id is never reused: take the highest id ever used,
including deleted tasks, plus one.

```markdown
---
status: todo                 # todo | doing | blocked
deps: [0005, other-repo#0012]  # optional; other-repo = path under ~/src
due: 2026-11-07              # optional
tags: [backend]              # optional
---
# Title

## Goal
## Decisions
## Ruled out
## State
## Next
```

Only the title is required; use the sections as the task grows.

## Workflow

- **Start / block:** edit `status:`. Write blockers in `deps` or in the body.
- **Done:** delete the file in the commit that resolves it, with `(closes NNNN)`
  in the message.
- **Someone else's task:** ask the author before you close or rewrite it.

## History

```sh
git log --diff-filter=D --name-only -- .tasks/   # closed tasks
git show <commit>^:.tasks/NNNN-slug.md           # read a closed task
git log -- '.tasks/NNNN-*'                       # everything that touched it
```
