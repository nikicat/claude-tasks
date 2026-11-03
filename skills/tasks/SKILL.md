---
name: tasks
description: Track tasks as plain Markdown files in each repo's `.tasks/`. One file per open task, deleted when done, with git history as the archive. Cross-repo deps via `repo#id`, and an overview by scanning ~/src. Promotes ad-hoc work to a tracked task when it outgrows the session. Use when the user wants to add, list, start, block, or finish a task, asks "what's open/next", wants to plan their day/week across projects, wants task tracking set up in a repo, references a task id like 0007 or billing#0012, or when working in a repo that has `.tasks/`.
---

# Tasks as files in git

No tool, no database. Open tasks live in `.tasks/` at the repo root; a closed
task is a deleted file, and git history keeps it. Every repo has its own
tasks, and the overview comes from scanning `~/src`.

**Only repos that already have `.tasks/` are tracked.** Never create
`.tasks/` unless the user asks to set up tracking. The directory is `.tasks/`,
not `tasks/`, because plain `tasks/` is already a code directory in many repos
(Hardhat, Celery, …).

## Layout

```
~/src/acme/api/.tasks/
  README.md                    # quick reference for humans (from README.template.md)
  0007-fix-login-timeout.md
  0008-add-export.md
```

Task files are `NNNN-short-slug.md`, a 4-digit id plus a kebab-case slug.
Always glob `.tasks/[0-9]*.md` so the README is skipped. There is no `done/`
directory.

```markdown
---
status: todo                              # todo | doing | blocked
deps: [0005, billing#0012]   # optional
due: 2026-11-07                           # optional
tags: [backend]                           # optional
---
# Fix login timeout

## Goal
Why this matters and what "done" means.
## Decisions
- Chose X over Y because …
## Ruled out
- Tried Z: fails because … (so nobody tries it again)
## State
Where the work stands: branch, what's working, what isn't.
## Next
The concrete next step.
```

Keep the front matter to those keys. Add another one only when the user asks
for it. Sections are optional: a fresh task may be just a title and a Goal.
The body is a snapshot of the current state, not a log. Rewrite State and
Next; don't append diary entries. Git history keeps the old versions.

## Lifecycle within a session

At session start, a hook lists the repo's open tasks. If the user's request
matches one of them, that's the current task: set it to `doing` if it isn't
already.

**Promote ad-hoc work.** Every request starts untracked: don't create a task
for "commit this" or "fix that". Propose a task when a signal appears:

1. **It won't finish now:** the user is wrapping up, or the context was
   compacted, with the work still open.
2. **Something is deferred:** "later", "out of scope", "separate PR", or a
   follow-up noticed while working. Each becomes its own task, not a TODO
   comment in the code.
3. **The scope grew:** a second commit is needed, an approach failed or had
   to change, or the "quick fix" became an investigation.
4. **It came back:** this topic was left unfinished by an earlier session.
5. **The user says so:** "track this", "make a task".

Proposing is one line plus a draft: *"Promote to
`.tasks/0012-fix-retry-loop.md`? (goal / found so far / next step)"*. On
yes, write the file and fill the sections from what the session already
knows. For 2 and 5, just create it, since the user has effectively already
said yes.

**Update the current task at checkpoints**, without asking: before a commit,
when a decision is made or an approach is ruled out, and when the user is
wrapping up. Rewrite State and Next so that a fresh session could resume from
the file alone. The user reviews these edits in `git diff` like any other
change.

**Close** by deleting the file along with the change that resolves it (see
Done).

**Migrate on next touch.** If the repo has `.tasks/` and also a
`STATUS.md`, `PLAN.md`, `TODO.md` or similar, propose once per session to turn
its open items into tasks and delete the converted parts. Don't do it without
asking.

## Shared repos

Repos are shared with teammates, so every task has an owner: the author of
the commit that added the file.

```sh
git log --diff-filter=A --format='%an <%ae>' -- '.tasks/0007-*' | tail -1
```

You may update or close the user's own tasks (git `user.email`) freely. For a
task someone else created, ask the user before changing anything except
appending to Decisions or Ruled out. A task that isn't committed yet belongs
to the user.

