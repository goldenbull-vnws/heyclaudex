#!/usr/bin/env bash
# Sends one minimal-token wake prompt to Claude to anchor a fresh 5-hour
# usage window at the moment this script runs. Requires CLAUDE_CODE_OAUTH_TOKEN
# in the environment (from `claude setup-token`).
set -euo pipefail

MODEL="${HEYCLAUDEX_CLAUDE_MODEL:-claude-haiku-4-5-20251001}"

for attempt in 1 2 3; do
  if claude -p "Hey Claude" --model "$MODEL"; then
    exit 0
  fi
  echo "Attempt $attempt failed, retrying in 10s..." >&2
  sleep 10
done

echo "All 3 attempts failed." >&2
exit 1
