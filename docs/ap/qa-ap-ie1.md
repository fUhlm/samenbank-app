## Rolle & Modus
Du bist **QA Engineer**.  
**READ-ONLY**: Du darfst **keine bestehenden Dateien ändern**.  
Erlaubt ist **nur** das Erstellen/Aktualisieren **einer** Report-Datei:  
- `docs/qa/qa-report-ap-ie1.md`

Wenn nach deiner QA **irgendeine** andere Änderung in `git status` sichtbar ist (tracked files), ist das ein **QA-Verstoß -> FAIL**.

---

## Inputs
- AP (Implementierung): `docs/ap/AP-IE1.md`
- QA-AP (dieses Dokument): `docs/ap/qa-ap-ie1.md`
- Base-Branch: `dev` (wenn remote vorhanden: `origin/dev`)
- Report-Ziel: `docs/qa/qa-report-ap-ie1.md`

---

## Ablauf (streng in dieser Reihenfolge)

### 1) Baseline & Kontext erfassen
1. `git rev-parse --abbrev-ref HEAD`
2. `git log -1 --oneline`
3. Versuche `git fetch --all --prune` (nur wenn remote verfügbar; wenn nicht, kurz notieren)
4. Bestimme BASE:
   - wenn `origin/dev` existiert: `BASE=$(git merge-base HEAD origin/dev)`
   - sonst: `BASE=$(git merge-base HEAD dev)`
5. `git show -s --oneline $BASE`
6. `git status --porcelain` (muss sauber sein außer untracked/ignored)

### 2) AP lesen & Kriterien extrahieren
- Lies `docs/ap/AP-IE1.md`.
- Extrahiere in Stichpunkten:
  - In-Scope
  - Out-of-Scope / Nicht-Ziele
  - Acceptance Criteria als Checkboxen (genau, keine Interpretation)
- Wenn etwas unklar ist: markiere „UNKLAR“ + warum (keine Rückfragen stellen).

### 3) Scope-Disziplin via Diff
1. `git diff --stat $BASE...HEAD`
2. `git diff --name-only $BASE...HEAD`
3. Prüfe: passen die geänderten Dateien zum AP-Scope?
   - Ergebnis: **OK/NOK**
   - Bei NOK: liste Dateien + konkreter Grund (z.B. „AP verbietet Domain-Änderungen, aber …“)

### 4) Harte Gates ausführen (mit Protokoll)
Führe aus und protokolliere jeweils **OK/NOK + kurze relevante Auszüge**:

1. `flutter --version`
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test`
5. Format-Check (ohne Änderungen!):
   - `dart format --output=none --set-exit-if-changed .`
   - Wenn NOK: liste betroffene Dateien/Fehlerauszug
6. Optionaler Build-Smoketest (falls im Projekt realistisch):
   - `flutter build apk --debug`
   - Wenn nicht möglich: als „NICHT AUSGEFÜHRT“ + Begründung

**Wichtig:** Nach jedem Gate:
- `git status --porcelain`
- Wenn tracked Änderungen auftauchen (z.B. pubspec.lock), dann:
  - **FAIL** (QA-Verstoß) und dokumentieren welche Datei warum.
  - Nichts revertieren (read-only).

### 5) Contract-/Regression-Checks (AP-IE1-spezifisch)
Da AP-IE1 explizit Out-of-Scope-Bereiche nennt, prüfe per Diff gezielt:
- `git diff $BASE...HEAD -- docs/app_format_v1.md`
- `git diff $BASE...HEAD -- lib/src/models`
- `git diff $BASE...HEAD -- lib/src/repositories`
- `git diff $BASE...HEAD -- lib/src/ui`
- `git diff $BASE...HEAD -- lib`
- `git diff $BASE...HEAD -- test`

Bewertung:
- Änderungen sind nur zulässig, wenn sie AP-IE1 direkt bedienen (Import/Export, Replace-All, Validierung, minimale Entry-Points, Tests).
- Wenn Änderungen Nextcloud/SAF-Arbeitsdatei-Logik, Merge/Conflict-Logik, UI-Redesign oder View/Edit-Verhaltensänderungen einführen -> **FAIL** (mit Datei/Grund).

### 6) UI/Flow Smoke-Checks (AP-IE1-abgeleitet)
Leite aus dem AP konkrete Testpfade ab und prüfe sie:
1. Export-Aktion erreichbar über minimal-invasiven Entry-Point.
2. Export erzeugt Datei im App-Format (`seeds_app_v1.json` bzw. bestehende Konstante).
3. Export zeigt Success/Failure klar an.
4. Import-Aktion erreichbar über minimal-invasiven Entry-Point.
5. Import zeigt destruktiven Confirm-Dialog mit korrektem Text und Buttons.
6. Import (valides JSON) ersetzt Bestand vollständig (Replace-All) und Zustand wird direkt neu angezeigt.
7. Import (invalides JSON) verändert nichts und zeigt verständliche Fehlermeldung.
8. Kein unerwarteter Eingriff in andere Flows (insb. kein Redesign/keine View-Edit-Regressions).

Für jeden Pfad: **OK/NOK** + kurzer Grund.

---

## Output: Report schreiben
Schreibe einen Markdown-Report nach:
`docs/qa/qa-report-ap-ie1.md`

Struktur:
1. **Metadaten** (Branch, BASE, HEAD, Datum/Uhrzeit)
2. **AP-Auszug** (In/Out/AC)
3. **Scope**
4. **Harte Gates**
5. **Contract-/Regression-Checks**
6. **UI/Flow Smoke-Checks**
7. **Befund & Entscheidung**

Entscheidung nur als:
- `PASS`
- `PASS WITH NOTES`
- `FAIL`

Bei `FAIL`:
- klare Blocker-Liste
- konkrete Dateien/Kommandos
- präzise Repro-Hinweise
