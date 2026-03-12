# QA Report: AP-IE1 (Import / Export)

## 1. Metadaten
- Branch: `dev`
- BASE-Strategie: `origin/dev` vorhanden, `git fetch --all --prune` fehlgeschlagen (kein Netzwerk/DNS auf `github.com`)
- BASE: `ec5791f4cfcfd86cabf8dc7c94d413e29cee81c1`
- HEAD: `9eec7f39820337a742992cfceb35f055727c8585`
- Datum/Uhrzeit: `2026-02-20T17:46:04+01:00`

## 2. AP-Auszug (AP-IE1)
### In-Scope
- Import/Export der Working-Copy als JSON im App-Format.
- Import als Replace-All (vollständiges Überschreiben).
- Validierung nach `docs/app_format_v1.md`.
- Minimale UI-Entry-Points für `Export (Backup)` und `Import (überschreibt)`.
- Destruktiver Import-Confirm-Dialog.
- Tests für Export, Import valid, Import invalid.

### Out-of-Scope / Nicht-Ziele
- Kein Merge/Conflict-Handling/CRDT.
- Keine Nextcloud-/SAF-Arbeitsdatei-Logik.
- Kein UI-Redesign.
- Keine unnötigen Domain-/Datenmodell-Erweiterungen.
- Keine Änderungen am View/Edit-Verhalten außerhalb AP-Bedarf.

### Acceptance Criteria (aus AP, als Checklist)
- [x] Export liefert aktuellen Working-Copy-Inhalt im App-Format in Datei (`seeds_app_v1.json`/bestehende Konstante).
- [x] Export erlaubt Speichern/Teilen und zeigt Erfolg/Fehler.
- [x] Import per File Picker.
- [x] Import validiert gegen App-Format.
- [x] Import valid: Replace-All + Persistenz + sofort sichtbarer neuer Zustand.
- [x] Import invalid: keine Änderungen + verständliche Fehlermeldung.
- [x] Confirm-Dialog vor destruktivem Import mit Text und Buttons.
- [x] Repository-API enthält minimale Export/Import-Methoden.
- [x] Unit-Tests: Export parsebar, Import valid ersetzt/persistiert, Import invalid unverändert.

## 3. Scope
### Diff gemäß Template (`BASE...HEAD`)
- Enthaltene Änderungen decken AP-IE1 technisch ab:
  - Repository-Schnittstellen + Implementierung (`lib/src/repositories/...`)
  - UI-Entry-Points/Import-Confirm/Feedback (`lib/all_seeds_screen.dart`)
  - Import/Export-Tests (`test/local_seed_repository_import_export_test.dart`)
  - notwendige Dependency-/Plugin-Registrierungen (`pubspec.*`, platform registrants)

Bewertung:
- **OK**: Technische AP-IE1-Umsetzung ist im Diff sichtbar.
- **Hinweis**: Im selben Commit sind auch Doku-/Hilfsdateien enthalten (`docs/...`, `diff.txt`), die nicht Teil der Kernimplementierung sind.

## 4. Harte Gates
1. `flutter --version` -> **OK**
   - Flutter `3.38.9`, Dart `3.10.8`.
2. `flutter pub get` -> **OK**
   - Dependencies aufgelöst.
3. `flutter analyze` -> **OK**
   - `No issues found!`
4. `flutter test` -> **OK**
   - `All tests passed!`
5. `dart format --output=none --set-exit-if-changed .` -> **OK**
   - `Formatted 40 files (0 changed)`.
6. `flutter build apk --debug` -> **OK**
   - `Built build/app/outputs/flutter-apk/app-debug.apk`.

QA-Guard nach jedem Gate (`git status --porcelain`):
- **OK**: kein neuer tracked Drift während des QA-Laufs.

## 5. Contract-/Regression-Checks
Ausgeführt laut AP-IE1-QA:
- `git diff $BASE...HEAD -- docs/app_format_v1.md` -> keine Änderungen
- `git diff $BASE...HEAD -- lib/src/models` -> keine Änderungen
- `git diff $BASE...HEAD -- lib/src/repositories` -> Änderungen vorhanden, AP-konsistent
- `git diff $BASE...HEAD -- lib/src/ui` -> keine direkten Änderungen
- `git diff $BASE...HEAD -- lib` -> Änderungen vorhanden, AP-konsistent
- `git diff $BASE...HEAD -- test` -> Import/Export-Tests ergänzt

Bewertung:
- **OK**: Keine Hinweise auf verbotene Nextcloud/SAF-Arbeitsdatei-Logik oder Merge/Conflict-Logik.
- **Hinweis/Risiko**: `lib/src/data/seed_json_mapper.dart` wurde mit angepasst; diese Änderung sollte separat fachlich verifiziert bleiben, da sie AP-seitig nicht zwingend war.

## 6. UI/Flow Smoke-Checks
Methodik: statische Code-Prüfung + Testausführung (`flutter test`). Kein vollständiger manueller Device-Clickthrough im QA-Lauf.

1. Export-Entry-Point minimal-invasiv vorhanden -> **OK**
2. Export nutzt bestehende Dateinamen-Konstante (`appFormatV1FileName`) -> **OK**
3. Export zeigt Erfolg/Fehler klar an -> **OK**
4. Import-Entry-Point vorhanden -> **OK**
5. Confirm-Dialog vor Import (Text + Buttons) -> **OK**
6. Import valid ersetzt Bestand vollständig + Persistenz -> **OK**
7. Import invalid verändert nichts + Fehlerfeedback -> **OK**
8. Keine offensichtliche Fremd-Regression in AP-fernen Flows -> **OK mit Restrisiko**

## 7. Befund & Entscheidung
**Entscheidung: `PASS WITH NOTES`**

Notes:
- Technische Anforderungen und Gates sind erfüllt.
- Fetch gegen Remote konnte wegen Netzwerk/DNS-Limit nicht durchgeführt werden.
- Vollständige manuelle UI-Regression wurde im QA-Lauf nicht durchgeführt.
