#!/usr/bin/env bash
# Usage:
#   TARGET_URI="mongodb://user:pass@host" TARGET_DB="fml" ./import_all.sh dump/fml
# If TARGET_DB not provided, the folder name is used.

set -euo pipefail

DUMP_DIR=${1:-dump}
if [ ! -d "$DUMP_DIR" ]; then
  echo "Usage: TARGET_URI=\"<mongo-uri>\" TARGET_DB=\"<db>\" $0 dump/<dbname>"
  exit 2
fi

if [ -z "${TARGET_URI:-}" ]; then
  echo "Please set TARGET_URI env var (mongo connection string)."
  echo "Example: TARGET_URI=\"mongodb+srv://user:pass@cluster.mongodb.net\" TARGET_DB=\"fml\" $0 dump/fml"
  exit 2
fi

TARGET_DB=${TARGET_DB:-$(basename "$DUMP_DIR")}

echo "Importing JSON files from $DUMP_DIR into $TARGET_URI/$TARGET_DB"

for file in "$DUMP_DIR"/*.json; do
  [ -e "$file" ] || continue
  collname=$(basename "$file" .json)
  echo "Importing $file -> collection $collname"
  mongoimport --uri "$TARGET_URI/$TARGET_DB" --collection "$collname" --file "$file" --jsonArray --drop
done

echo "All done."
