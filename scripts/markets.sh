#!/bin/bash
# List and search Polymarket events and markets
# Usage: markets.sh [--trending|--search <query>|--event <slug>] [--limit N]

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/polymarket.sh"

# Defaults
MODE="trending"
QUERY=""
EVENT_SLUG=""
LIMIT=10
FORMAT="table"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --trending)
      MODE="trending"
      shift
      ;;
    --search)
      MODE="search"
      QUERY="$2"
      shift 2
      ;;
    --event)
      MODE="event"
      EVENT_SLUG="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --json)
      FORMAT="json"
      shift
      ;;
    --help|-h)
      echo "Usage: markets.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --trending          List trending events (default)"
      echo "  --search <query>    Search events by title"
      echo "  --event <slug>      Show markets within an event"
      echo "  --limit N           Number of results (default: 10)"
      echo "  --json              Output raw JSON"
      echo ""
      echo "Examples:"
      echo "  markets.sh --trending --limit 5"
      echo "  markets.sh --search \"bitcoin\""
      echo "  markets.sh --event presidential-election-winner-2028"
      exit 0
      ;;
    *)
      # Treat as search query if no flag
      MODE="search"
      QUERY="$1"
      shift
      ;;
  esac
done

# Fetch based on mode
case $MODE in
  trending)
    RESULT=$(polymarket_trending "$LIMIT")
    ;;
  search)
    if [ -z "$QUERY" ]; then
      echo "Error: --search requires a query" >&2
      exit 1
    fi
    RESULT=$(polymarket_search "$QUERY" "$LIMIT")
    ;;
  event)
    if [ -z "$EVENT_SLUG" ]; then
      echo "Error: --event requires an event slug" >&2
      exit 1
    fi
    RESULT=$(polymarket_event_markets "$EVENT_SLUG")
    ;;
esac

# Output
if [ "$FORMAT" = "json" ]; then
  echo "$RESULT"
else
  if [ "$MODE" = "event" ]; then
    # Event markets table
    echo "$RESULT" | jq -r '
      ["ODDS", "VOLUME", "QUESTION"],
      ["----", "------", "--------"],
      (.[] | [
        ((.odds_yes * 100 | floor | tostring) + "%"),
        (if .volume == null then "N/A"
         elif .volume > 1000000 then ((.volume / 1000000 * 10 | floor / 10 | tostring) + "M")
         elif .volume > 1000 then ((.volume / 1000 | floor | tostring) + "K")
         else (.volume | floor | tostring) end),
        (if (.question | length) > 55 then (.question[:52] + "...") else .question end)
      ]) | @tsv
    ' | column -t -s $'\t'
  else
    # Events table
    echo "$RESULT" | jq -r '
      ["VOLUME", "MKTS", "EVENT"],
      ["------", "----", "-----"],
      (.[] | [
        (if .volume > 1000000000 then ((.volume / 1000000000 * 10 | floor / 10 | tostring) + "B")
         elif .volume > 1000000 then ((.volume / 1000000 * 10 | floor / 10 | tostring) + "M")
         elif .volume > 1000 then ((.volume / 1000 | floor | tostring) + "K")
         else (.volume | floor | tostring) end),
        (.num_markets | tostring),
        (if (.title | length) > 50 then (.title[:47] + "...") else .title end)
      ]) | @tsv
    ' | column -t -s $'\t'
  fi
fi
