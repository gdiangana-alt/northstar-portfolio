#!/usr/bin/env bash
set -euo pipefail

site_url="${SITE_URL:-https://www.guydiangana.com/}"
expected_title="Guy Diangana | Cloud &amp; Identity Security"
expected_marker="Engineering secure infrastructure, trusted identity, and resilient operations."

body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --connect-timeout 10 \
  --max-time 30 \
  --retry 2 \
  --retry-all-errors \
  --output "$body_file" \
  "$site_url"

grep -Fq "$expected_title" "$body_file"
grep -Fq "$expected_marker" "$body_file"

echo "Public availability check passed: $site_url"
