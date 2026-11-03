#!/bin/sh
# SessionStart hook: tell Claude about this repo's open tasks. Silent outside repos with .tasks/.
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
source=$(printf '%s' "$input" | jq -r '.source // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -d "$root/.tasks" ] || exit 0

echo "This repo tracks tasks in .tasks/ (see the tasks skill). Open tasks:"
found=
for f in "$root"/.tasks/[0-9]*.md; do
  [ -e "$f" ] || continue
  found=1
  status=$(sed -n 's/^status: *\([a-z]*\).*/\1/p' "$f" | head -1)
  title=$(sed -n 's/^# //p' "$f" | head -1)
  echo "- $(basename "$f" .md) [$status] $title"
done
[ -n "$found" ] || echo "- (none)"

if [ "$source" = compact ]; then
  echo "The conversation was just compacted. If the work in progress is not yet captured in a task file, or a task's state/next step is stale, propose promoting or updating it now."
fi
