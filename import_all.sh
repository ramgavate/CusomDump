#!/usr/bin/env bash
set -euo pipefail

if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  . ".env"
  set +a
fi

DUMP_DIR="${1:-}"

if [ -z "$DUMP_DIR" ] || [ ! -d "$DUMP_DIR" ]; then
  echo "Usage: ./import_all.sh dump/<dbname>"
  exit 2
fi

if [ -z "${TARGET_URI:-}" ]; then
  echo "ERROR: TARGET_URI is missing. Add it to .env"
  exit 2
fi

if [ -z "${TARGET_DB:-}" ]; then
  TARGET_DB="$(basename "$DUMP_DIR")"
fi

echo "Importing JSON files from $DUMP_DIR into $TARGET_URI/$TARGET_DB"

files=("$DUMP_DIR"/*.json)
if [ ! -e "${files[0]}" ]; then
  echo "ERROR: No JSON files found in $DUMP_DIR"
  exit 2
fi

for file in "${files[@]}"; do
  collname="$(basename "$file" .json)"
  echo "Importing $file -> collection $collname"
  mongoimport --uri "$TARGET_URI/$TARGET_DB" --collection "$collname" --file "$file" --jsonArray --drop
done

echo "All collections imported successfully."
