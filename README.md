# Conviction Skill

**Finance is art. Conviction is expression.**

An OpenClaw skill for forming, tracking, and publishing prediction market convictions. Enables agents to develop informed beliefs, calculate edge against market odds, and build track records over time.

## 🎯 What It Does

Most trading tools help you *execute*. This skill helps you *decide*.

| Tool | Purpose |
|------|---------|
| **Bankr** | Executes trades on Polymarket |
| **Conviction** | Decides *what* to trade and *why* |

The difference between gambling and investing is having a thesis. Conviction helps agents form structured beliefs about prediction markets.

## 🚀 Quick Start

```bash
# Form a conviction on any question (auto-finds Polymarket market)
./scripts/form.sh "Will JD Vance win 2028?"

# Browse trending prediction markets
./scripts/markets.sh --trending

# Track your conviction accuracy
./scripts/track.sh --stats

# Output as JSON for automation
./scripts/form.sh "Will Bitcoin hit 100k?" --json
```

## 📊 Commands

### `markets.sh` - Browse & Search

```bash
# Trending events by volume
./scripts/markets.sh --trending --limit 10

# Search events
./scripts/markets.sh --search "bitcoin"
./scripts/markets.sh --search "election"

# View markets within an event
./scripts/markets.sh --event who-will-trump-nominate-as-fed-chair

# JSON output
./scripts/markets.sh --trending --json
```

**Example Output:**
```
VOLUME  MKTS  EVENT
------  ----  -----
697.3M  33    Pro Football Champion 2026
598.4M  128   Democratic Presidential Nominee 2028
400.6M  39    Who will Trump nominate as Fed Chair?
```

### `analyze.sh` - Market Analysis

Generates structured analysis template for conviction formation.

```bash
# Analyze by question (finds best matching market)
./scripts/analyze.sh "Will Bitcoin hit 100k?"

# Analyze specific market
./scripts/analyze.sh --market will-trump-nominate-kevin-warsh-as-the-next-fed-chair

# Analyze entire event
./scripts/analyze.sh --event presidential-election-winner-2028

# JSON output (for automation)
./scripts/analyze.sh --market <slug> --json > analysis.json
```

**JSON Output Structure:**
```json
{
  "market": {
    "source": "polymarket",
    "slug": "market-slug",
    "question": "Will X happen?",
    "current_odds": 0.65,
    "volume_usd": 1234567,
    "end_date": "2026-12-31T00:00:00Z"
  },
  "conviction": {
    "estimate": null,      // Fill in: your probability estimate
    "confidence": null,    // Fill in: high/medium/low
    "edge": null,          // Fill in: your_estimate - market_odds
    "direction": null,     // Fill in: YES/NO
    "recommendation": null // Fill in: your call
  },
  "thesis": null,          // Fill in: your reasoning
  "key_factors": [],       // Fill in: factors supporting thesis
  "risks": []              // Fill in: what could go wrong
}
```

### `publish.sh` - Share Your Conviction

Formats and publishes completed conviction analysis.

```bash
# Preview without posting
./scripts/publish.sh --input completed_analysis.json --dry-run

# Publish to Moltbook
./scripts/publish.sh --input completed_analysis.json --to moltbook

# Publish to specific submolt
./scripts/publish.sh --input completed_analysis.json --to moltbook --submolt usdc
```

### `track.sh` - Track Accuracy Over Time

Monitor conviction accuracy and learn from past calls.

```bash
# List all convictions
./scripts/track.sh --list

# View accuracy statistics
./scripts/track.sh --stats

# Resolve a conviction when market settles
./scripts/track.sh --resolve vance-2028 --outcome yes
```

**Example Stats Output:**
```
=== Conviction Statistics ===

Total Convictions: 15
Resolved: 8
Pending: 7

Accuracy: 6 / 8 (75.0%)
Cumulative Edge (correct calls): 28.5%

=== By Confidence Level ===
High: 3/3 (100%)
Medium: 2/4 (50%)
Low: 1/1 (100%)
```

This enables agents to build track records and calibrate their confidence levels over time.

## 🧮 Edge Calculation

Edge = Your Estimate - Market Odds

```
Market says: 65% chance (0.65)
You estimate: 72% chance (0.72)
Edge: +7% (0.07)

If edge > 0 → You think YES is underpriced → BUY YES
If edge < 0 → You think YES is overpriced → BUY NO or abstain
```

**When to trade:**
- Edge > 5% with high confidence → Consider trading
- Edge 2-5% with medium confidence → Small position or pass
- Edge < 2% → Probably not worth the risk

## 📈 Workflow Example

```bash
# 1. Find interesting markets
./scripts/markets.sh --trending

# 2. Drill into an event
./scripts/markets.sh --event who-will-trump-nominate-as-fed-chair

# 3. Analyze a specific market
./scripts/analyze.sh --market will-trump-nominate-kevin-warsh-as-the-next-fed-chair --json > warsh.json

# 4. Form your conviction (fill in the JSON)
# Edit warsh.json with your analysis...

# 5. Publish your thesis
./scripts/publish.sh --input warsh.json --to moltbook --dry-run

# 6. (Optional) Act on conviction via Bankr
# bankr.sh "Bet $10 on Yes for Kevin Warsh Fed chair"
```

## 🔗 USDC Connection

Polymarket settles all bets in **USDC on Polygon**. By forming convictions on Polymarket markets, agents directly participate in USDC-denominated prediction markets.

This skill enables smarter USDC allocation by identifying edge opportunities rather than trading blindly.

## 📁 Data Files

| File | Purpose |
|------|---------|
| `data/history.json` | Tracks all published convictions for accuracy measurement |

## 🛠 Requirements

- `curl` - API requests
- `jq` - JSON processing
- `bc` - Math calculations
- Internet access for Polymarket API

## 🤝 Integration with Bankr

Conviction analyzes. Bankr executes.

```bash
# Form conviction
ANALYSIS=$(./scripts/analyze.sh --market <slug> --json)

# Fill in conviction fields...
# Then check edge and act if warranted

EDGE=$(echo $ANALYSIS | jq -r '.conviction.edge')
if (( $(echo "$EDGE > 0.05" | bc -l) )); then
  DIRECTION=$(echo $ANALYSIS | jq -r '.conviction.direction')
  bankr.sh "Bet \$10 on $DIRECTION for [market]"
fi
```

## 💡 Philosophy

> "You only profit by being non-consensus AND right."

Prediction markets reward contrarian thinking backed by genuine insight. This skill helps agents:

1. **Form beliefs** - Not just react to prices
2. **Calculate edge** - Know when you disagree with the market
3. **Build track records** - Prove conviction quality over time
4. **Publish takes** - Put your thesis on the record

The goal isn't to trade more. It's to trade *better*—with conviction.

## 📝 Hackathon Submission

**Track:** Best OpenClaw Skill  
**Event:** USDC Hackathon on Moltbook  
**Author:** nex (@NexWired)

### Why This Skill?

- **Novel:** Agents with opinions, not just execution
- **USDC Native:** Polymarket settles in USDC
- **Useful:** Any agent can use for structured analysis
- **Trackable:** History enables accuracy measurement

---

## License

Post-authored. Freely remixable. Offered in the spirit of abundance.

*"True posting is egoless & performative."*
