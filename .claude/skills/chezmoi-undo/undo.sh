#!/bin/bash
# Compare a chezmoi backup with the current deployed files, or restore from it.
#
# Usage:
#   undo.sh plan    <backup-id|latest> [file...]
#   undo.sh restore <backup-id|latest> [file...]
#
# plan     prints, for each file in the backup, whether the deployed copy is identical,
#          differs or is missing. Changes nothing.
# restore  first saves the current copies of the files it is about to overwrite into a
#          new backup named <timestamp>_pre-undo, then copies the backed-up files back.
#
# With file arguments (paths relative to the home directory, as the manifest lists them),
# only those files are compared or restored. Files that `chezmoi apply` created are never
# deleted; they are listed so the user can decide.
# Exit status: 0 on success, 1 on a bad argument or any failed copy.
#
# Test hooks (not for normal use): CHEZMOI_BACKUP_ROOT and CHEZMOI_BACKUP_DEST replace
# the backup folder and the home directory.

set -u

ROOT="${CHEZMOI_BACKUP_ROOT:-$HOME/.chezmoi-backups}"
DEST="${CHEZMOI_BACKUP_DEST:-$HOME}"

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 1
}

[ $# -ge 2 ] || usage
mode=$1
id=$2
shift 2

case $mode in plan | restore) ;; *) usage ;; esac
case $id in
  */* | .* | "") echo "bad backup id: $id" >&2; exit 1 ;;
esac

BD="$ROOT/$id"
if [ ! -d "$BD/files" ]; then
  echo "No backup '$id' in $ROOT. Available:" >&2
  for d in "$ROOT"/*/; do
    [ -f "${d}manifest.json" ] && [ ! -L "${d%/}" ] && basename "$d" >&2
  done
  exit 1
fi
# Resolve `latest` to the real folder name for the report.
real=$(cd "$BD" && pwd -P)
echo "Backup: $(basename "$real")"

# The files to act on: the arguments, or everything in the backup.
files=()
if [ $# -gt 0 ]; then
  for f in "$@"; do
    f=${f#"$DEST"/}
    f=${f#\~/}
    if [ -L "$BD/files/$f" ] || [ -f "$BD/files/$f" ]; then
      files+=("$f")
    else
      echo "not in this backup: $f" >&2
      exit 1
    fi
  done
else
  while IFS= read -r f; do
    files+=("${f#"$BD/files/"}")
  done <<EOF
$(find "$BD/files" \( -type f -o -type l \) | sort)
EOF
fi

if [ "${#files[@]}" -eq 0 ] || [ -z "${files[0]}" ]; then
  echo "This backup holds no files."
  exit 0
fi

state_of() {
  local f=$1
  if [ ! -e "$DEST/$f" ] && [ ! -L "$DEST/$f" ]; then
    echo missing
  elif [ -L "$BD/files/$f" ] || [ -L "$DEST/$f" ]; then
    if [ "$(readlink "$BD/files/$f" 2>/dev/null)" = "$(readlink "$DEST/$f" 2>/dev/null)" ] &&
      [ -L "$BD/files/$f" ] && [ -L "$DEST/$f" ]; then
      echo identical
    else
      echo differs
    fi
  elif cmp -s "$BD/files/$f" "$DEST/$f"; then
    echo identical
  else
    echo differs
  fi
}

# Files apply would have created: undo leaves them alone, so say so.
created=$(sed -n 's/^  "created_by_apply": \[\(.*\)\],\{0,1\}$/\1/p' "$BD/manifest.json" 2>/dev/null |
  tr ',' '\n' | sed 's/^ *"//; s/" *$//')
report_created() {
  local c
  [ -n "$created" ] || return 0
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    if [ -e "$DEST/$c" ] || [ -L "$DEST/$c" ]; then
      echo "  created  $c (made by apply after this backup; not removed)"
    fi
  done <<EOF
$created
EOF
}

if [ "$mode" = plan ]; then
  for f in "${files[@]}"; do
    printf '  %-9s %s\n' "$(state_of "$f")" "$f"
  done
  report_created
  exit 0
fi

# restore: snapshot what is about to be overwritten, then copy back.
to_restore=()
for f in "${files[@]}"; do
  [ "$(state_of "$f")" = identical ] || to_restore+=("$f")
done
if [ "${#to_restore[@]}" -eq 0 ]; then
  echo "Nothing to restore: every file already matches the backup."
  report_created
  exit 0
fi

SNAP_ID="$(date +%Y-%m-%d_%H-%M-%S)_pre-undo"
SNAP="$ROOT/$SNAP_ID"
if [ -e "$SNAP" ]; then
  SNAP_ID="${SNAP_ID}_$$"
  SNAP="$ROOT/$SNAP_ID"
fi
mkdir -p "$SNAP/files" || { echo "cannot create $SNAP" >&2; exit 1; }
chmod 700 "$SNAP"
snapped=()
for f in "${to_restore[@]}"; do
  if [ -e "$DEST/$f" ] || [ -L "$DEST/$f" ]; then
    mkdir -p "$SNAP/files/$(dirname "$f")"
    if cp -pP "$DEST/$f" "$SNAP/files/$f"; then
      snapped+=("$f")
    else
      echo "could not save the current $f; nothing was restored" >&2
      exit 1
    fi
  fi
done
{
  printf '{\n  "timestamp": "%s",\n' "$SNAP_ID"
  printf '  "date": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf '  "total_files": %d,\n' "${#snapped[@]}"
  printf '  "files_backed_up": ['
  first=1
  for f in ${snapped[@]+"${snapped[@]}"}; do
    [ "$first" -eq 1 ] || printf ', '
    g=${f//\\/\\\\}
    printf '"%s"' "${g//\"/\\\"}"
    first=0
  done
  printf '],\n  "created_by_apply": [],\n  "failed_files": [],\n'
  printf '  "notes": "Taken automatically before restoring from %s"\n}\n' "$(basename "$real")"
} > "$SNAP/manifest.json"
echo "Saved the current copies first: $SNAP_ID"

failed=0
for f in "${to_restore[@]}"; do
  mkdir -p "$DEST/$(dirname "$f")"
  # Copy beside the target, then rename over it: a symlink is replaced, not followed,
  # and a failed copy leaves the current file in place.
  tmp="$DEST/$f.undo-tmp.$$"
  if cp -pP "$BD/files/$f" "$tmp" && mv -f "$tmp" "$DEST/$f"; then
    echo "  restored $f"
  else
    echo "  FAILED   $f" >&2
    failed=1
  fi
done
report_created
exit "$failed"
