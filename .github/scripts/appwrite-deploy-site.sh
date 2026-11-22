#!/usr/bin/env bash
# Deploys a prebuilt static folder to an Appwrite Site and waits until it is live.
# Usage: APPWRITE_API_KEY=... appwrite-deploy-site.sh <siteId> <folder>
set -euo pipefail
SITE_ID="$1"; DIR="$2"
ENDPOINT="${APPWRITE_ENDPOINT:-https://sgp.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT_ID:-6b012dd80037b9146a2b}"
: "${APPWRITE_API_KEY:?APPWRITE_API_KEY is required}"

ARCHIVE="$(mktemp -d)/site.tar.gz"
tar -czf "$ARCHIVE" -C "$DIR" .
H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $APPWRITE_API_KEY")

DEPLOYMENT=$(curl -sfS -X POST "$ENDPOINT/sites/$SITE_ID/deployments" "${H[@]}" \
  -F "code=@$ARCHIVE;type=application/gzip" -F "activate=true" | node -pe 'JSON.parse(require("fs").readFileSync(0)).$id')
echo "Deployment $DEPLOYMENT created"

for _ in $(seq 1 60); do
  STATUS=$(curl -sfS "$ENDPOINT/sites/$SITE_ID/deployments/$DEPLOYMENT" "${H[@]}" | node -pe 'JSON.parse(require("fs").readFileSync(0)).status')
  echo "Status: $STATUS"
  case "$STATUS" in
    ready) exit 0 ;;
    failed|canceled) exit 1 ;;
  esac
  sleep 5
done
echo "Timed out waiting for the deployment"; exit 1
