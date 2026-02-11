#!/bin/bash
# watchlist.sh — Manage conviction watchlist
# Track markets you're monitoring but haven't acted on yet

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WATCHLIST="$SKILL_DIR/data/watchlist.json"

# Ensure data directory exists
mkdir -p "$SKILL_DIR/data"

# Initialize watchlist if doesn't exist
if [ ! -f "$WATCHLIST" ]; then
  echo '{"markets":[]}' > "$WATCHLIST"
fi

ACTION="${1:-list}"
shift 2>/dev/null || true

case "$ACTION" in
  add)
    if [ -z "$1" ]; then
      echo "Usage: $0 add <market-name> [target-odds] [notes]"
      exit 1
    fi
    MARKET="$1"
    TARGET="${2:-}"
    NOTES="${3:-}"
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Add to watchlist
    jq --arg m "$MARKET" --arg t "$TARGET" --arg n "$NOTES" --arg ts "$TIMESTAMP" \
      '.markets += [{"market": $m, "target": $t, "notes": $n, "added": $ts}]' \
      "$WATCHLIST" > "$WATCHLIST.tmp" && mv "$WATCHLIST.tmp" "$WATCHLIST"
    
    echo "✅ Added to watchlist: $MARKET"
    [ -n "$TARGET" ] && echo "   Target: $TARGET"
    [ -n "$NOTES" ] && echo "   Notes: $NOTES"
    ;;
    
  remove|rm)
    if [ -z "$1" ]; then
      echo "Usage: $0 remove <market-name>"
      exit 1
    fi
    MARKET="$1"
    
    jq --arg m "$MARKET" '.markets = [.markets[] | select(.market != $m)]' \
      "$WATCHLIST" > "$WATCHLIST.tmp" && mv "$WATCHLIST.tmp" "$WATCHLIST"
    
    echo "🗑️ Removed from watchlist: $MARKET"
    ;;
    
  list|ls|"")
    echo "👁️ Conviction Watchlist"
    echo "======================="
    
    COUNT=$(jq '.markets | length' "$WATCHLIST")
    if [ "$COUNT" -eq 0 ]; then
      echo "(empty)"
      echo ""
      echo "Add markets: $0 add \"market name\" [target] [notes]"
    else
      jq -r '.markets[] | "• \(.market)\n  Added: \(.added)\(.target | if . != "" then "\n  Target: \(.)" else "" end)\(.notes | if . != "" then "\n  Notes: \(.)" else "" end)\n"' "$WATCHLIST"
    fi
    ;;
    
  clear)
    echo '{"markets":[]}' > "$WATCHLIST"
    echo "🗑️ Watchlist cleared"
    ;;
    
  *)
    echo "Usage: $0 [add|remove|list|clear]"
    echo ""
    echo "Commands:"
    echo "  list              Show all watched markets (default)"
    echo "  add <market>      Add market to watchlist"
    echo "  remove <market>   Remove market from watchlist"
    echo "  clear             Clear entire watchlist"
    ;;
esac
