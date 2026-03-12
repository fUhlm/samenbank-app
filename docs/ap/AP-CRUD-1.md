# AP-CRUD-1: Delete Seed

## Ziel
Ein bestehender Eintrag kann aus der Working Copy dauerhaft entfernt werden.

## Scope
- UI-Aktion `Löschen` im Detail-Screen (Bottom Sheet via Long-Press auf TubeCode-Badge)
- Bestätigungsdialog vor dem Löschen (irreversibel)
- Repository-API `deleteSeed(String varietyId)`
- Persistenz: Working Copy wird nach Delete atomar überschrieben
- Navigation: Nach erfolgreichem Delete zurück in den vorherigen Kontext

## Guardrails
- Kein Soft-Delete
- Kein Undo
- Keine Änderungen an Domain-/Kalenderlogik
- Keine Änderungen an Import/Export

## Umsetzung

### UI
- Bottom Sheet enthält die Aktion `Löschen`
- Bestätigungsdialog:
  - Titel: `Eintrag löschen?`
  - Text: `Dieser Vorgang ist irreversibel. Soll der Eintrag wirklich gelöscht werden?`
  - Aktionen: `Abbrechen`, `Löschen`
- Erfolg: Detail-Screen wird geschlossen (Rücknavigation)
- Fehler: Snackbar `Löschen fehlgeschlagen. Bitte erneut versuchen.`

### Repository
- `SeedRepository` um `Future<void> deleteSeed(String varietyId)` erweitert
- `MockSeedRepository`: Entfernt Eintrag per `varietyId`
- `LocalSeedRepository`:
  - validiert Initialisierung und Existenz des Eintrags
  - entfernt Eintrag aus Cache-Kopie
  - schreibt aktualisierte Liste in `seeds_app_v1.json` (atomar via `.tmp` + rename)
  - aktualisiert In-Memory-Cache

## Persistenzverhalten
Nach erfolgreichem Delete ist der Eintrag:
- sofort nicht mehr in `getAllSeeds()` enthalten
- nach vollständigem Reload weiterhin entfernt

## Tests
### Implementiert
- `LocalSeedRepository.deleteSeed removes seed from cache and persists removal to seeds_app_v1.json`
  - prüft Entfernen aus `getAllSeeds()`
  - prüft Persistenz durch Reload einer neuen Repository-Instanz
  - prüft, dass keine `.tmp`-Datei liegen bleibt

## Ergebnis
AP-CRUD-1 ist technisch umgesetzt und getestet.
