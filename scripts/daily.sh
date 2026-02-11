#!/bin/bash
# daily.sh — Morning conviction check
# Combines portfolio, price alerts, and market scan into one view

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "☀️ Daily Conviction Check"
echo "========================="
echo "$(date '+%Y-%m-%d %H:%M %Z')"
echo ""

# 1. Key prices
echo "📈 Key Prices"
echo "-------------"
PRICES=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=ethereum,bitcoin,solana&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)

if [ -n "$PRICES" ]; then
  ETH=$(echo "$PRICES" | jq -r '.ethereum.usd')
  ETH_CHG=$(echo "$PRICES" | jq -r '.ethereum.usd_24h_change' | xargs printf "%.1f")
  BTC=$(echo "$PRICES" | jq -r '.bitcoin.usd')
  BTC_CHG=$(echo "$PRICES" | jq -r '.bitcoin.usd_24h_change' | xargs printf "%.1f")
  SOL=$(echo "$PRICES" | jq -r '.solana.usd')
  SOL_CHG=$(echo "$PRICES" | jq -r '.solana.usd_24h_change' | xargs printf "%.1f")
  
  printf "ETH: \$%-8s (%+.1f%%)\n" "$ETH" "$ETH_CHG"
  printf "BTC: \$%-8s (%+.1f%%)\n" "$BTC" "$BTC_CHG"  
  printf "SOL: \$%-8s (%+.1f%%)\n" "$SOL" "$SOL_CHG"
else
  echo "⚠️ Could not fetch prices"
fi
echo ""

# 2. Market sentiment
echo "🌡️ Market Sentiment"
echo "-------------------"
if (( $(echo "${ETH_CHG:-0} < -3" | bc -l 2>/dev/null) )); then
  echo "📉 ETH down significantly — potential buy opportunity?"
elif (( $(echo "${ETH_CHG:-0} > 3" | bc -l 2>/dev/null) )); then
  echo "📈 ETH up significantly — momentum or overextended?"
else
  echo "➡️ ETH relatively flat — wait for clearer signal"
fi
echo ""

# 3. Trending markets
echo "🎯 High-Volume Polymarket Events"
echo "---------------------------------"
EVENTS=$(curl -s "https://gamma-api.polymarket.com/events?closed=false&limit=5" 2>/dev/null)
if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | jq -r '.[] | "• \(.title) ($\(.volume | tonumber / 1000000 | floor)M)"' 2>/dev/null | head -5
else
  echo "⚠️ Could not fetch markets"
fi
echo ""

# 4. Action items
echo "📋 Today's Questions"
echo "--------------------"
echo "1. Any markets I have conviction on?"
echo "2. Should I adjust existing positions?"
echo "3. What's the highest-edge opportunity?"
echo ""
echo "Use './scripts/form.sh \"question\"' to analyze a specific market."
echo "Use './scripts/edge.sh <market> <estimate>' for quick edge calc."
