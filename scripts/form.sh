#!/bin/bash
# Form a complete conviction on a prediction market question
# Usage: form.sh <question> [--market <slug>] [--research] [--json]
#
# This is the main command for conviction formation. It:
# 1. Finds the relevant Polymarket market
# 2. Gathers research context (optional)
# 3. Structures everything for agent reasoning
# 4. Outputs a conviction template ready for completion

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/polymarket.sh" 2>/dev/null || true

# Defaults
QUESTION=""
MARKET_SLUG=""
DO_RESEARCH=false
JSON_OUTPUT=false
SEARCH_RESULTS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --market|-m)
      MARKET_SLUG="$2"
      shift 2
      ;;
    --research|-r)
      DO_RESEARCH=true
      shift
      ;;
    --json|-j)
      JSON_OUTPUT=true
      shift
      ;;
    --search-context)
      # Hidden flag: pass in pre-gathered search results
      SEARCH_RESULTS="$2"
      shift 2
      ;;
    --help|-h)
      cat << 'EOF'
Usage: form.sh <question> [OPTIONS]

Form a complete conviction on a prediction market question.

This command orchestrates the full conviction formation workflow:
1. Find matching Polymarket market (or use --market)
2. Fetch current odds, volume, liquidity
3. Optionally gather research context (--research)
4. Structure everything for agent reasoning
5. Output template for agent to complete

The agent fills in:
- Probability estimate (your belief)
- Confidence level (high/medium/low)
- Thesis (your reasoning)
- Key factors and risks

Options:
  --market, -m <slug>   Use specific Polymarket market slug
  --research, -r        Gather web context (requires web_search)
  --json, -j            Output as JSON (default: human-readable)

Examples:
  form.sh "Will Bitcoin hit 100k in 2026?"
  form.sh --market bitcoin-100k-2026 --research --json
  form.sh "Fed rate cut March?" --research

Philosophy:
  The skill gathers data and structures reasoning.
  The agent makes the final probability judgment.
  This is the right division of labor.
EOF
      exit 0
      ;;
    *)
      if [ -z "$QUESTION" ]; then
        QUESTION="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$QUESTION" ] && [ -z "$MARKET_SLUG" ]; then
  echo "Error: Question or --market required" >&2
  exit 1
fi

# Step 1: Find or fetch the market
if [ -n "$MARKET_SLUG" ]; then
  # Direct market lookup
  MARKET_DATA=$(polymarket_get_market "$MARKET_SLUG" 2>/dev/null || echo "{}")
else
  # Search for matching market  
  MARKET_DATA=$(polymarket_find_match "$QUESTION" 2>/dev/null || echo "{}")
fi

# Extract market info (with fallbacks for missing data)
MARKET_ID=$(echo "$MARKET_DATA" | jq -r '.id // empty' 2>/dev/null)

if [ -n "$MARKET_ID" ] && [ "$MARKET_ID" != "null" ]; then
  MARKET_QUESTION=$(echo "$MARKET_DATA" | jq -r '.question // "Unknown"' 2>/dev/null || echo "$QUESTION")
  MARKET_SLUG=$(echo "$MARKET_DATA" | jq -r '.slug // "unknown"' 2>/dev/null || echo "unknown")
  CURRENT_ODDS=$(echo "$MARKET_DATA" | jq -r '.odds_yes // 0.50' 2>/dev/null || echo "0.50")
  VOLUME=$(echo "$MARKET_DATA" | jq -r '.volume // 0' 2>/dev/null || echo "0")
  LIQUIDITY=$(echo "$MARKET_DATA" | jq -r '.liquidity // 0' 2>/dev/null || echo "0")
  END_DATE=$(echo "$MARKET_DATA" | jq -r '.end_date // "unknown"' 2>/dev/null || echo "unknown")
else
  # No market found - create template anyway
  MARKET_QUESTION="$QUESTION"
  MARKET_SLUG="manual-entry"
  CURRENT_ODDS="0.50"
  VOLUME="0"
  LIQUIDITY="0"
  END_DATE="unknown"
fi

# Clean up odds to be a decimal
CURRENT_ODDS=$(echo "$CURRENT_ODDS" | sed 's/[^0-9.]//g')
if [ -z "$CURRENT_ODDS" ] || [ "$CURRENT_ODDS" = "." ]; then
  CURRENT_ODDS="0.50"
