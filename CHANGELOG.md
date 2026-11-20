# Changelog

Continues from the changelog sections in README.md (v0.1 - v0.5).

## v0.8.20+40 - 2026-11-20

- Semantics test mode: opening the web app with ?semantics=1 forces the accessibility/semantics tree on (same deployed build, no separate artifact, CanvasKit untouched) - this is what dynamic walkthrough automation and screen-reader verification need on web, where the tree otherwise only comes up when an assistive technology is detected. CI builds can force the same with --dart-define=FORCE_SEMANTICS=true.
- Manual-attach hint (first live scan gap): the forward flow's labeling now says plainly that browsers cannot attach the photos for you - tap the paperclip in the email window, add the scanned photos in upload order (photo 1 first), then Send. The first live scan package arrived with zero attachments because the step was only implied.

## v0.8.19+39 - 2026-11-20

- Cellulose connection (steward priority): the scan-to-email forward now opens pre-addressed - the web mailto compose carries afantashoon@gmail.com as the recipient, the in-app labeling names the destination (covering the APK share path, which cannot prefill a recipient), and the README documents the lane.
- R3-F1 (QA): the scan save mirrors the Plan tab's cast - a valid-JSON-but-non-List tidy-plan store now reports the honest corrupt banner on both sides instead of being silently overwritten. New widget tests pin the Plan tab's non-List banner and the scan side's no-overwrite guarantee.

## v0.8.18+38 - 2026-11-20

- R2-01 (scan-save race, Firebase mode): the scan's leave-behind save now reads a snapshot of the plan, the recognized list and the venue taken before its first await - a flow reset racing the side effects can no longer turn the save into a silent no-op. Demo mode's window was near-zero; this hardens Firebase mode before that switch flips.
- Functional test gate (Meiosis task-5): widget_test.dart gets real coverage - the dashboard badge derives from package metadata, the Plan tab honors the tidy-plan storage contract (stored parts render, first runs start empty, corrupt stores show the honest banner), the duplicate-space guard reuses case-insensitive matches, and a full scan-flow integration test drives pick -> gallery photos -> pasted recognition -> coach reveal -> result to verify the plan auto-save, the venue auto-add to "Your spaces", and that confirmed/verify objects land as unpacked items while flagged reads stay out.

## v0.8.17+37 - 2026-11-20

- Coach vocabulary variety (steward directive): the plan drafter, the bucket suggestions and the chat assembly now rotate wording through a per-scan seeded, no-repeat vocabulary bundle - rotating openers, varied lead-ins, confirmation questions, discard phrasings and Dan/Sha/Ri phrasings - so two scans never read alike while one conversation stays coherent. The Danshari method is untouched; only the wording rotates.
- Coach confirmation points are flagged structurally (a parallel list on the plan) instead of matched by fixed opening words.
- Scan-to-email forward action (Lane 2 interim route): the waiting bubble gains "Forward scan by email" beside the paste fallback. The package carries the photos in upload order with a body line pinning the order, the venue, the typed notes, and the scan ID in the subject line. APK shares natively; web uses the browser share sheet where it supports files and a copied body where it does not (honest about that edge). The flow ends on the "package sent" labeling - renders and the item list arrive by email, nothing spins. The recipient is not hardcoded; the user addresses the email.

## v0.8.16+36 - 2026-11-20

- Save-at-result-entry: the tidy plan auto-saves the moment the result page opens, so closing the tab can no longer lose suggestions (the back arrow no longer discards - nothing can).
- Venue auto-add: every scan with a venue adds it to "Your spaces"; rescans reuse the existing space. Confirmed and verify recognized objects land as unpacked items on the venue's page; flagged (under 50%) reads stay out by design.
- Empty first run: the demo seed (kitchen mugs and plates, desk paper pile, wardrobe socks) is gone - "Your spaces" and Today's plan start empty and fill from real scans and quick-adds.
- Venue page redesign: tap = select, and a "Finish organizing" bottom button clears the selection (the per-item three-dots delete is gone); "Drop in [venue]" chips open that venue's page on tap.
- Coach attribution: interjections and the notes echo render as coach bubbles, not user bubbles.
- Onboarding double-tap guard (UI flag plus a state-layer backstop); whitespace-only renames rejected in the state layer.
- Corrupt plan stores are reported honestly on the save side and in a Plan tab banner; the next successful save replaces the bad data.
- Dashboard badge derives from package metadata (package_info_plus) - no more manual syncs.
- Docs: photo count (six per scan), mess-scaling behavior, Settings About, PWA manifest, page title.

## v0.8.14+34 - 2026-11-20

- Removed the "Show my tidy plan" button from Coach's chat: it could appear before any suggestion existed, so tapping it opened an empty plan. Finishing the chat (final Next press, or a reply landing on the last line) auto-flows into the tidy plan page. The Plan tab and its auto-save-after-scan flow are unchanged.

## v0.8.13+33 - 2026-11-20

- Dashboard title spacing: the home "Stuff Organiser" title block sits lower (taller app bar + top padding) so the gap to the screen top matches the Demo mode chip. Badge + version synced.

## v0.8.12+32 - 2026-11-20

- Mascot idle + happy expression variants for all three packs (animals, food, anime) - all 15 mascots. Idle renders byte-identical to the base pack; happy swaps only the mouth shape(s) via override data.

## v0.8.11+31 - 2026-11-20

- Removed the "Paste Recognized List" button from Coach's chat; paste remains as a quiet inline fallback inside the waiting bubble so a scan can't dead-end.
- CI: index-wait step between the Pages artifact upload and deploy, fixing the deploy race that killed runs #120-121.
