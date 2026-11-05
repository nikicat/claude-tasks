#!/bin/sh
# SessionStart hook: tell Claude about this repo's open tasks. Silent outside repos with .tasks/.
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
source=$(printf '%s' "$input" | jq -r '.source // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -d "$root/.tasks" ] || exit 0

echo "This repo tracks tasks in .tasks/ (see the tasks skill). Open tasks:"
found=
for f in "$root"/.tasks/*-*.md; do
  [ -e "$f" ] || continue
  found=1
  status=$(sed -n 's/^status: *\([a-z]*\).*/\1/p' "$f" | head -1)
  title=$(sed -n 's/^# //p' "$f" | head -1)
  echo "- $(basename "$f" .md) [$status] $title"
done
[ -n "$found" ] || echo "- (none)"

# Random ids drawn on branches that hadn't seen each other can clash after a merge.
dups=$(ls "$root"/.tasks | sed -n 's/^\([^-]*\)-.*\.md$/\1/p' | sort | uniq -d)
[ -z "$dups" ] || echo "Duplicate task ids: $(echo $dups). Propose renaming the newer file of each (git log --diff-filter=A) to a fresh id and fixing its references."

if [ "$source" = compact ]; then
  echo "The conversation was just compacted. If the work in progress is not yet captured in a task file, or a task's state/next step is stale, propose promoting or updating it now."
fi
