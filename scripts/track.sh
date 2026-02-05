#!/bin/bash
# Track conviction accuracy over time
# Usage: track.sh [--resolve <slug> --outcome <yes|no>] [--stats] [--list]

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HISTORY_FILE="${SCRIPT_DIR}/../data/history.json"

# Ensure history file exists
if [ ! -f "$HISTORY_FILE" ]; then
  echo '{"convictions":[]}' > "$HISTORY_FILE"
fi

ACTION="list"
SLUG=""
OUTCOME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --resolve|-r)
      ACTION="resolve"
      SLUG="$2"
      shift 2
      ;;
    --outcome|-o)
      OUTCOME="$2"
      shift 2
      ;;
    --stats|-s)
      ACTION="stats"
      shift
      ;;
    --list|-l)
      ACTION="list"
      shift
      ;;
    --help|-h)
      echo "Usage: track.sh [OPTIONS]"
      echo ""
      echo "Track conviction accuracy over time."
      echo ""
      echo "Options:"
      echo "  --list, -l              List all convictions (default)"
      echo "  --stats, -s             Show accuracy statistics"
      echo "  --resolve, -r <slug>    Mark a conviction as resolved"
      echo "  --outcome, -o <yes|no>  The actual outcome (use with --resolve)"
      echo ""
      echo "Examples:"
      echo "  track.sh --list"
      echo "  track.sh --stats"
      echo "  track.sh --resolve vance-2028 --outcome yes"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

case $ACTION in
  list)
    echo "=== Conviction History ==="
    echo ""
    jq -r '.convictions[] | "[\(.timestamp | split("T")[0])] \(.question)\n  Direction: \(.direction) @ \(.market_odds) (my estimate: \(.my_estimate))\n  Edge: \(.edge) | Confidence: \(.confidence)\n  Status: \(.status)\(.outcome | if . then " → Outcome: \(.)" else "" end)\n"' "$HISTORY_FILE"
    
    TOTAL=$(jq '.convictions | length' "$HISTORY_FILE")
    echo "Total convictions: $TOTAL"
    ;;
    
  stats)
    echo "=== Conviction Statistics ==="
    echo ""
    
    TOTAL=$(jq '.convictions | length' "$HISTORY_FILE")
    RESOLVED=$(jq '[.convictions[] | select(.resolved != null)] | length' "$HISTORY_FILE")
    PENDING=$(jq '[.convictions[] | select(.resolved == null)] | length' "$HISTORY_FILE")
    
    # Calculate accuracy (convictions where direction matched outcome)
    CORRECT=$(jq '[.convictions[] | select(.resolved != null) | select(
      (.direction == "YES" and .outcome == "yes") or
      (.direction == "NO" and .outcome == "no")
    )] | length' "$HISTORY_FILE")
    
    if [ "$RESOLVED" -gt 0 ]; then
      ACCURACY=$(echo "scale=1; $CORRECT * 100 / $RESOLVED" | bc)
    else
      ACCURACY="N/A"
    fi
    
    # Calculate edge-weighted returns
    EDGE_SUM=$(jq '[.convictions[] | select(.resolved != null) | select(
      (.direction == "YES" and .outcome == "yes") or
      (.direction == "NO" and .outcome == "no")
    ) | .edge] | add // 0' "$HISTORY_FILE")
    
    echo "Total Convictions: $TOTAL"
    echo "Resolved: $RESOLVED"
    echo "Pending: $PENDING"
    echo ""
    echo "Accuracy: $CORRECT / $RESOLVED ($ACCURACY%)"
    echo "Cumulative Edge (correct calls): $EDGE_SUM%"
    echo ""
    
    # Breakdown by confidence
    echo "=== By Confidence Level ==="
    for CONF in "High" "Medium" "Low"; do
      CONF_TOTAL=$(jq --arg c "$CONF" '[.convictions[] | select(.confidence == $c)] | length' "$HISTORY_FILE")
      CONF_RESOLVED=$(jq --arg c "$CONF" '[.convictions[] | select(.confidence == $c) | select(.resolved != null)] | length' "$HISTORY_FILE")
      CONF_CORRECT=$(jq --arg c "$CONF" '[.convictions[] | select(.confidence == $c) | select(.resolved != null) | select(
        (.direction == "YES" and .outcome == "yes") or
        (.direction == "NO" and .outcome == "no")
      )] | length' "$HISTORY_FILE")
      
      if [ "$CONF_RESOLVED" -gt 0 ]; then
        CONF_ACC=$(echo "scale=1; $CONF_CORRECT * 100 / $CONF_RESOLVED" | bc)
        echo "$CONF: $CONF_CORRECT/$CONF_RESOLVED ($CONF_ACC%)"
      else
        echo "$CONF: $CONF_TOTAL pending"
      fi
    done
    ;;
    
  resolve)
    if [ -z "$SLUG" ]; then
      echo "Error: --resolve requires a market slug" >&2
      exit 1
    fi
    if [ -z "$OUTCOME" ]; then
      echo "Error: --outcome required (yes or no)" >&2
      exit 1
    fi
    if [[ "$OUTCOME" != "yes" && "$OUTCOME" != "no" ]]; then
      echo "Error: --outcome must be 'yes' or 'no'" >&2
      exit 1
    fi
    
    # Find and update the conviction
    FOUND=$(jq --arg slug "$SLUG" '[.convictions[] | select(.market_slug | contains($slug))] | length' "$HISTORY_FILE")
    
    if [ "$FOUND" -eq 0 ]; then
      echo "No conviction found matching slug: $SLUG" >&2
      exit 1
    fi
    
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --arg slug "$SLUG" --arg outcome "$OUTCOME" --arg ts "$TIMESTAMP" '
      .convictions = [.convictions[] | 
        if (.market_slug | contains($slug)) then
          .resolved = $ts | .outcome = $outcome | .status = "resolved"
        else
          .
        end
      ]
    ' "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
    
    echo "Resolved conviction for '$SLUG' with outcome: $OUTCOME"
    
    # Show updated stats
    $0 --stats
    ;;
esac
