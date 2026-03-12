Du arbeitest im Flutter-Projekt „Samenbank“.

AUFTRAG (AP-IE-1): Implementiere **Import / Export** der Saatgut-Daten als Datei (JSON) auf Basis des **App-Formats**. Ziel ist Backup/Restore und Datentransfer zwischen Geräten (z.B. via Nextcloud), ohne Cloud-Backend und ohne Account-System.

WICHTIG (Scope / Regeln)
- Arbeite **streng nach `docs/app_format_v1.md`**. Keine Annahmen außerhalb dieses Dokuments.
- Export/Import bezieht sich auf die **Working Copy** (Single Source of Truth) im App-Format.
- MVP-Entscheidung: **Import = Replace-All** (überschreibt den gesamten aktuellen Bestand).
- Kein Merge, keine Konfliktauflösung, keine CRDT.
- Keine Nextcloud/SAF-„Arbeitsdatei wählen“ Logik in diesem AP (das kommt später). Hier reicht: Datei auswählen (Import) / Datei erzeugen & teilen/speichern (Export).
- Keine UI-Redesigns: Nutze minimal-invasive Entry-Points (z.B. Menüpunkt in AppBar/Overflow/Settings Screen – wo bei euch am passendsten).
- Keine Änderungen am Datenmodell außer dem, was für Import/Export zwingend nötig ist.

FUNKTIONALE ANFORDERUNGEN

1) Export (Backup)
- Exportiere den **aktuellen Working-Copy JSON-Inhalt** (App-Format) in eine Datei:
  - Dateiname: `seeds_app_v1.json` (oder exakt wie in eurem Code/Initializer definiert; wenn dort schon ein Konstante existiert, nutze diese).
  - Inhalt: exakt der aktuelle Zustand, den das Repository als Working Copy nutzt.
- Der Nutzer kann die Datei speichern/teilen (Android Share Sheet ist ok).
- Erfolg/Fehler wird klar angezeigt (SnackBar reicht).

2) Import (Restore)
- Nutzer wählt eine JSON-Datei aus (File Picker).
- App liest die Datei, validiert sie gegen das App-Format (wie in `docs/app_format_v1.md` beschrieben).
- Wenn valide:
  - Ersetze den gesamten aktuellen Bestand (Replace-All).
  - Persistiere als neue Working Copy.
  - Reinitialisiere In-Memory State/Cache (falls vorhanden), sodass die App sofort den neuen Bestand anzeigt.
- Wenn invalide:
  - Zeige eine verständliche Fehlermeldung (z.B. „Ungültiges Datenformat“ + optional kurze Detailinfo).
  - Keine Änderungen an der bestehenden Working Copy.

3) Safety UX (sehr wichtig)
- Import ist destruktiv → bestätigungsdialog:
  - „Import überschreibt alle aktuellen Daten. Fortfahren?“
  - Buttons: Abbrechen / Importieren
- Optional (nice): Vor dem Überschreiben automatisch ein temporäres Backup erstellen (nur wenn minimal machbar). Wenn zu aufwendig: weglassen.

TECHNISCHE ANFORDERUNGEN (Implementierung)

A) Repository-Erweiterungen (minimal)
- Ergänze im `SeedRepository` Interface (oder analog in eurem Setup) minimale Methoden:
  - `Future<String> exportWorkingCopyJson()` (oder `Future<Map<String,dynamic>>` + Encode)
  - `Future<void> importWorkingCopyJson(String json)` (Replace-All + Persist)
- LocalSeedRepository:
  - Export: liest aktuellen Working Copy Inhalt (in-memory oder von Datei) und gibt JSON String zurück.
  - Import: parst JSON, validiert/normalisiert strikt nach app_format_v1.md, schreibt Datei, lädt neu.
- Kein neues Format: ausschließlich App-Format.

B) File Handling (Android)
- Import: nutze `file_picker` oder bestehende Lösung im Projekt (wenn bereits vorhanden).
- Export: simplest robust:
  - Erzeuge eine temporäre Datei im app documents/temp dir,
  - schreibe JSON rein,
  - öffne Share-Sheet (z.B. `share_plus`) ODER „Speichern unter“ via system picker, je nachdem was ihr bereits nutzt.
- Keine neuen Dependencies, wenn es sich vermeiden lässt. Wenn nötig, füge genau die minimalen, etablierten Packages hinzu und dokumentiere kurz im Code.

C) Validation
- Validierung strikt nach `docs/app_format_v1.md`.
- Wenn ihr bereits Validator/Parser habt: wiederverwenden.
- Fehlermeldungen: kurz, nutzerfreundlich; technische Details maximal in debug logs.

ENTRY POINTS (UI)
- Füge zwei Aktionen hinzu:
  - „Export (Backup)“
  - „Import (überschreibt)“
- Platziere sie dort, wo es am wenigsten invasiv ist (z.B. Overflow im Hauptscreen / Settings Screen, falls vorhanden).
- Keine neue komplexe Navigation; einfacher Dialog/BottomSheet reicht.

TESTS (verpflichtend)
- Unit-Test: Export liefert validen JSON-String im App-Format (Parse sollte funktionieren).
- Unit-Test: Import (valid) ersetzt Daten vollständig:
  - Arrange: Repo mit Dataset A
  - Act: import Dataset B
  - Assert: `getAllSeeds()` entspricht B, A ist weg
  - Persistenz: nach Repo-Neuinit ist B vorhanden
- Unit-Test: Import (invalid) verändert nichts:
  - Arrange: Repo mit Dataset A
  - Act: import invalid JSON
  - Assert: `getAllSeeds()` weiterhin A, Datei unverändert
- Optional Widget-Test: Confirm-Dialog blockiert Import bis bestätigt (nur wenn leicht).

VORGEHEN (verbindlich)
1) Lies `docs/app_format_v1.md` vollständig.
2) Finde die Working-Copy-Datei-Konstante / Initializer (z.B. WorkingCopyV1Initializer) und nutze die bestehenden Pfade/Namen.
3) Implementiere Repository Export/Import (Replace-All) + Validierung.
4) Implementiere UI Entry Points + Confirm Dialog + Feedback.
5) Schreibe Tests.
6) `flutter test` muss grün sein.

SCOPE-DISZIPLIN (nicht tun)
- Kein Merge, keine Konfliktauflösung.
- Keine Nextcloud-Ordnerwahl/SAF-Working-Copy Location (kommt später).
- Keine neuen Domain-Felder/Logik.
- Keine Änderungen am View/Edit Screen Verhalten.

ABGABE
- Sauberer Diff.
- Kurze Notiz in Code-Kommentaren, wo Import/Export verankert ist.
- Alle Tests grün.

