#!/bin/bash
# Back up every deployed file that `chezmoi apply` would change or remove.
#
# Usage: backup.sh [note]
#
# Writes ~/.chezmoi-backups/<timestamp>/ containing:
#   files/            the current deployed copies, with their modes and symlinks kept
#   chezmoi-diff.txt  the pending diff (owner-only: it can hold decrypted private lines)
#   manifest.json     what was saved, what apply would create, and what failed
# and points ~/.chezmoi-backups/latest at it. Prints a summary. Creates nothing when no
# file is pending. Exit status: 0 on success or nothing to do, 1 if any copy failed.
#
# Test hooks (not for normal use): CHEZMOI_BACKUP_ROOT, CHEZMOI_BACKUP_DEST and
# CHEZMOI_BACKUP_ARGS replace the backup folder, the home directory and add chezmoi flags.

set -u
# Do not change the umask here: chezmoi uses it to work out target permissions, so a
# stricter one makes every file look modified. The backup folder is made private below.

ROOT="${CHEZMOI_BACKUP_ROOT:-$HOME/.chezmoi-backups}"
DEST="${CHEZMOI_BACKUP_DEST:-$HOME}"
NOTE="${1:-}"

cz() {
  # shellcheck disable=SC2086
  chezmoi ${CHEZMOI_BACKUP_ARGS:-} "$@"
}

json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

json_array() {
  local first=1 item
  printf '['
  for item in "$@"; do
    [ "$first" -eq 1 ] || printf ', '
    printf '"%s"' "$(json_escape "$item")"
    first=0
  done
  printf ']'
}

# Scripts and externals are not files to back up: scripts are run and discarded, and
# externals are re-downloadable.
if ! status=$(cz status --exclude=externals,scripts); then
  echo "chezmoi status failed; no backup made" >&2
  exit 1
fi

if [ -z "$status" ]; then
  echo "Nothing to back up: chezmoi apply would not change any file."
  exit 0
fi

TS=$(date +%Y-%m-%d_%H-%M-%S)
BD="$ROOT/$TS"
if [ -e "$BD" ]; then
  TS="${TS}_$$"
  BD="$ROOT/$TS"
fi
mkdir -p "$BD/files" || { echo "cannot create $BD" >&2; exit 1; }
chmod 700 "$BD"

saved=()
created=()
failed=()
skipped=()

while IFS= read -r line; do
  [ -n "$line" ] || continue
  code=${line:0:2}
  path=${line:3}
  target="$DEST/$path"

  if [ -L "$target" ] || [ -f "$target" ]; then
    mkdir -p "$BD/files/$(dirname "$path")"
    if cp -pP "$target" "$BD/files/$path"; then
      saved+=("$path")
    else
      failed+=("$path")
    fi
  elif [ -d "$target" ]; then
    # A directory whose own attributes change. Its files are listed separately.
    skipped+=("$path")
  elif [ "${code:1:1}" = "A" ]; then
    # Does not exist yet: apply would create it. Undo needs to know.
    created+=("$path")
  else
    failed+=("$path")
  fi
done <<EOF
$status
EOF

: > "$BD/chezmoi-diff.txt"
chmod 600 "$BD/chezmoi-diff.txt"
cz diff --exclude=externals --no-pager >> "$BD/chezmoi-diff.txt" 2>&1

{
  printf '{\n'
  printf '  "timestamp": "%s",\n' "$TS"
  printf '  "date": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf '  "chezmoi_version": "%s",\n' "$(json_escape "$(cz --version)")"
  printf '  "total_files": %d,\n' "${#saved[@]}"
  printf '  "files_backed_up": %s,\n' "$(json_array ${saved[@]+"${saved[@]}"})"
  printf '  "created_by_apply": %s,\n' "$(json_array ${created[@]+"${created[@]}"})"
  printf '  "directories_not_copied": %s,\n' "$(json_array ${skipped[@]+"${skipped[@]}"})"
  printf '  "failed_files": %s,\n' "$(json_array ${failed[@]+"${failed[@]}"})"
  printf '  "notes": "%s"\n' "$(json_escape "$NOTE")"
  printf '}\n'
} > "$BD/manifest.json"

ln -sfn "$BD" "$ROOT/latest"

echo "Backup ID: $TS"
echo "Location: $BD"
echo "Saved: ${#saved[@]}"
for p in ${saved[@]+"${saved[@]}"}; do echo "  saved    $p"; done
for p in ${created[@]+"${created[@]}"}; do echo "  new      $p (apply would create it; nothing to save)"; done
for p in ${skipped[@]+"${skipped[@]}"}; do echo "  dir      $p (attributes only; not copied)"; done
for p in ${failed[@]+"${failed[@]}"}; do echo "  FAILED   $p"; done

[ "${#failed[@]}" -eq 0 ]
