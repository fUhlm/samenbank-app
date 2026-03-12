# samenbank-app

Flutter app for managing a private seed collection with a month-oriented growing calendar, variety management, and local JSON-based working copies.

Flutter-App zur Verwaltung einer privaten Samenbank mit monatsorientierter Gartenansicht, Sortenverwaltung und lokaler JSON-Working-Copy.

Repository name: `samenbank-app` / package name: `samenbank` / app name on the device: `Saatenschluessel`.

## Overview

`samenbank-app` is a personal seed inventory and planning app built with Flutter. It is designed for gardeners who want to keep seed varieties, sowing windows, and related notes in a structured local format instead of a spreadsheet.

The repository and package still use the historic `samenbank` naming, while the installed app is presented to end users as `Saatenschluessel`.

The current app focuses on:

- month-based planning for sowing and pre-cultivation periods
- a searchable list of seed varieties
- detail views for editing seed entries
- import of local or external working copies, for example via Android SAF or Nextcloud
- JSON backup export

## Ueberblick

Die App dient zur Organisation einer privaten Saatgut-Sammlung in einem lokalen, einfach transportierbaren Datenformat. Der aktuelle Funktionsumfang umfasst:

Repository und Paket verwenden weiterhin den historischen Namen `samenbank`, waehrend die installierte App auf dem Geraet als `Saatenschluessel` erscheint.

- Monatsansicht mit relevanten Aussaat- und Voranzuchtfenstern
- Sortenliste mit Suche, Filterung und Neuanlage
- Detailansichten zum Bearbeiten von Sorten
- Import lokaler oder externer Working Copies, zum Beispiel ueber Android SAF oder Nextcloud
- Export von Backups als JSON

## Project Status

This repository contains a working Flutter application with tests and technical documentation. The repository only includes demo data. Real or private seed data should be stored in local, non-versioned files or external working copies, not in Git.

## Tech Stack

- Flutter
- Dart
- local JSON persistence
- GitHub Actions for analysis and tests

## Getting Started

Prerequisites:

- Flutter SDK
- Dart SDK compatible with the Flutter version used by this project

Run locally:

```bash
flutter pub get
flutter run
```

Run analysis and tests:

```bash
flutter analyze
flutter test
```

Format code:

```bash
dart format .
```

CI-style format check:

```bash
dart format --output=none --set-exit-if-changed .
```

## Android Release Build

For local Android releases outside the Play Store, the project expects a private keystore configured via `android/key.properties`. The keystore passwords are read from environment variables so they do not need to live in a file.

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Create or choose a local keystore file.
3. Fill in `storeFile` and `keyAlias`.
4. Export `SAATENSCHLUESSEL_STORE_PASSWORD` and `SAATENSCHLUESSEL_KEY_PASSWORD` in your shell.
5. Build the release artifact with `flutter build apk --release`.

`android/key.properties` and keystore files are intentionally ignored by Git.

You can also use `./build-release.sh`. The script prompts for missing passwords without echoing them and then runs the Android release build.

## Data Model

- `assets/seeds.json` contains demo data in the bundled import or legacy format.
- The app works internally with a local working copy in app format v1.
- The format description is documented in [docs/app_format_v1.md](docs/app_format_v1.md).
- Additional contract and QA documentation is available in [docs](docs).

## Privacy

This repository is intended to be public-safe. It does not contain productive seed inventory data. If you use the app with your own collection, keep exports and working copies outside version control unless the data is explicitly meant to be shared.

## Project Structure

- [lib/main.dart](lib/main.dart): app entry point and month view
- [lib/all_seeds_screen.dart](lib/all_seeds_screen.dart): variety list
- [lib/seed_detail_screen_v2.dart](lib/seed_detail_screen_v2.dart): detail and edit view
- [lib/settings_screen.dart](lib/settings_screen.dart): working copy selection, reload, and export
- [test](test): automated tests
- [.github/workflows/flutter_ci.yml](.github/workflows/flutter_ci.yml): CI for analysis and tests

## Platform Notes

- Android-specific logic for external working copies is already implemented.
- The repository also contains the standard Flutter targets for web, Windows, Linux, macOS, and iOS.
- Production readiness should be validated per platform before publishing releases.

## License

This repository is licensed under the GNU GPL v3 or later (`GPL-3.0-or-later`). See [LICENSE](LICENSE) for details.
