Du arbeitest im Flutter-Projekt „Samenbank“.

AUFTRAG (AP-CRUD-2): Implementiere „Neu anlegen“ (Create) durch **Wiederverwendung** des bestehenden Detail-Screens (SeedDetailScreenV2) und seines Edit-Modes – als „Create-Mode“. Zusätzlich: **Autocomplete** (Vorschläge beim Tippen) für „Lateinischer Name“ und „Familie“ auf Basis bereits vorhandener Repository-Daten.

WICHTIG (Scope / Regeln)
- Arbeite **streng nach `docs/app_format_v1.md`**. Keine Annahmen außerhalb dieses Dokuments.
- Kein Nextcloud/SAF/Cloud-Sync in diesem AP.
- Kein Redesign: Feld-Reihenfolge/Labels/Spacing im Create-Mode sollen dem Edit-Mode entsprechen (und damit auch dem View-Mode).
- „Lateinischer Name“ und „Familie“ stehen am Ende (wie bereits im Edit-Mode umgesetzt).
- `variety_id` wird beim Create **automatisch generiert** (UUID empfohlen) und ist im UI **nicht editierbar**.
- Beim Create werden **alle Felder** editierbar angeboten (quasi „großer Edit Screen“).
- „Save“ erzeugt einen neuen Seed in der Working Copy und persistiert (über Repository).
- „Cancel/Back“ verlässt den Create-Mode ohne Seiteneffekte.
- Validierung/Constraints gemäß app_format_v1.md:
  - Pflichtfelder gemäß Modell müssen gesetzt sein (zeige verständliche Fehlermeldung).
  - Eindeutigkeitschecks: falls im App-Format eindeutige Identitäten/Keys oder Container-Constraints gefordert sind, müssen sie beim Create geprüft werden.
- Autocomplete ausschließlich aus lokalen Daten (Repository/Working Copy). Keine externen Quellen.

UX-Entscheidung
- Create wird durch denselben Screen umgesetzt:
  - SeedDetailScreenV2 bekommt einen Modus (z.B. enum `DetailMode { view, edit, create }` oder bool flags), sodass die UI:
    - im View-Mode unverändert bleibt,
    - im Edit-Mode wie bisher,
    - im Create-Mode identisch zu Edit, aber initial mit leeren/Default-Werten + neuer variety_id.
- Einstieg in Create:
  - Füge im passenden Listen-/Übersichtsscreen (wo sinnvoll) eine „+“ Aktion hinzu (z.B. AppBar IconButton).
  - Beim Tap: navigiere auf SeedDetailScreenV2 im Create-Mode.

Autocomplete-Details (nur 2 Felder)
- Für die Textfelder „Lateinischer Name“ und „Familie“:
  - Beim Tippen erscheinen Vorschläge (Dropdown/Overlay).
  - Vorschläge = DISTINCT Strings aus vorhandenen Seeds im Repository (case-insensitive dedupe), leere/null ignorieren.
  - Filter: case-insensitive `contains` (oder `startsWith` – wähle das, was minimal-invasiv ist, aber konsistent).
  - Bei Auswahl: Feld wird exakt mit dem Vorschlags-String befüllt.
  - Keine neuen Dependencies, wenn Flutter-Standard reicht. (Wenn bereits `RawAutocomplete` genutzt werden kann: bevorzugen.)
- Vorschlagsdaten einmal beim Öffnen des Create-Screens laden:
  - `repository.getAllSeeds()` oder entsprechender Call (nutze bestehende APIs).
  - Mappe auf die beiden Felder, distinct + sort (optional, aber nice).

TECHNISCHE ANFORDERUNGEN (Implementierung)
1) Modus-Erweiterung
- Erweitere SeedDetailScreenV2 um Create-Mode, ohne bestehendes Verhalten zu brechen.
- Stelle sicher:
  - Im Read/View-Mode ist keinerlei Interaktion möglich, außer bereits erlaubte Navigation/Swipe.
  - Interaktive Editierbarkeit wird nur in Edit/Create aktiv.

2) Create-Model/Initialwerte
- Implementiere eine Initialisierung für Create:
  - Neues `SeedDetailModel`/Seed (je nach bestehender Architektur) mit:
    - neuer `variety_id`
    - sinnvollen Default-Werten gemäß app_format_v1.md (wenn dort definiert)
    - ansonsten leer/null, aber UI muss damit klarkommen.
- Speichern:
  - Nutze Repository: neuer Eintrag wird hinzugefügt und persistiert.
  - Danach zurück zur Liste/Context, oder direkt in View-Mode des neu erstellten Seeds (wähle die Variante mit minimaler Änderung und konsistenter UX).

3) Validierung
- Beim Speichern im Create-Mode:
  - prüfe Pflichtfelder
  - prüfe Container-/Uniqueness-Constraints (soweit im app_format_v1.md gefordert / im bestehenden Code vorhanden)
  - bei Fehler: zeige SnackBar/Dialog, keine Persistenz

4) Tests (mindestens)
- Schreibe/erweitere Tests (unit oder widget – minimal sinnvoll):
  - Create: `create` führt zu +1 Eintrag, Persistenz nach Reload vorhanden.
  - Autocomplete: wenn Repository Seeds mit `latin_name`/`family` enthalten, erscheinen diese Vorschläge beim Tippen.
  - Cancel: Create abbrechen erzeugt keinen neuen Eintrag.
- Nutze bestehende Teststruktur und vorhandene Mock/Local Repository Utilities.

VORGEHEN (verbindlich)
1) Lies `docs/app_format_v1.md` vollständig und halte dich strikt daran.
2) Analysiere die bestehende Create/Update-Repository-API:
   - Falls `createSeed` nicht existiert: ergänze minimal eine `addSeed`/`createSeed` API analog zu `updateSeed`.
3) Implementiere Create-Mode in SeedDetailScreenV2 (Wiederverwendung!).
4) Implementiere Autocomplete für die zwei Felder.
5) Schreibe Tests.
6) `flutter test` muss grün sein.

SCOPE-DISZIPLIN (nicht tun)
- Keine Änderungen am Datenformat außerhalb dessen, was `docs/app_format_v1.md` erlaubt.
- Keine neue Screen-Architektur, keine großen Refactors.
- Kein Nextcloud, kein Supabase, keine Sync-Logik.
- Keine neuen Felder, die nicht im app_format_v1.md existieren.

ABGABE
- Liefere einen sauberen Diff.
- Stelle sicher, dass bestehender Edit-Mode unverändert funktioniert.
- Stelle sicher, dass View-Mode unverändert bleibt.
- Stelle sicher, dass Create-Mode alle Felder anbietet und Speichern funktioniert.

