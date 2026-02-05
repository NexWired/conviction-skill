#!/bin/bash
# Publish a conviction thesis to Moltbook
# Usage: publish.sh --input <analysis.json> --to moltbook [--submolt <name>] [--dry-run]

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
INPUT_FILE=""
DESTINATION="moltbook"
SUBMOLT="usdc"
DRY_RUN=false
HASHTAGS="#USDCHackathon #ConvictionSkill"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --input|-i)
      INPUT_FILE="$2"
      shift 2
      ;;
    --to)
      DESTINATION="$2"
      shift 2
      ;;
    --submolt|-s)
      SUBMOLT="$2"
      shift 2
      ;;
    --dry-run|-n)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      echo "Usage: publish.sh --input <file.json> --to moltbook [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --input <file>      JSON file with completed conviction analysis"
      echo "  --to <destination>  Where to publish (moltbook)"
      echo "  --submolt <name>    Moltbook submolt (default: usdc)"
      echo "  --dry-run           Preview without posting"
      echo ""
      echo "The input JSON should have conviction fields filled in."
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Validate input
if [ -z "$INPUT_FILE" ]; then
  echo "Error: --input required" >&2
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File not found: $INPUT_FILE" >&2
  exit 1
fi

# Read and validate JSON
ANALYSIS=$(cat "$INPUT_FILE")

# Check if analysis is complete
STATUS=$(echo "$ANALYSIS" | jq -r '._meta.status // "unknown"')
ESTIMATE=$(echo "$ANALYSIS" | jq -r '.conviction.estimate // empty')

if [ -z "$ESTIMATE" ]; then
  echo "Error: Conviction analysis incomplete - missing estimate" >&2
  echo "Fill in the conviction fields before publishing." >&2
  exit 1
fi

# Extract fields for post
QUESTION=$(echo "$ANALYSIS" | jq -r '.market.question')
SLUG=$(echo "$ANALYSIS" | jq -r '.market.slug')
CURRENT_ODDS=$(echo "$ANALYSIS" | jq -r '.market.current_odds')
MY_ESTIMATE=$(echo "$ANALYSIS" | jq -r '.conviction.estimate')
EDGE=$(echo "$ANALYSIS" | jq -r '.conviction.edge')
DIRECTION=$(echo "$ANALYSIS" | jq -r '.conviction.direction')
CONFIDENCE=$(echo "$ANALYSIS" | jq -r '.conviction.confidence')
THESIS=$(echo "$ANALYSIS" | jq -r '.thesis')
RECOMMENDATION=$(echo "$ANALYSIS" | jq -r '.conviction.recommendation')

# Format key factors
FACTORS=$(echo "$ANALYSIS" | jq -r '.key_factors[] | "• \(.factor) (\(.impact), \(.weight) weight)"' 2>/dev/null || echo "• No factors specified")

# Format risks
RISKS=$(echo "$ANALYSIS" | jq -r '.risks[]' 2>/dev/null | sed 's/^/• /' || echo "• No risks specified")

# Build the post
POST=$(cat << EOF
🎯 **CONVICTION: ${QUESTION}**

**Market:** ${DIRECTION} @ ${CURRENT_ODDS}
**My Estimate:** ${MY_ESTIMATE} (${CONFIDENCE} confidence)
**Edge:** ${EDGE}
**Recommendation:** ${RECOMMENDATION}

---

**Thesis:**
${THESIS}

**Key Factors:**
${FACTORS}

**Risks:**
${RISKS}

---

📊 Market: https://polymarket.com/event/${SLUG}
🔧 Built with conviction skill

${HASHTAGS}
EOF
)

# Output or publish
if [ "$DRY_RUN" = true ]; then
  echo "=== DRY RUN - Would post to m/${SUBMOLT} ==="
  echo ""
  echo "$POST"
  echo ""
  echo "=== End preview ==="
else
  case $DESTINATION in
    moltbook)
      echo "Publishing to m/${SUBMOLT}..."
      # For now, output the formatted post
      # Actual Moltbook API integration would go here
      echo ""
      echo "$POST"
      echo ""
      echo "---"
      echo "To post to Moltbook, copy the above and post to m/${SUBMOLT}"
      echo "Or use the Moltbook skill if available."
      ;;
    *)
      echo "Error: Unknown destination: $DESTINATION" >&2
      exit 1
      ;;
  esac
fi

# Log to history
HISTORY_FILE="${SCRIPT_DIR}/../data/history.json"
if [ ! -f "$HISTORY_FILE" ]; then
  echo '{"convictions":[]}' > "$HISTORY_FILE"
fi

# Append to history
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HISTORY_ENTRY=$(jq -n \
  --arg ts "$TIMESTAMP" \
  --arg question "$QUESTION" \
  --arg slug "$SLUG" \
  --argjson odds "$CURRENT_ODDS" \
  --argjson estimate "$MY_ESTIMATE" \
  --argjson edge "$EDGE" \
  --arg direction "$DIRECTION" \
  --arg confidence "$CONFIDENCE" \
  --arg status "published" \
  '{
    timestamp: $ts,
    question: $question,
    market_slug: $slug,
    market_odds: $odds,
    my_estimate: $estimate,
    edge: $edge,
    direction: $direction,
    confidence: $confidence,
    status: $status,
    resolved: null,
    outcome: null
  }')

# Update history file
jq --argjson entry "$HISTORY_ENTRY" '.convictions += [$entry]' "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"

echo "Logged to conviction history."
