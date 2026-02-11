#!/bin/bash
# edge.sh — Quick edge calculator for Polymarket positions
# Usage: ./edge.sh <market_odds> <your_estimate>
# Example: ./edge.sh 0.35 0.42  (market: 35%, you: 42%)

set -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 <market_odds> <your_estimate>"
  echo ""
  echo "Example: $0 0.35 0.42"
  echo "  Market says: 35% chance"
  echo "  You estimate: 42% chance"
  echo "  Edge: +7%"
  echo ""
  echo "Enter odds as decimals (0.35 = 35%)"
  exit 1
fi

MARKET=$1
ESTIMATE=$2

# Calculate edge
EDGE=$(echo "$ESTIMATE - $MARKET" | bc -l)
EDGE_PCT=$(echo "$EDGE * 100" | bc -l | xargs printf "%.1f")
MARKET_PCT=$(echo "$MARKET * 100" | bc -l | xargs printf "%.1f")
ESTIMATE_PCT=$(echo "$ESTIMATE * 100" | bc -l | xargs printf "%.1f")

echo ""
echo "📊 Edge Calculation"
echo "==================="
echo "Market odds:    ${MARKET_PCT}%"
echo "Your estimate:  ${ESTIMATE_PCT}%"
echo ""

# Determine direction and recommendation
if (( $(echo "$EDGE > 0" | bc -l) )); then
  DIRECTION="YES"
  echo "📈 Edge: +${EDGE_PCT}% (BUY $DIRECTION)"
else
  DIRECTION="NO"
  ABS_EDGE=$(echo "$EDGE * -1" | bc -l | xargs printf "%.1f")
  echo "📉 Edge: -${ABS_EDGE}% (market overpricing YES)"
fi

echo ""

# Recommendation based on edge size
ABS_EDGE=$(echo "if ($EDGE < 0) -1*$EDGE else $EDGE" | bc -l)

if (( $(echo "$ABS_EDGE >= 0.10" | bc -l) )); then
  echo "✅ STRONG EDGE (≥10%) — Consider larger position if confident"
elif (( $(echo "$ABS_EDGE >= 0.05" | bc -l) )); then
  echo "⚠️  MODERATE EDGE (5-10%) — Worth trading if thesis is solid"
elif (( $(echo "$ABS_EDGE >= 0.02" | bc -l) )); then
  echo "🔸 SMALL EDGE (2-5%) — Marginal, only trade with high conviction"
else
  echo "❌ MINIMAL EDGE (<2%) — Not worth the risk/fees"
fi

echo ""
echo "Remember: You only profit by being non-consensus AND right."
