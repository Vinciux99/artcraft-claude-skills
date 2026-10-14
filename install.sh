#!/usr/bin/env bash
# ArtCraft skills installer for macOS.
#   curl -fsSL https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.sh | bash -s -- --apps gridcraft,wordcraft
# Options: --apps a,b|all  --mode live|headless|both  --dry-run  --no-launcher --no-claude-desktop --no-claude-code --no-skill --no-download
#          --local DIR   (use an already downloaded copy of the hub instead of downloading)
set -euo pipefail
APPS=""; LOCAL=""; PASS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --apps) APPS="$2"; shift 2;;
    --local) LOCAL="$2"; shift 2;;
    --mode) PASS+=("--mode" "$2"); shift 2;;
    -h|--help) sed -n '2,6p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0;;
    *) PASS+=("$1"); shift;;
  esac
done
[ -n "$APPS" ] || { echo "Usage: install.sh --apps gridcraft,wordcraft  (or --apps all)"; exit 2; }
if [ -n "$LOCAL" ]; then
  SRC="$(cd "$LOCAL" && pwd)"
else
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  echo "Downloading ArtCraft skills..."
  curl -fsSL "https://github.com/Vinciux99/artcraft-claude-skills/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP"
  SRC="$TMP/artcraft-claude-skills-main"
fi
if [ "$APPS" = "all" ]; then APPS="$(ls "$SRC/apps" | tr '\n' ',')"; fi
IFS=',' read -r -a LIST <<< "$APPS"
for ID in "${LIST[@]}"; do
  ID="$(echo "$ID" | tr -d '[:space:]')"; [ -n "$ID" ] || continue
  if [ ! -f "$SRC/apps/$ID/app.json" ]; then echo "Unknown app: $ID"; exit 2; fi
  echo; echo "=== $ID ==="
  if [ ${#PASS[@]} -gt 0 ]; then
    bash "$SRC/scripts/artcraft-setup.sh" --config "$SRC/apps/$ID/app.json" --skill-dir "$SRC/plugins/$ID/skills/$ID" "${PASS[@]}"
  else
    bash "$SRC/scripts/artcraft-setup.sh" --config "$SRC/apps/$ID/app.json" --skill-dir "$SRC/plugins/$ID/skills/$ID"
  fi
done
echo; echo "Done. Fully quit and reopen Claude, then start each app with its \"<App> (Claude)\" launcher."
