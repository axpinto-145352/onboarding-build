#!/bin/bash
# Import all Veteran Vectors n8n workflows via the n8n REST API
# Usage: ./import_workflows.sh

set -euo pipefail

N8N_URL="https://veteranvectors.app.n8n.cloud"
N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkZDhiMjQxMi03OTNmLTQwMjAtYjBlMC0wZmRkMTY2NTRiZWMiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiODQ2YTQzZmYtM2FlYy00NTVjLWE0MjMtYzEyYjNkNTk4NjhlIiwiaWF0IjoxNzczNTI0MzgyLCJleHAiOjE3ODEyNDc2MDB9.66rz5lvYxlJDILwtsppc5hUPYWnq2q0LmApQqX3uM24"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

WORKFLOWS=(
  "WF0_Lead_Scoring.json"
  "WF_STEP1_Prosp_LinkedIn_Connection.json"
  "WF_STEP2_Loom_Sent.json"
  "WF_STEP3A_No_Response_Followup.json"
  "WF_STEP3C_Calendly_Screening.json"
  "WF_STEP4_Meeting_Processing.json"
  "WF_STEP4B_Audit_Call_Processing.json"
  "WF_STEP5_SOW_Contract.json"
  "WF_STEP6_Contract_Reminders.json"
  "WF_STEP7_Post_Signing.json"
  "WF_STEP8_Calendly_Notion_Sync.json"
  "BACKFILL_1_Prosp_to_Notion.json"
  "BACKFILL_2_Loom_to_Notion.json"
  "BACKFILL_3_Calendly_to_Notion.json"
  "BACKFILL_4_Bluedot_to_Notion.json"
)

echo "=== n8n Workflow Import ==="
echo "Target: $N8N_URL"
echo ""

SUCCESS=0
FAIL=0

for wf in "${WORKFLOWS[@]}"; do
  FILE="$SCRIPT_DIR/$wf"
  if [ ! -f "$FILE" ]; then
    echo "SKIP: $wf (file not found)"
    continue
  fi

  # Extract workflow name from JSON
  NAME=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['name'])" "$FILE" 2>/dev/null || echo "$wf")

  echo -n "Importing: $NAME ... "

  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$N8N_URL/api/v1/workflows" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -H "Content-Type: application/json" \
    -d @"$FILE" 2>&1)

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    WF_ID=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['id'])" "$BODY" 2>/dev/null || echo "unknown")
    echo "OK (id: $WF_ID)"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "FAILED (HTTP $HTTP_CODE)"
    echo "  Response: $BODY" | head -3
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== Done: $SUCCESS succeeded, $FAIL failed ==="
