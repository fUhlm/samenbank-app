# QA Report: AP-CRUD-2 Follow-up (UI/Contract Fixes)

## 1. Metadaten
- Branch: `dev`
- HEAD: `259226042ac1e6ab05ebea6672b44a62604a085b` (`2592260 feat: implement AP-CRUD-2 create mode with autocomplete`)
- BASE: `30faa6a5a3f4454085efbc55fde1e7b95423d8e7` (`30faa6a style: run dart format and document format commands`)
- Datum/Zeit: `2026-02-20T08:53:59+01:00`

Baseline-Kommandos:
- `git rev-parse --abbrev-ref HEAD` -> `dev`
- `git log -1 --oneline` -> `2592260 feat: implement AP-CRUD-2 create mode with autocomplete`
- `git fetch --all --prune` -> NOK (kein Netzwerk: `Could not resolve hostname github.com`)
- `git show -s --oneline $BASE` -> `30faa6a style: run dart format and document format commands`
- `git status --porcelain` zu Beginn:
  - `M lib/all_seeds_screen.dart`
  - `M lib/seed_detail_screen_v2.dart`
  - `M test/seed_detail_create_mode_test.dart`
  - plus untracked Dateien/Ordner

## 2. AP-Auszug (durchgeführte Follow-up-Anforderungen)

### In-Scope
- Header-Fix im Listen-Screen: eine Zeile, rechts `[Filter][Add-Button]`.
- Save-Fehlertexte mit konkreter Ursache (mindestens Exception-Text).
- Autocomplete-Erweiterung auf `Art`.
- Wording: `Tubenummer` -> `Röhrchen-Nr.`.
- `Röhrchen-Nr.` als Dropdown mit freien Nummern pro Röhrchenfarbe.
- Reihenfolge im Identifikation-Block: `Röhrchen-Nr.` -> `Lateinischer Name` -> `Familie`.
- Variety-ID-Erzeugung gemäß Data-Contract v1.2; UI-Label `Samen-ID` (read-only).

### Out-of-Scope / Nicht-Ziele
- Keine UI-Neugestaltung außerhalb der Punkte.
- Keine neuen Features.
- Keine Änderungen am Datenformat/Contract.
- Keine Änderungen in Domain-/Calendar-/Model-Logik außerhalb erforderlicher Folgeeffekte.

### Acceptance Criteria (Checklist)
- [x] Header rechts in Reihenfolge `Filter`, `Add Button`
- [x] Save-Fehler enthält konkrete Ursache (`e.toString()` sichtbar)
- [x] Autocomplete für `Art` aus lokalen Daten (unique/sortiert)
- [x] Label überall im CRUD2-Formular auf `Röhrchen-Nr.`
- [x] `Röhrchen-Nr.` ist Dropdown mit freien Nummern je Farbe
- [x] Identifikation-Reihenfolge angepasst (`Röhrchen-Nr.` -> `Lateinischer Name` -> `Familie`)
- [x] Variety-ID-Generierung nach Contract v1.2 umgesetzt, UI als `Samen-ID` read-only

UNKLAR:
- Kein separates `docs/ap/qa-ap-xx.md` für diese Follow-up-Anweisung vorhanden; QA basiert auf der konkret übergebenen Anforderung + bestehender AP-CRUD2-Kontext.

## 3. Scope-Disziplin via Diff

### 3.1 Template-Diff (`$BASE...HEAD`)
- `git diff --name-only $BASE...HEAD`:
  - `lib/all_seeds_screen.dart`
  - `lib/seed_detail_screen_v2.dart`
  - `lib/src/repositories/local_seed_repository.dart`
  - `lib/src/repositories/seed_repository.dart`
  - `test/local_seed_repository_update_test.dart`
  - `test/seed_detail_create_mode_test.dart`
- Bewertung: **OK** für ursprüngliches AP-CRUD2, aber enthält mehr als nur diese Follow-up-Änderung.

### 3.2 Arbeitsdiff (durchgeführte Follow-up-Arbeiten)
- `git diff --name-only`:
  - `lib/all_seeds_screen.dart`
  - `lib/seed_detail_screen_v2.dart`
  - `test/seed_detail_create_mode_test.dart`
- Bewertung Scope-Fit: **OK** (nur Liste/Detail/UI-Fehlertext/Test).

## 4. Harte Gates