## Referring to tasks

- In the same repo: `0007`.
- In another repo: `<repo>#0007`, where `<repo>` is the repo path relative to
  `~/src`. Repos can be nested, e.g. `lazyagent#0003` or
  `billing#0012`.
- A repo with no tasks of its own (life admin, cross-cutting work) goes in
  `~/src/tasks/`, which is a plain repo following the same convention. Its ref
  is `tasks#0001`.

**Dependency state.** For `<repo>#NNNN`:

1. `~/src/<repo>/.tasks/NNNN-*.md` exists → **open**.
2. Otherwise, if `git -C ~/src/<repo> log --diff-filter=D --format=%h -- '.tasks/NNNN-*'`
   prints a commit → **done**.
3. Otherwise (repo not cloned, or the id never existed) → **unknown**. Report
   it. Don't treat it as done.

A `blocked` task whose deps are all done is **ready**: say so, and offer to
set it back to `todo`.

## Operations (in one repo)

**New.** The next id is one more than the highest id that ever existed, which
includes deleted tasks, so ids are never reused:

```sh
{ ls .tasks; git log --all --format= --name-only -- .tasks/; } 2>/dev/null \
  | grep -o '^\(\.tasks/\)\?[0-9]\{4\}' | grep -o '[0-9]\{4\}' | sort -n | tail -1
```

No output means start at `0001`. Create the file with `status: todo`.

**List.** `grep -H '^status:' .tasks/[0-9]*.md`. Show id, status and title.

**Start / block.** Edit the `status:` line. For `blocked`, write the reason
in the body, and in `deps` when it is another task.

**Done.** Delete the file (`rm .tasks/0007-*.md`) along with the change that
resolves it, so the same commit closes the task and ships the fix. Put the id
in the commit message (`… (closes 0007)`). The user's git rules still apply:
staging and committing need their approval. Then check whether this unblocks
anything elsewhere: `grep -l '<repo>#0007' ~/src/{*,*/*,*/*/*}/.tasks/[0-9]*.md`.

**Closed tasks / history:**

- list closed tasks: `git log --diff-filter=D --format='%h %ad %s' --date=short --name-only -- .tasks/`
- read a closed task: `git show <commit>^:.tasks/0007-fix-login-timeout.md`
- find work by id: `git log --grep 0007` plus `git log -- '.tasks/0007-*'`
- search all task text ever written: `git log -S '<text>' -- .tasks/`
- the Claude sessions that touched a task: the `Claude-Session:` trailers in
  `git log -- '.tasks/0007-*'`. Don't record session ids in the task file.

## Overview and planning (all repos)

Repos sit at depth 1 to 3 under `~/src`. This scan finds every open task:

```sh
grep -H -e '^status:' -e '^due:' -e '^deps:' -e '^# ' ~/src/{*,*/*,*/*/*}/.tasks/[0-9]*.md 2>/dev/null
```

When the user asks "what's open", or to plan their day or week, group the
results by repo and then rank them:

1. `doing`, since it is already in flight.
2. Overdue, or due within the planning window.
3. Just unblocked (`blocked`, with all deps done).
4. `todo`. Prefer tasks that other tasks depend on, because finishing them
   unblocks the most.
5. `blocked`, listed with what each one waits on.

Propose an order that fits the window and ask the user to adjust it. The plan
isn't stored anywhere: it is derived from the files each time.

**Progress over a period**, per repo with a `.tasks/` (either now or in the
past):

```sh
for r in ~/src/{*,*/*,*/*/*}/; do [ -d "$r/.git" ] || continue
  n=$(git -C "$r" log --since='1 week ago' --diff-filter=D --format= --name-only -- '.tasks/[0-9]*' 2>/dev/null | grep -c .)
  [ "$n" -gt 0 ] && echo "${r#$HOME/src/} $n"; done
```

## Setup in a new repo

Only when the user asks for it: `mkdir .tasks`, then copy `README.template.md`
from this skill's directory to `.tasks/README.md`, then create the first task.
Don't add an index, a template task, or a script.
