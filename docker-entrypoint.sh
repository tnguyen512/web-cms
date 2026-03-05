#!/bin/sh
set -e

echo "=== Starting CMS Service ==="
echo "NODE_ENV: $NODE_ENV"
echo "DB_HOST: $DB_HOST"

echo ""
echo "=== Step 1: Running Bootstrap ==="
npx directus bootstrap || echo "Bootstrap already completed"

echo ""
echo "=== Step 2: Importing Schema ==="
npm run import || echo "Schema already imported"

echo ""
echo "=== Step 3: Starting Directus ==="
exec npx directus start
