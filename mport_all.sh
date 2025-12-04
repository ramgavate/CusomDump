#!/usr/bin/env bash
# auto load .env
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

set -euo pipefail

# Usage:
#   ./import_all.sh dump/fml
# TARGET_URI and TARGET_DB should be set in .env

DUMP_DIR=${1:-dump}

if [ ! -d "$DUMP_DIR" ]; then
  echo "Usage: ./import_all.sh dump/<dbname>"
  exit 2
fi

if [ -z "${TARGET_URI:-}" ]; then
  echo "❌ TARGET_URI is missing. Add it to .env"
  exit 2
fi

if [ -z "${TARGET_DB:-}" ]; then
  TARGET_DB=$(basename "$DUMP_DIR")
fi

echo "🚀 Importing JSON files from $DUMP_DIR into $TARGET_URI/$TARGET_DB"

for file in "$DUMP_DIR"/*.json; do
  [ -e "$file" ] || continue
  collname=$(basename "$file" .json)
  echo "➡ Importing $file -> collection $collname"
  mongoimport --uri "$TARGET_URI/$TARGET_DB" --collection "$collname" --file "$file" --jsonArray --drop
done

echo "🎉 All done."
