#!/bin/bash
# Polymarket API helper functions
# No authentication required for read operations

GAMMA_API="https://gamma-api.polymarket.com"
CLOB_API="https://clob.polymarket.com"

# Fetch trending/active events
polymarket_trending() {
  local limit="${1:-10}"
  curl -s "${GAMMA_API}/events?limit=${limit}&active=true&closed=false&order=volume&ascending=false" | \
    jq '[.[] | {
      id: .id,
      slug: .slug,
      title: .title,
      volume: .volume,
      end_date: .endDate,
      category: .category,
      num_markets: (.markets | length)
    }]'
}

# Search events by title
polymarket_search() {
  local query="$1"
  local limit="${2:-10}"
  local encoded_query=$(echo -n "$query" | jq -sRr @uri)
  curl -s "${GAMMA_API}/events?limit=${limit}&active=true&closed=false&title_contains=${encoded_query}" | \
    jq '[.[] | {
      id: .id,
      slug: .slug,
      title: .title,
      volume: .volume,
      end_date: .endDate,
      category: .category,
      num_markets: (.markets | length)
    }]'
}

# Get event with all its markets and odds
polymarket_get_event() {
  local slug="$1"
  curl -s "${GAMMA_API}/events?slug=${slug}&limit=1" | \
    jq '.[0] // {} | {
      id: .id,
      slug: .slug,
      title: .title,
      description: .description,
      volume: .volume,
      end_date: .endDate,
      category: .category,
      markets: [.markets[]? | {
        id: .id,
        question: .question,
        slug: .slug,
        odds_yes: (if .outcomePrices then (.outcomePrices | fromjson)[0] | tonumber else null end),
        odds_no: (if .outcomePrices then (.outcomePrices | fromjson)[1] | tonumber else null end),
        volume: .volumeNum,
        outcomes: (if .outcomes then .outcomes | fromjson else ["Yes", "No"] end)
      }]
    }'
}

# Get a specific market by its slug
polymarket_get_market() {
  local slug="$1"
  curl -s "${GAMMA_API}/markets?slug=${slug}&limit=1" | \
    jq '.[0] // {} | {
      id: .id,
      slug: .slug,
      question: .question,
      description: .description,
      odds_yes: (if .outcomePrices then (.outcomePrices | fromjson)[0] | tonumber else null end),
      odds_no: (if .outcomePrices then (.outcomePrices | fromjson)[1] | tonumber else null end),
      volume: .volumeNum,
      end_date: .endDate,
      outcomes: (if .outcomes then .outcomes | fromjson else ["Yes", "No"] end)
    }'
}

# Smart get - tries event first, then market
polymarket_get() {
  local identifier="$1"
  # Try as event first
  local result=$(polymarket_get_event "$identifier")
  if [ "$(echo "$result" | jq -r '.id // empty')" != "" ]; then
    echo "$result"
    return
  fi
  # Try as market
  result=$(polymarket_get_market "$identifier")
  echo "$result"
}

# Find best matching market for a question (searches events and their markets)
polymarket_find_match() {
  local question="$1"
  
  # Extract the most distinctive keyword (longest word that's not common)
  local keyword=$(echo "$question" | tr '[:upper:]' '[:lower:]' | \
    sed 's/will//g; s/the//g; s/[?]//g; s/win//g; s/2028//g; s/2026//g; s/2025//g' | \
    tr ' ' '\n' | awk 'length >= 4 {print length, $0}' | sort -rn | head -1 | awk '{print $2}')
  
  # If no good keyword found, try first word
  if [ -z "$keyword" ]; then
    keyword=$(echo "$question" | tr '[:upper:]' '[:lower:]' | sed 's/will //g; s/the //g; s/[?]//g' | awk '{print $1}')
  fi
  
  # Simple search - find markets containing this keyword, prefer unsettled markets
  curl -s "${GAMMA_API}/events?limit=100&active=true&closed=false&order=volume&ascending=false" | \
    jq --arg k "$keyword" '
      [.[] | .markets[]? | 
        select(.question != null) | 
        select(.question | ascii_downcase | contains($k)) |
        (.outcomePrices | if . then (fromjson | .[0] | tonumber) else null end) as $odds |
        select($odds != null and $odds > 0.01 and $odds < 0.99) |
        {id: .id, slug: .slug, question: .question, odds_yes: $odds, volume: (.volumeNum // 0), end_date: .endDate}
      ] | sort_by(-.volume) | .[0] // {}'
}

# List markets in an event
polymarket_event_markets() {
  local event_slug="$1"
  polymarket_get_event "$event_slug" | jq '[.markets[] | select(.odds_yes != null) | {
    question: .question,
    slug: .slug,
    odds_yes: .odds_yes,
    volume: .volume
  }] | sort_by(-.odds_yes)'
}
