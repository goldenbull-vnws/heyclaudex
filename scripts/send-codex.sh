#!/usr/bin/env bash
# Sends one minimal-token wake prompt to Codex to anchor a fresh 5-hour
# usage window at the moment this script runs. Requires ~/.codex/auth.json
# to already hold a valid session (restored from CODEX_AUTH_JSON).
#
# IMPORTANT: must use a model that actually registers on the account's 5-hour
# meter. "mini" models bill a separate bucket and never start a window, even
# though the send succeeds and returns a reply — see README FAQ.
set -euo pipefail

MODEL="${HEYCLAUDEX_CODEX_MODEL:-gpt-5.6-sol}"
EFFORT="${HEYCLAUDEX_CODEX_REASONING_EFFORT:-low}"

for attempt in 1 2 3; do
  if codex exec --skip-git-repo-check -m "$MODEL" \
      -c model_reasoning_effort="$EFFORT" "Hey Codex"; then
    exit 0
  fi
  echo "Attempt $attempt failed, retrying in 10s..." >&2
  sleep 10
done

echo "All 3 attempts failed." >&2
exit 1
