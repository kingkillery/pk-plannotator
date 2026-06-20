#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PROJECT_NAME="pk-planner-install"
TMP_DIR_REL=".tmp-pk-planner-pages"
TMP_DIR="$ROOT_DIR/$TMP_DIR_REL"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cp "$ROOT_DIR/scripts/install.sh" "$TMP_DIR/install.sh"

(
  cd "$ROOT_DIR"
  bunx wrangler pages deploy "$TMP_DIR_REL" \
    --project-name "$PROJECT_NAME" \
    --branch main \
    --commit-dirty=true
)
