#!/usr/bin/env bash
# Verify the redirect hub. Run after each domain's DNS is pointed at Netlify.
#
#   ./verify.sh              check every mapped URL
#   ./verify.sh labastida    check only URLs matching a string
#
# Expect: 301 → a destination on viralgeniusinstitute.com
# Before DNS is moved, a domain will show its CURRENT live site (200) — that is
# not a failure, it just means that domain has not been pointed here yet.

set -uo pipefail
FILTER="${1:-}"

URLS=(
  # viralgeniusframework.com — the one that matters most
  "https://viralgeniusframework.com/"
  "https://viralgeniusframework.com/the-viral-genius-framework/"
  "https://viralgeniusframework.com/about-fernando-labastida/"
  "https://viralgeniusframework.com/offerings/"
  "https://viralgeniusframework.com/podcast/"
  "https://viralgeniusframework.com/some-page-that-never-existed"

  # labastida.com
  "https://labastida.com/"
  "https://labastida.com/about/"
  "https://labastida.com/services/"
  "https://labastida.com/fernandos-portfolio/"
  "https://labastida.com/turn-your-business-into-digital-business-ccreate-framework/"

  # getstartupbook.com
  "https://getstartupbook.com/"
  "https://getstartupbook.com/about/"
  "https://getstartupbook.com/resources/"
  "https://getstartupbook.com/stop-being-a-commodity-provider-start-being-a-category-king-or-queen/"
  "https://getstartupbook.com/commodity-power-imbalance/"
  "https://getstartupbook.com/webinar-the-4d-book-method/"

  # strikemarketinginstitute.com
  "https://strikemarketinginstitute.com/"

  # aimarketingcasestudies.com — last
  "https://aimarketingcasestudies.com/"
)

printf "%-92s %-6s %s\n" "URL" "CODE" "DESTINATION"
printf '%.0s─' {1..150}; echo

fail=0
for u in "${URLS[@]}"; do
  [[ -n "$FILTER" && "$u" != *"$FILTER"* ]] && continue
  read -r code dest < <(curl -sS -o /dev/null --max-time 15 \
      -w "%{http_code} %{redirect_url}" "$u" 2>/dev/null || echo "ERR -")
  [[ -z "${dest:-}" ]] && dest="—"
  mark=""
  if [[ "$code" == "301" && "$dest" == *"viralgeniusinstitute.com"* ]]; then
    mark="✅"
  else
    mark="⏳"; fail=$((fail+1))
  fi
  printf "%-92s %-6s %s %s\n" "${u:0:92}" "$code" "$mark" "$dest"
done

echo
if [[ $fail -eq 0 ]]; then
  echo "✅ All checked URLs 301 to viralgeniusinstitute.com."
else
  echo "⏳ $fail URL(s) not yet redirecting — expected until that domain's DNS is pointed at Netlify."
fi

echo
echo "MX safety check (these must NOT change):"
for d in aimarketingcasestudies.com viralgeniusframework.com; do
  printf "  %-32s %s\n" "$d" "$(dig MX "$d" +short | tr '\n' ' ')"
done
