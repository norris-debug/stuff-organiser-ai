# Changelog

Continues from the changelog sections in README.md (v0.1 - v0.5).

## v0.8.14+34 - 2026-11-20

- Removed the "Show my tidy plan" button from Coach's chat: it could appear before any suggestion existed, so tapping it opened an empty plan. Finishing the chat (final Next press, or a reply landing on the last line) auto-flows into the tidy plan page. The Plan tab and its auto-save-after-scan flow are unchanged.

## v0.8.13+33 - 2026-11-20

- Dashboard title spacing: the home "Stuff Organiser" title block sits lower (taller app bar + top padding) so the gap to the screen top matches the Demo mode chip. Badge + version synced.

## v0.8.12+32 - 2026-11-20

- Mascot idle + happy expression variants for all three packs (animals, food, anime) - all 15 mascots. Idle renders byte-identical to the base pack; happy swaps only the mouth shape(s) via override data.

## v0.8.11+31 - 2026-11-20

- Removed the "Paste Recognized List" button from Coach's chat; paste remains as a quiet inline fallback inside the waiting bubble so a scan can't dead-end.
- CI: index-wait step between the Pages artifact upload and deploy, fixing the deploy race that killed runs #120-121.