fi

# Step 2: Research context (if requested)
RESEARCH_JSON="null"
if [ "$DO_RESEARCH" = true ]; then
  RESEARCH_JSON=$("${SCRIPT_DIR}/research.sh" "$QUESTION" --json 2>/dev/null || echo "null")
fi

# Step 3: Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Step 4: Output the conviction template
if [ "$JSON_OUTPUT" = true ]; then
  cat << EOF
{
  "_meta": {
    "skill": "conviction",
    "version": "0.2.0",
    "generated": "$TIMESTAMP",
    "status": "draft"
  },
  "question": "$(echo "$QUESTION" | sed 's/"/\\"/g')",
  "market": {
    "source": "polymarket",
    "slug": "$MARKET_SLUG",
    "question": "$(echo "$MARKET_QUESTION" | sed 's/"/\\"/g')",
    "current_odds": $CURRENT_ODDS,
    "volume_usd": $VOLUME,
    "liquidity_usd": $LIQUIDITY,
    "end_date": "$END_DATE",
    "url": "https://polymarket.com/event/$MARKET_SLUG"
  },
  "research": $RESEARCH_JSON,
  "conviction": {
    "estimate": null,
    "confidence": null,
    "edge": null,
    "direction": null,
    "thesis": null,
    "recommendation": null
  },
  "reasoning": {
    "key_factors": [
      {
        "factor": null,
        "impact": null,
        "weight": null,
        "source": null
      }
    ],
    "risks": [],
    "assumptions": [],
    "edge_sources": []
  },
  "action": {
    "recommended_position": null,
    "position_size_pct": null,
    "entry_price": $CURRENT_ODDS,
    "target_exit": null,
    "stop_loss": null
  }
}
EOF

else
  # Human-readable output
  cat << EOF
════════════════════════════════════════════════════════════════
                    CONVICTION FORMATION
════════════════════════════════════════════════════════════════

QUESTION: $QUESTION

────────────────────────────────────────────────────────────────
MARKET DATA
────────────────────────────────────────────────────────────────
Source:       Polymarket
Market:       $MARKET_QUESTION
Current Odds: $(echo "$CURRENT_ODDS * 100" | bc 2>/dev/null || echo "$CURRENT_ODDS")% YES
Volume:       \$$(printf "%'d" ${VOLUME%.*} 2>/dev/null || echo "$VOLUME")
End Date:     $END_DATE
URL:          https://polymarket.com/event/$MARKET_SLUG

────────────────────────────────────────────────────────────────
YOUR CONVICTION (fill in)
────────────────────────────────────────────────────────────────
Your Estimate:    ___% (your probability for YES)
Confidence:       ___ (high / medium / low)
Direction:        ___ (YES / NO)

THESIS:
(Write your reasoning here. Why do you believe this?)




────────────────────────────────────────────────────────────────
KEY FACTORS (list 3-5)
────────────────────────────────────────────────────────────────
Factor                          Impact      Weight
─────────────────────────────────────────────────────────────
1. ________________________    bullish/bearish   high/med/low
2. ________________________    bullish/bearish   high/med/low
3. ________________________    bullish/bearish   high/med/low

────────────────────────────────────────────────────────────────
RISKS (what could make you wrong?)
────────────────────────────────────────────────────────────────
1. 
2. 
3. 

────────────────────────────────────────────────────────────────
EDGE CALCULATION
────────────────────────────────────────────────────────────────
Market Odds:      $(echo "$CURRENT_ODDS * 100" | bc 2>/dev/null || echo "$CURRENT_ODDS")%
Your Estimate:    ___%
Edge:             ___% (estimate - market)

If edge > +5%  → Consider BUY YES
If edge < -5%  → Consider BUY NO
If |edge| < 5% → Probably pass

────────────────────────────────────────────────────────────────
RECOMMENDATION
────────────────────────────────────────────────────────────────
Action:           ___ (BUY YES / BUY NO / PASS)
Position Size:    ___% of bankroll
Rationale:        



════════════════════════════════════════════════════════════════
                    Generated by conviction skill
                    $TIMESTAMP
════════════════════════════════════════════════════════════════
EOF

fi
