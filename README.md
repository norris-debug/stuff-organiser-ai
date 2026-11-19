# Stuff Organiser AI

A near-zero-friction organiser for physical household items and real paper piles.
Android-first. Runs instantly in demo mode — no Firebase keys needed to look around.

## Quick start (demo mode)

```bash
flutter pub get
flutter run
```

Boots straight into onboarding/dashboard with sample data. Firebase only activates
when dart-define keys are provided; otherwise the app stays in demo mode by design.

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

## Firebase (optional, for real accounts)

- Keys at build time:
  `--dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=...`
- Security rules: paste `firestore.rules` into the Firebase console (Rules tab).
  Users can only read/write their own `/users/{uid}` data.
- Indexes: none required for v1 queries.

## Data model

User → Spaces → Items. One unified model: category `household | paper`,
status `loose | organized`. Paper piles carry an action: `sort | keep | file | recycle`.

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
