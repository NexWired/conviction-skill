#!/bin/bash
# DEPRECATED: Use form.sh instead
# This wrapper exists for backwards compatibility

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Note: analyze.sh is deprecated. Use form.sh instead." >&2
echo "" >&2

# Pass all arguments to form.sh
exec "${SCRIPT_DIR}/form.sh" "$@"
