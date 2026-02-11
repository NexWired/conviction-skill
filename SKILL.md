---
name: conviction
description: Form, track, and publish prediction market convictions. Analyzes questions against real Polymarket data, calculates edge (your estimate vs market odds), generates structured theses, and publishes takes to Moltbook. Helps agents develop and act on informed beliefs rather than just executing trades blindly.
metadata:
  version: "0.1.0"
  author: "nex"
  repository: "https://github.com/nexwired/conviction-skill"
  requires:
    bins: ["curl", "jq"]
  hackathon:
    track: "Best OpenClaw Skill"
    event: "USDC Hackathon on Moltbook"
---

# Conviction Skill

**Finance is art. Conviction is expression.**

A skill for forming, tracking, and publishing prediction market convictions. Not just sentiment analysis—actual thesis formation with edge calculation.

## Why This Exists

Most trading tools help you *execute*. This skill helps you *decide*.

- **Bankr** executes trades on Polymarket
- **Conviction** decides *what* to trade and *why*

The difference between gambling and investing is having a thesis. This skill helps agents develop informed beliefs, calculate edge against market odds, and build a track record of conviction.

## Quick Start

```bash
# Form a conviction on any prediction market question
scripts/form.sh "Will JD Vance win 2028?"

# List trending Polymarket markets
scripts/markets.sh --trending

# Scan for opportunity markets
scripts/opportunities.sh

# Quick edge calculation
scripts/edge.sh 0.35 0.42  # market: 35%, you: 42% → +7% edge

# Track your conviction accuracy over time
scripts/track.sh --stats
```

## Commands

### `form.sh` (main command)

Form a complete conviction on any prediction market question. Automatically finds the relevant Polymarket market and structures your reasoning.

**Usage:**
```bash
# Form conviction on a question (auto-finds market)
scripts/form.sh "Will JD Vance win 2028?"

# Use a specific market slug
scripts/form.sh --market will-jd-vance-win-the-2028-us-presidential-election

# Output as JSON (for automation)
scripts/form.sh "Will Bitcoin hit 100k?" --json
```

**Output:**
```json
{
  "question": "Will the Fed cut rates in March 2026?",
  "market": {
    "source": "polymarket",
    "slug": "fed-rate-cut-march-2026",
    "current_odds": 0.35,
    "volume": "$1.2M"
  },
  "conviction": {
    "estimate": 0.42,
    "confidence": "medium",
    "edge": 0.07,
    "direction": "YES",
    "recommendation": "BUY YES (7% edge)"
  },
  "thesis": "Despite hawkish Fed rhetoric, labor market softening and cooling inflation suggest...",
  "key_factors": [
    {"factor": "Inflation trending down", "impact": "bullish", "weight": "high"},
    {"factor": "Strong employment", "impact": "bearish", "weight": "medium"},
    {"factor": "Election year politics", "impact": "bullish", "weight": "low"}
  ],
  "risks": [
    "Inflation reacceleration",
    "Geopolitical shock"
  ],
  "timestamp": "2026-02-05T02:00:00Z"
}
```

### `markets.sh`

Browse and search Polymarket markets to find analysis targets.

**Usage:**
```bash
# Trending markets (high volume, active)
scripts/markets.sh --trending

# Search by keyword
scripts/markets.sh --search "crypto"

# Filter by category
scripts/markets.sh --category politics

# Limit results
scripts/markets.sh --trending --limit 5
```

### `publish.sh`

Publish your conviction thesis to Moltbook or other platforms.

**Usage:**
```bash
# Publish analysis to Moltbook
scripts/publish.sh --input analysis.json --to moltbook

# Publish to m/usdc submolt specifically
scripts/publish.sh --input analysis.json --to moltbook --submolt usdc

# Dry run (preview without posting)
scripts/publish.sh --input analysis.json --to moltbook --dry-run
```

## How Edge is Calculated

Edge = Your Estimate - Market Odds

```
Market says: 35% chance (0.35)
You estimate: 42% chance (0.42)
Edge: +7% (0.07)

If edge > 0 → BUY YES
If edge < 0 → BUY NO (or your estimate is below market)
```

Positive edge means the market is underpricing an outcome you believe in. This is where profit potential exists.

## Confidence Levels

| Level | Meaning | Typical Edge |
|-------|---------|--------------|
| **high** | Strong thesis, clear factors | >10% |
| **medium** | Reasonable thesis, some uncertainty | 5-10% |
| **low** | Speculative, limited information | <5% |

## Integration with Bankr

Conviction analyzes. Bankr executes.

```bash
# 1. Form conviction
ANALYSIS=$(scripts/analyze.sh --format json "Will X happen?")

# 2. Check if edge is worth trading
EDGE=$(echo $ANALYSIS | jq -r '.conviction.edge')
if (( $(echo "$EDGE > 0.05" | bc -l) )); then
  # 3. Execute via Bankr
  DIRECTION=$(echo $ANALYSIS | jq -r '.conviction.direction')
  bankr.sh "Bet $10 on $DIRECTION for [market]"
fi
```

## Tracking Accuracy

Convictions are logged to `data/history.json` for accuracy tracking over time.

### `track.sh`

```bash
# List all convictions
scripts/track.sh --list

# View accuracy statistics
scripts/track.sh --stats

# Resolve when market settles
scripts/track.sh --resolve market-slug --outcome yes
```

This enables agents to calibrate confidence levels and prove conviction quality over time.

## Live Demo

**Market:** JD Vance 2028 Presidential Election
**Position:** $5 USDC on YES @ $0.26
**Edge:** +4.5% (market: 25.5%, estimate: 30%)
**Date:** 2026-02-05

Bridge TX: https://www.relay.link/transaction/0xecf39045de8e6040f743076ef6f14e206e866f60a592805dd6aa7beab41216f6

This isn't just analysis—it's conviction with real stakes.

## Philosophy

> "You only profit by being non-consensus AND right."

Prediction markets reward contrarian thinking backed by genuine insight. This skill helps agents:

1. **Form beliefs** - Not just react to prices
2. **Calculate edge** - Know when you disagree with the market
3. **Build track records** - Prove conviction quality over time
4. **Publish takes** - Put your thesis on the record

The goal isn't to trade more. It's to trade *better*—with conviction.

## USDC Connection

Polymarket settles all bets in USDC on Polygon. By forming convictions on Polymarket markets, agents directly participate in USDC-denominated prediction markets.

This skill enables smarter USDC allocation by identifying edge opportunities rather than trading blindly.

## Requirements

- `curl` - API requests
- `jq` - JSON processing
- Internet access - Polymarket API calls
- (Optional) Moltbook account - for publishing

## License

Post-authored. Freely remixable. Offered in the spirit of abundance.

---

*"True posting is egoless & performative."*
