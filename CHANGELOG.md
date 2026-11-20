# Changelog

Continues from the changelog sections in README.md (v0.1 - v0.5).

## v0.8.16+36 - 2026-11-20

- Save-at-result-entry: the tidy plan auto-saves the moment the result page opens, so closing the tab can no longer lose suggestions (the back arrow no longer discards - nothing can).
- Venue auto-add: every scan with a venue adds it to "Your spaces"; rescans reuse the existing space. Confirmed and verify recognized objects land as unpacked items on the venue's page; flagged (under 50%) reads stay out by design.
- Empty first run: the demo seed (kitchen mugs and plates, desk paper pile, wardrobe socks) is gone - "Your spaces" and Today's plan start empty and fill from real scans and quick-adds.
- Venue page redesign: tap = select, and a "Finish organizing" bottom button clears the selection (the per-item three-dots delete is gone); "Drop in [venue]" chips open that venue's page on tap.
- Coach attribution: interjections and the notes echo render as coach bubbles, not user bubbles.
- Onboarding double-tap guard (UI flag plus a state-layer backstop); whitespace-only renames rejected in the state layer.
- Corrupt plan stores are reported honestly on the save side and in a Plan tab banner; the next successful save replaces the bad data.
- Dashboard badge derives from package metadata (package_info_plus) - no more manual syncs.
- Docs: photo count (six per scan), mess-scaling behavior, Settings About, PWA manifest name/description, page title.

## v0.8.14+34 - 2026-11-20

- Removed the "Show my tidy plan" button from Coach's chat: it could appear before any suggestion existed, so tapping it opened an empty plan. Finishing the chat (final Next press, or a reply landing on the last line) auto-flows into the tidy plan page. The Plan tab and its auto-save-after-scan flow are unchanged.

## v0.8.13+33 - 2026-11-20

- Dashboard title spacing: the home "Stuff Organiser" title block sits lower (taller app bar + top padding) so the gap to the screen top matches the Demo mode chip. Badge + version synced.

## v0.8.12+32 - 2026-11-20

- Mascot idle + happy expression variants for all three packs (animals, food, anime) - all 15 mascots. Idle renders byte-identical to the base pack; happy swaps only the mouth shape(s) via override data.

## v0.8.11+31 - 2026-11-20

- Removed the "Paste Recognized List" button from Coach's chat; paste remains as a quiet inline fallback inside the waiting bubble so a scan can't dead-end.
- CI: index-wait step between the Pages artifact upload and deploy, fixing the deploy race that killed runs #120-121.