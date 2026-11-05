---
name: tasks
description: Track tasks as plain Markdown files in each repo's `.tasks/`. One file per open task, deleted when done, with git history as the archive. Cross-repo deps via `repo#Tid`, and an overview by scanning ~/src. Promotes ad-hoc work to a tracked task when it outgrows the session. Use when the user wants to add, list, start, block, or finish a task, asks "what's open/next", wants to plan their day/week across projects, wants task tracking set up in a repo, references a task id like T7kq2x, api#Tm3xaj or owner/repo#Tm3xaj, or when working in a repo that has `.tasks/`.
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
  7kq2x-fix-login-timeout.md
  p2fen-add-export.md
```

Task files are `xxxxx-short-slug.md`, a 5-character random id plus a
kebab-case slug. Ids are random so that tasks created in parallel on
different branches never need coordinating (see New). Older repos may have
4-digit ids like `0007`; keep them, don't rename. Always glob
`.tasks/*-*.md` so the README is skipped. There is no `done/`
directory.

```markdown
---
status: todo                              # todo | doing | blocked
deps: [Tc9wdr, billing#Tm3xaj]              # optional
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
`.tasks/m3xaj-fix-retry-loop.md`? (goal / found so far / next step)"*. On
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
git log --diff-filter=A --format='%an <%ae>' -- '.tasks/7kq2x-*' | tail -1
```

You may update or close the user's own tasks (git `user.email`) freely. For a
task someone else created, ask the user before changing anything except
appending to Decisions or Ruled out. A task that isn't committed yet belongs
to the user.

## Referring to tasks

References name repos by their git remote, not by local path, because each
teammate's clone layout is different. The forms look like GitHub's, but the
id always carries a `T` prefix: GitHub autolinks `#12` and `owner/repo#12` to
PRs and issues, and never autolinks `#T12`. File names stay `7kq2x-slug.md`.
In commit messages, write `(task T7kq2x)`, never `closes`/`fixes` followed by an
id, since those are GitHub's issue-closing keywords.

- Same repo: `T7kq2x`.
- Same owner as this repo: `billing#T7kq2x`. This is the usual form.
- Different owner: `someone-else/lib#T7kq2x`. Use it only when the
  owner differs from the current repo's.

The owner and repo name come from `git remote get-url origin`. A repo with no
remote is named by its directory, and only a bare `name#Txxxxx` can refer to it.

When writing a reference, use the shortest form that's unambiguous from the
repo the task is in.

**Resolve a reference to a local clone.** Directory names don't reliably
match remote names (`acme-tracing` may be a clone of `tracing`), so match on
the remote. Build the map once per session, which takes a few seconds:

```sh
bash -c 'for d in ~/src/{*,*/*,*/*/*}/; do [ -e "$d/.git" ] || continue
  u=$(git -C "$d" remote get-url origin 2>/dev/null) || continue
  printf "%s %s %s\n" "$(echo "$u" | sed -E "s#\.git\$##; s#.*[:/]([^/]+/[^/]+)\$#\1#")" \
    "$(git -C "$d" log -1 --format=%ct 2>/dev/null)" "${d%/}"
done'   # lines: owner/repo  last-commit-epoch  path
```

Look up `<owner>/<repo>`, taking the owner from the current repo when the
reference leaves it out. One remote can have several clones (forks,
worktree-style copies, submodules). Use the one with the newest last commit,
and mention the others if they disagree.

**A personal tasks repo** (say `you/tasks`, cloned anywhere under `~/src`,
usually private) holds two kinds of task: work that isn't tied to any repo,
and umbrella tasks that span repos, possibly across owners. An umbrella task
lists its per-repo subtasks in `deps` with owner-qualified references (it
lives under a different owner than they do), so it shows as ready once they
are all closed. Each subtask says `part of you/tasks#Th4tzb` in its body. If
the tasks repo is private, leave that backlink out of subtasks in shared
repos, because teammates can't resolve it.

**Dependency state.** Resolve the reference to a clone `$d`, then:

1. `$d/.tasks/xxxxx-*.md` exists → **open**.
2. Otherwise, if `git -C "$d" log --diff-filter=D --format=%h -- '.tasks/xxxxx-*'`
   prints a commit → **done**. The clone may be stale: offer to
   `git -C "$d" fetch` and check `origin/HEAD` when it matters.
3. Otherwise (not cloned, or the id never existed) → **unknown**. Report it.
   Don't treat it as done.

A `blocked` task whose deps are all done is **ready**: say so, and offer to
set it back to `todo`.

## Operations (in one repo)

**New.** Draw a random 5-character id from `0-9a-z` without `i l o u`, and
redraw if any ref this clone knows has ever used it, deleted tasks included,
so ids are never reused:

```sh
bash -c 'used=$({ ls .tasks; git log --all --format= --name-only -- .tasks/; } 2>/dev/null \
    | sed -n "s#^\(\.tasks/\)\{0,1\}\([0-9a-z]\{5\}\)-.*#\2#p")
  while id=$(LC_ALL=C tr -dc 0-9abcdefghjkmnpqrstvwxyz </dev/urandom | head -c5)
    printf "%s\n" "$used" | grep -qx "$id"; do :; done; echo "$id"'
```

Two branches that haven't seen each other can still draw the same id, but
rarely: about 0.03% when each adds 100 tasks. The session hook warns when it happens;
then rename the newer file and fix its references.

Create the file with `status: todo`. If `.tasks/README.md` is missing, copy
`README.template.md` from this skill's directory there in the same step.

**List.** `grep -H '^status:' .tasks/*-*.md`. Show id, status and title.

**Start / block.** Edit the `status:` line. For `blocked`, write the reason
in the body, and in `deps` when it is another task.

**Done.** Delete the file (`rm .tasks/7kq2x-*.md`) along with the change that
resolves it, so the same commit closes the task and ships the fix. Put the id
in the commit message (`… (task T7kq2x)`). The user's git rules still apply:
staging and committing need their approval. Then check whether this unblocks
anything elsewhere: `bash -c "grep -l '<repo>#T7kq2x' ~/src/{*,*/*,*/*/*}/.tasks/*-*.md"`.

**Closed tasks / history:**

- list closed tasks: `git log --diff-filter=D --format='%h %ad %s' --date=short --name-only -- .tasks/`
- read a closed task: `git show <commit>^:.tasks/7kq2x-fix-login-timeout.md`
- find work by id: `git log --grep T7kq2x` plus `git log -- '.tasks/7kq2x-*'`
- search all task text ever written: `git log -S '<text>' -- .tasks/`
- the Claude sessions that touched a task: the `Claude-Session:` trailers in
  `git log -- '.tasks/7kq2x-*'`. Don't record session ids in the task file.

## Overview and planning (all repos)

Repos sit at depth 1 to 3 under `~/src`. This scan finds every open task:

```sh
bash -c "grep -H -e '^status:' -e '^due:' -e '^deps:' -e '^# ' ~/src/{*,*/*,*/*/*}/.tasks/*-*.md 2>/dev/null"
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
bash -c 'for r in ~/src/{*,*/*,*/*/*}/; do [ -e "$r/.git" ] || continue
  n=$(git -C "$r" log --since="1 week ago" --diff-filter=D --format= --name-only -- ".tasks/*-*" 2>/dev/null | grep -c .)
  [ "$n" -gt 0 ] && echo "${r#$HOME/src/} $n"; done'
```

## Setup in a new repo

Only when the user asks for it: `mkdir .tasks`, then copy `README.template.md`
from this skill's directory to `.tasks/README.md`, then create the first task.
If the user ran just `mkdir .tasks` themselves, the README gets added with the
first new task (see New).
Don't add an index, a template task, or a script.