### Gate 1: `flutter --version`
- Ergebnis: **OK**
- Auszug: `Flutter 3.38.9`, `Dart 3.10.8`
- `git status --porcelain` danach: unverändert (keine neuen tracked Änderungen)

### Gate 2: `flutter pub get`
- Ergebnis: **OK**
- Auszug: `Got dependencies!`
- `git status --porcelain` danach: unverändert

### Gate 3: `flutter analyze`
- Ergebnis: **OK**
- Auszug: `No issues found!`
- `git status --porcelain` danach: unverändert

### Gate 4: `flutter test`
- Ergebnis: **OK**
- Auszug: `All tests passed!`
- `git status --porcelain` danach: unverändert bzgl. tracked Dateien

### Gate 5: `dart format --output=none --set-exit-if-changed .`
- Ergebnis: **OK**
- Auszug: `Formatted 39 files (0 changed)`
- `git status --porcelain` danach: unverändert

### Gate 6 (optional): `flutter build apk --debug`
- Ergebnis: **OK**
- Auszug: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`
- `git status --porcelain` danach: unverändert bzgl. tracked Dateien

## 5. Contract-/Regression-Checks

Ausgeführt:
- `git diff -- lib/src/calendar`
- `git diff -- lib/src/models`
- `git diff -- lib/src/repositories`
- `git diff -- docs/contracts assets`

Ergebnis (Arbeitsdiff):
- `lib/src/calendar`: **OK** (kein Diff)
- `lib/src/models`: **OK** (kein Diff)
- `lib/src/repositories`: **OK** (kein Diff)
- `docs/contracts`/`assets`: **OK** (kein Diff)

Hinweis (`$BASE...HEAD`): enthält Repository-Änderungen aus früheren Commits (`lib/src/repositories/...`), nicht aus diesem Follow-up-Arbeitsdiff.

## 6. UI/Flow Smoke-Checks (AP-abgeleitet)

1. Header-Row Layout (`Titel links`, rechts `Filter` + `Add Button`)
- Ergebnis: **OK**
- Evidenz: `lib/all_seeds_screen.dart` (Header auf `Row` umgestellt, `FilledButton.icon` als Add)

2. Save-Fehler zeigt Ursache
- Ergebnis: **OK**
- Evidenz: `_buildSaveErrorMessage` + `catch (error)` in `lib/seed_detail_screen_v2.dart`

3. Autocomplete für `Art`
- Ergebnis: **OK**
- Evidenz: `speciesSuggestions` geladen aus Repository + `Art` als `_EditableAutocompleteRow` in `lib/seed_detail_screen_v2.dart`

4. `Röhrchen-Nr.` Label + Dropdown freie Nummern
- Ergebnis: **OK**
- Evidenz: `_EditableNumberDropdownRow`, `_tubeNumberOptionsForDraft` in `lib/seed_detail_screen_v2.dart`

5. Identifikation-Reihenfolge
- Ergebnis: **OK**
- Evidenz: Reihenfolge im Create-Block: `Röhrchen-Nr.` gefolgt von `Lateinischer Name` und `Familie`

6. `Samen-ID` read-only + Variety-ID-Regel
- Ergebnis: **OK**
- Evidenz: Label `Samen-ID` (`_ReadOnlyValueRow`) und `_generateVarietyId(...)` mit Slug+Hash6 in `lib/seed_detail_screen_v2.dart`

7. Regressionstest für erweitertes Autocomplete
- Ergebnis: **OK**
- Evidenz: `test/seed_detail_create_mode_test.dart` prüft zusätzlich Species-Vorschläge

## 7. Read-only QA-Guard
- Template-Regel (streng): Wenn nach QA tracked Änderungen sichtbar sind, dann FAIL.
- Befund: tracked Änderungen waren bereits **vor** QA-Lauf vorhanden und sind Teil des zu prüfenden Arbeitsstands.
- Bewertung:
  - **Template-strikt:** FAIL (dirty worktree zu Beginn)
  - **Technische QA der implementierten Änderungen:** PASS

## 8. Gesamturteil
**PASS (technisch, für die geprüften Follow-up-Änderungen)**

Restrisiken:
- Keine dedizierten neuen Unit-Tests für Variety-ID-Hashfunktion selbst (nur indirekte Abdeckung über bestehende Flows).
- Kein manueller Geräte-UX-Check, nur Code-/Widget-/Build-Smoketest.
