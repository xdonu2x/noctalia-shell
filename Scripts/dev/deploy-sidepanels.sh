#!/usr/bin/env bash
set -euo pipefail

# Deploy side-panels related files from a downloaded Noctalia zip.
# Usage:
#   ./Scripts/dev/deploy-sidepanels.sh /path/to/noctalia.zip [/etc/xdg/quickshell/noctalia-shell]

ZIP_PATH="${1:-}"
TARGET_ROOT="${2:-/etc/xdg/quickshell/noctalia-shell}"

if [[ -z "$ZIP_PATH" ]]; then
  echo "Usage: $0 /path/to/noctalia.zip [target_root]"
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: Zip file not found: $ZIP_PATH"
  exit 1
fi

if [[ ! -d "$TARGET_ROOT" ]]; then
  echo "ERROR: Target root not found: $TARGET_ROOT"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

UNZIP_DIR="$TMP_DIR/unzipped"
mkdir -p "$UNZIP_DIR"

echo "==> Unzipping: $ZIP_PATH"
unzip -q "$ZIP_PATH" -d "$UNZIP_DIR"

# Detect repo root by locating shell.qml (safe with spaces)
SOURCE_SHELL_QML="$(find "$UNZIP_DIR" -type f -name shell.qml -print -quit || true)"
if [[ -z "$SOURCE_SHELL_QML" ]]; then
  echo "ERROR: Could not find shell.qml inside zip (cannot detect source root)."
  exit 1
fi
SOURCE_ROOT="$(dirname "$SOURCE_SHELL_QML")"

echo "==> Source root: $SOURCE_ROOT"
echo "==> Target root: $TARGET_ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$TARGET_ROOT/.backup-sidepanels-$STAMP"
mkdir -p "$BACKUP_ROOT"

# Side-panel feature files (new + changed)
FILES=(
  "Assets/settings-default.json"
  "Assets/settings-search-index.json"
  "Commons/Settings.qml"
  "Modules/MainScreen/MainScreen.qml"
  "Modules/MainScreen/SideWidgetPanel.qml"
  "Modules/Panels/Settings/SettingsContent.qml"
  "Modules/Panels/Settings/SettingsPanel.qml"
  "Modules/Panels/Settings/Tabs/Bar/BarTab.qml"
  "Modules/Panels/Settings/Tabs/Bar/SidePanelsSubTab.qml"
  "Modules/Panels/Settings/Tabs/SidePanels/SidePanelsTab.qml"
)

copied=0
missing=0

for rel in "${FILES[@]}"; do
  src="$SOURCE_ROOT/$rel"
  dst="$TARGET_ROOT/$rel"

  if [[ ! -f "$src" ]]; then
    echo "WARN: Missing in zip, skipped: $rel"
    ((missing+=1))
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  mkdir -p "$(dirname "$BACKUP_ROOT/$rel")"

  if [[ -f "$dst" ]]; then
    cp -a "$dst" "$BACKUP_ROOT/$rel"
  fi

  cp -a "$src" "$dst"
  echo "OK: $rel"
  ((copied+=1))
done

echo
echo "==> Done"
echo "Copied:  $copied"
echo "Missing: $missing"
echo "Backup:  $BACKUP_ROOT"

echo
echo "Now restart quickshell/noctalia (example):"
echo "  pkill -f quickshell || true"
echo "  qs -c noctalia-shell &"
