# Stuff Organiser AI

A near-zero-friction organiser for physical household items and real paper piles.
Android-first. Runs instantly in demo mode — no Firebase keys needed to look around.

## Quick start (demo mode)

```bash
flutter pub get
flutter run
```

Boots straight into onboarding with an empty home: "Your spaces" and Today's plan
fill up only from real scans and quick-adds. Firebase only activates when
dart-define keys are provided; otherwise the app stays in demo mode by design.

## Android build (one command, then run)

```bash
flutter create --platforms=android --org com.stufforganiser .
flutter pub get
flutter run                  # connected device/emulator
flutter build apk --debug    # installable debug APK
```

- APK lands at `build/app/outputs/flutter-apk/app-debug.apk` — copy it to an
  Android phone and install (allow "install unknown apps" once).
- applicationId: `com.stufforganiser.stuff_organiser_ai` (assumption — say the
  word and it gets renamed before delivery).
- `android/gradle.properties` pins `flutter.minSdkVersion=23`, required by
  firebase_auth 5.x.
- Requires Flutter >= 3.29 (stable) / Dart >= 3.7.

## Automated APK (GitHub Actions)

`.github/workflows/android-apk.yml` builds a debug APK on every push to `main`
(and on demand via "Run workflow"):

1. Push this repo to GitHub.
2. Actions → android-apk → latest run → Artifacts → `stuff-organiser-ai-debug-apk`.

The web-pages job also publishes the web build (plus the APK as a direct
download) to GitHub Pages and stamps `build/web/version.json` with the pubspec
version so the deployed build can be verified from outside.

## Scan feature

Photograph a messy space (up to six photos per scan — the first is the main
view, extra angles welcome) and the tidy coach works from what the recognition
lane actually reads:

- Each uploaded photo gets its own read from the recognition lane; the coach
drafts every observation, suggestion and confirmation point from the merged
object list, so different rooms produce different plans.
- Reads are tiered by confidence: confirmed (85%+), verify (50–84%) and flagged
(under 50%). Verify reads become confirmation points you can answer inline;
flagged reads are shown but never acted on.
- The number of suggestions scales with how much the lane found (2 for a light
space, 3 for a fuller one, never more than 4), and the mess level chip
(tidy / moderate / messy) comes from the object count.
- The tidy plan auto-saves the moment the result page opens, and every scanned
venue auto-adds to "Your spaces" with its recognized items ready to clear.

Interpretation runs on the recognition lane; photos never leave the device in
demo mode. The old optional Gemini-key route was retired from the pipeline
(v0.6.9).

## Scan forward lane (email)

App-user scans reach the recognition lane by email while the automated
transport is pending. After uploading a scan, the waiting bubble offers
"Forward scan by email": the package carries the photos in upload order (with
a body line pinning the order), the venue and the typed notes, and the scan ID
names the subject line ("Stuff Organiser scan <id>").

- The web compose opens pre-addressed to **afantashoon@gmail.com** — the
  coach's receive mailbox. Attach the photos in upload order and send.
- On Android, the native share sheet carries the photos as attachments; the
  in-app hint names the destination address to send to.
- The mailbox watches for subjects beginning with "Stuff Organiser scan";
  the organized renders and the recognized item list arrive back by email.

## Firebase (optional, for real accounts)

- Keys at build time:
  `--dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=...`
- Security rules: paste `firestore.rules` into the Firebase console (Rules tab).
  Users can only read/write their own `/users/{uid}` data.
- Indexes: none required for v1 queries.

## Data model

User → Spaces → Items. One unified model: category `household | paper`,
status `loose | organized`. Paper piles carry an action: `sort | keep | file | recycle`.

## Changelog

The running changelog lives in CHANGELOG.md; the v0.1 – v0.5 history is below.

## Changelog v0.1 → v0.2

- Fixed compile-breaking `ThemeData.cardTheme` type (CardTheme → CardThemeData);
  toolchain floor raised to Flutter >= 3.29 / Dart >= 3.7.
- Fixed quick-add crash when a selected space was deleted mid-screen.
- Fixed quick-add saving state getting stuck if adding failed.
- Fixed stale data shown after sign-out (state reloads now).
- Added `android/gradle.properties` (minSdk 23 for Firebase, AndroidX, Gradle memory).
- Added `firestore.rules` (per-user data isolation).
- Added GitHub Actions workflow producing an installable debug APK on push.
- Added this README.
- Verified edge cases: empty spaces, zero-item plan, duplicates as distinct
  entries, drag-reorder persistence.

## Changelog v0.2 → v0.3

- Duplicate guard: quick-add detects an item with the same name already in the
target space and offers to increase the existing count, add a separate
entry, or cancel - no more silent clones.
- Paper piles: the planned action (sort / keep / file / recycle) can now be
changed after creation from the item tile; the plan text follows the new
action.
- Reorder/move hardening: drag-reorder and cross-space moves validate that the
items and spaces still exist, skip redundant writes when nothing changed,
and persist immediately so ordering survives app restarts.
- Order fix: new items take max(order)+1 inside a space, closing an order
collision after a cross-space move.
- pubspec bumped to 0.3.0+3. No new dependencies; all v0.2 fixes retained.

## Changelog v0.3 → v0.4

- New **Scan** feature: a camera "Scan" button on the home screen; the coach
chats the plan step by step in separate dialogue boxes, then a concept
preview plus the complete notes page with copy-all.
- Demo mode by default; optional Google AI Studio / Gemini key via the key
icon inside the scan screen, kept on-device, with graceful fallback to demo
whenever the live call fails.
- CI builds the web version and publishes it to GitHub Pages together with a
direct-download APK.
- pubspec bumped to 0.4.0+4. No new dependencies; all v0.3 fixes retained.

## Changelog v0.4 → v0.5

- Scan now analyses what is actually in the photo: every suggestion names the
real objects and surfaces it can see and proposes a concrete physical action
instead of template advice (reference: professional organiser Kira Chan's
small-space tidying method).
- The coach reports the visible setting and the mess level, both surfaced as
chips in the result stage and included in the copy digest.
- The number of suggestions scales with the real messiness (1-2 for tidy,
4-6 for moderate, 8-12 for messy) instead of a fixed list.
- New generated "after tidying" picture: photoreal edit of the user's own
photo with a Gemini key; keyless Pollinations concept image otherwise, with
graceful degradation to the concept placeholder.
- Richer offline demo coach: the photo hash selects one of three concrete
organiser play books (papers and files, cups and dishes, clothes / floor /
cables) and the suggestion count varies per photo.
- pubspec bumped to 0.5.0+5. CI stamps `build/web/version.json` with the
pubspec version for outside verification.
