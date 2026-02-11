#!/bin/bash
# opportunities.sh — Find prediction markets with potential edge
# Scans active markets and highlights where odds may be mispriced

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SKILL_DIR/scripts/lib/utils.sh" 2>/dev/null || true

# Default settings
CATEGORY="${1:-politics}"
MIN_VOLUME=100000  # $100k minimum
LIMIT=10

echo "🔍 Scanning $CATEGORY markets for opportunities..."
echo ""

# Get active markets via Polymarket API (gamma-api for active markets)
MARKETS=$(curl -s "https://gamma-api.polymarket.com/events?closed=false&limit=$LIMIT" 2>/dev/null)

if [ -z "$MARKETS" ] || [ "$MARKETS" = "[]" ]; then
  echo "⚠️ Could not fetch markets. Try again later."
  exit 1
fi

echo "📊 Active High-Volume Markets"
echo "=============================="
echo ""

# Parse and display markets with volume
echo "$MARKETS" | jq -r '
  .[] | 
  select(.volume != null) |
  "\(.title)\n  Volume: $\(.volume | tonumber | . / 1000000 | floor)M\n  Markets: \(.markets | length)\n"
' 2>/dev/null | head -50

echo ""
echo "💡 Tip: Use './scripts/form.sh \"question\"' to analyze a specific market"
echo ""

# Quick assessment prompts
echo "🎯 Quick Assessment Questions:"
echo "  - Which outcomes is the market underpricing?"
echo "  - What information does the market not know yet?"  
echo "  - What's your honest estimate vs the market odds?"
echo ""
echo "Remember: Edge = Your Estimate - Market Odds"
echo "Only trade when edge > 5% AND you have real conviction."
