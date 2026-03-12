# samenbank-app

Flutter-App zur Organisation einer privaten Samenbank mit Monatsansicht, Sortenverwaltung und lokaler JSON-Working-Copy.

## Überblick

Die App bündelt Saatgutdaten in einer lokalen Arbeitsdatei und stellt sie in einer auf Gartenmonate ausgerichteten Oberfläche dar. Der aktuelle Fokus liegt auf:

- Monatsübersicht mit relevanten Aussaat- und Voranzuchtfenstern
- Sortenliste mit Filter und Anlage neuer Einträge
- Detailansicht zum Bearbeiten von Sorten
- Import einer lokalen oder externen Working-Copy, zum Beispiel über Android SAF und Nextcloud
- Export von Backups als JSON

## Tech-Stack

- Flutter
- Dart
- Lokale JSON-Datenhaltung
- GitHub Actions für Analyse und Tests

## Projektstatus

Das Repository enthält eine lauffähige Flutter-App inklusive Tests und technischer Dokumentation. Die öffentliche Variante `samenbank-app` enthält nur Demo-Daten im Repository; produktive/private Saatgutdaten gehören in eine externe oder lokale, nicht versionierte Arbeitsdatei.

## Schnellstart

Voraussetzungen:

- Flutter SDK installiert
- Dart SDK passend zur im Projekt verwendeten Flutter-Version

Projekt lokal starten:

```bash
flutter pub get
flutter run
```

Tests und Analyse ausführen:

```bash
flutter analyze
flutter test
```

Code formatieren:

```bash
dart format .
```

CI-kompatible Format-Prüfung:

```bash
dart format --output=none --set-exit-if-changed .
```

## Datenmodell

- `assets/seeds.json` ist das mitgelieferte Import-/Legacy-Format mit Demo-Daten.
- Die App arbeitet intern mit einer lokalen Working Copy im App-Format v1.
- Die Formatbeschreibung liegt in [docs/app_format_v1.md](docs/app_format_v1.md).
- Weitere Vertrags- und QA-Dokumente liegen im Ordner [docs](docs).

## Demo-Daten und Privatsphäre

Dieses Repository enthaelt ausschliesslich Demo-Daten. Eigene oder produktive Seed-Daten sollten nicht versioniert werden, sondern nur in lokalen Exportdateien oder externen Working Copies liegen.

## Projektstruktur

- [lib/main.dart](lib/main.dart): App-Einstieg und Monatsansicht
- [lib/all_seeds_screen.dart](lib/all_seeds_screen.dart): Sortenliste
- [lib/seed_detail_screen_v2.dart](lib/seed_detail_screen_v2.dart): Detail- und Bearbeitungsansicht
- [lib/settings_screen.dart](lib/settings_screen.dart): Working-Copy-Auswahl, Reload und Export
- [test](test): automatisierte Tests
- [.github/workflows/flutter_ci.yml](.github/workflows/flutter_ci.yml): CI für Analyse und Tests

## Plattformhinweise

- Android-spezifische Logik für externe Working Copies ist bereits vorhanden.
- Das Repository enthält außerdem die üblichen Flutter-Targets für Web, Windows, Linux, macOS und iOS.
- Ob alle Targets produktionsreif sind, sollte vor einer öffentlichen Veröffentlichung oder einem Release separat validiert werden.

## Für ein öffentliches Repository sinnvoll

Vor dem Umschalten auf `public` solltest du mindestens diese Punkte prüfen:

- Repository-Beschreibung, Topics und ggf. Social Preview auf GitHub setzen
- Private Seed-Daten nur in nicht versionierten lokalen Dateien oder externen Working Copies halten
- Optional: Screenshots, Issue-Templates und Changelog ergänzen

## Lizenz

Dieses Repository steht unter der GNU GPL v3 oder spaeter (`GPL-3.0-or-later`). Details siehe [LICENSE](LICENSE).
