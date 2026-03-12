# Data Contract – `assets/seeds.json` (Domain Contract v1.2)

Status: verbindlich für Import/Mapping von `assets/seeds.json`  
Zweck: präziser Vertrag für Struktur, Feldtypen, Required/Optional, Validierung & Fehlerfälle.

---

## 1) Datei-Überblick

- **Dateiname:** `assets/seeds.json`
- **Encoding:** UTF-8
- **Top-Level Struktur:** Objekt mit optionalen Metadaten + `seeds` Liste
  - `seeds` (Array von Seed-Objekten) **required**
  - `version` (int) **optional**
  - `generated_at` (string ISO-8601) **optional**
- **Eindeutigkeitsregeln:**
  - `seeds[].variety_id` **muss eindeutig** innerhalb der Datei sein.
  - `(seeds[].container.tube_color_key, seeds[].container.tube_number)` **muss eindeutig** innerhalb der Datei sein.

> `version`/`generated_at` sind forward-compatible. Ihr Fehlen ist **kein** Formatfehler.

---

## 2) Entity-Definition: Seed (JSON)

| JSON-Pfad | Typ | Required | Default (Mapper) | Semantik/Bedeutung | Validierungsregeln |
|---|---|---:|---|---|---|
| `variety_id` | string | ja | – | **Einzige** technische Identität der Sorte (VarietyId). | Nicht leer; eindeutig in `seeds`; siehe ID-Regel (Abschnitt 5). |
| `category` | string | ja | – | Kategorie (z. B. „Fruchtgemüse“, „Kräuter“). | Nicht leer. |
| `species` | string | ja | – | Art/Gattung im UI-Kontext. | Nicht leer. |
| `variety_name` | string | ja | – | Sortenname (ggf. aus `species` übernommen). | Nicht leer. Darf == `species` sein, wenn `flags.variety_name_from_species == true`. |
| `latin_name` | string \| null | optional | null | Botanischer Name. | String oder `null`. |
| `container` | object | ja | – | Behälter-/Tube-Daten (TubeCode). | Objekt vorhanden. |
| `container.tube_number` | string | ja | – | Tube-Nummer (als String). | Nicht leer. Empfehlung: nur Ziffern. |
| `container.tube_color_key` | string | ja | – | Farb-Schlüssel (z. B. „red“, „white“). | Nicht leer. |
| `botany` | object | optional | `{}` | Botanische Daten. | Objekt, freie Struktur erlaubt. |
| `properties` | object | optional | `{}` | Zusätzliche Eigenschaften. | Objekt, freie Struktur erlaubt. |
| `cultivation` | object | optional | `{}` | Anbau-/Kulturdaten. | Objekt, freie Struktur erlaubt. |
| `flags` | object | optional | `{}` | Status-/Daten-Flags. | Objekt, freie Struktur erlaubt. |
| `flags.rebuild_required` | boolean \| null | optional | null | **Nachbau-Flag** (Anzeige/Meta). | Boolean oder `null`. **Keine** Kalenderrelevanz. |
| `flags.variety_name_from_species` | boolean | optional | false | Hinweis: `variety_name` wurde aus `species` abgeleitet. | Boolean. |
| `calendar` | object | optional | `{}` | Monatszuordnungen für Actions/Anzeige. | Objekt, freie Struktur erlaubt. |
| `calendar.aussaat` | list<int> | optional | `[]` | **Aussaat** (DIRECT_SOW) – kalenderrelevant. | Monate 1–12, keine Duplikate. |
| `calendar.voranzucht` | list<int> | optional | `[]` | **Voranzucht** (PRE_CULTURE) – kalenderrelevant. | Monate 1–12, keine Duplikate. |
| `calendar.auspflanzen` | list<int> | optional | `[]` | **Auspflanzen** – **nur Anzeige**. | Monate 1–12, keine Duplikate. |
| `calendar.bluete` | list<int> | optional | `[]` | **Blüte** – **nur Anzeige**. | Monate 1–12, keine Duplikate. |
| `calendar.ernte` | list<int> | optional | `[]` | **Ernte** – **nur Anzeige**. | Monate 1–12, keine Duplikate. |
| `meta` | object | optional | `{}` | Metadaten. | Objekt, freie Struktur erlaubt. |

**Optional bedeutet:** Feld darf fehlen; Mapper setzt Defaults.  
**Für `calendar.*`:** `null` ist **nicht** zulässig (entweder Feld fehlt oder ist Liste).

---

## 3) Strikte Trennung „Actions“ vs „Display“ (Domain Contract v1.2)

### Kalenderrelevante Actions (erzeugen ActivityType)
- `calendar.aussaat` → **DIRECT_SOW**
- `calendar.voranzucht` → **PRE_CULTURE**

### Reine Anzeige (keine Kalenderrelevanz)
- `calendar.auspflanzen` → Anzeige
- `calendar.bluete` → Anzeige
- `calendar.ernte` → Anzeige

### Nachbau (kein Kalender-Element)
- `flags.rebuild_required` → Nachbau-Flag (Meta/Anzeige), **keine** Aktivität.

---

## 4) Monatsspezifikation

- **Erlaubte Repräsentation:** Liste von Monaten als Ganzzahlen: `[]`, `[1, 2, 3]`
- **Ranges:** nicht definiert (nicht gültig)
- **Validierung:**
  - Monat muss `1..12` sein
  - keine Duplikate pro Feld
- **Leere Liste:** „keine Monate“

---

## 5) ID-Regel: `variety_id` (Slug + kurzer Hash)

`variety_id` muss deterministisch erzeugbar sein (reproduzierbarer Export).

**Format (empfohlen):**  
`"<speciesSlug>-<varietySlug>-<hash6>"`  
Beispiel: `tomate-ruthje-9f3a2c`

**Slug-Regeln (normativ):**
- trim, lower-case
- ä→ae, ö→oe, ü→ue, ß→ss
- nicht-alphanumerisch → `-`
- mehrfach `-` zusammenfassen, Rand-`-` entfernen

**Hash-Regel (normativ):**
- canonical input: `"<category>|<species>|<variety_name>"`
- Hash-Algorithmus: **fix wählen** (z. B. SHA-1 oder SHA-256)
- `hash6`: erste 6 Hex-Zeichen

> Hinweis: Der Hash reduziert Kollisionen bei gleichen Namen in unterschiedlichen Kategorien.

---

## 6) Fehlerfälle & Fehlermeldungen (Mapper/Loader)

### Fehlerfälle
1. Missing required: `variety_id`, `category`, `species`, `variety_name`, `container.*`
2. Wrong type (z. B. `calendar.aussaat` ist String)
3. Invalid month (0, 13, …)
4. Duplicate `variety_id`
5. Duplicate TubeCode (`tube_color_key + tube_number`)

### Beispiel-Fehlermeldungen
- `SeedJsonFormatError: seed[12].variety_id missing (required)`
- `SeedJsonFormatError: seed[5].calendar.aussaat expected list<int>, got string`
- `SeedJsonFormatError: seed[3].calendar.voranzucht contains invalid month 13 (allowed 1..12)`
- `SeedJsonFormatError: duplicate variety_id "tomate-ruthje-9f3a2c" at seed[18]`
- `SeedJsonFormatError: duplicate tubeCode "white-15" at seed[42]`

---

## 7) Beispiele

### Minimal gültiger Seed
```json
{
  "variety_id": "tomate-ruthje-9f3a2c",
  "category": "Fruchtgemüse",
  "species": "Tomate",
  "variety_name": "Ruthje",
  "container": { "tube_number": "7", "tube_color_key": "red" },
  "calendar": { "aussaat": [3, 4], "voranzucht": [2, 3] }
}
```

### Vollständiger Seed (inkl. Anzeige + Flags)
```json
{
  "variety_id": "karotte-rodelika-41b8d0",
  "category": "Sonstige",
  "species": "Karotte",
  "variety_name": "Rodelika",
  "latin_name": "Daucus carota",
  "container": { "tube_number": "35", "tube_color_key": "white" },
  "flags": { "rebuild_required": null, "variety_name_from_species": false },
  "calendar": {
    "aussaat": [3, 4, 5],
    "voranzucht": [],
    "auspflanzen": [5, 6],
    "bluete": [],
    "ernte": [8, 9, 10]
  },
  "meta": {}
}
```

---

## Impact (max 10)
- **Nur eine ID:** `variety_id` ist die einzige Identität; kein `id`/Alias.
- **Kalenderrelevanz:** ausschließlich `aussaat` + `voranzucht`.
- **Display-only:** `auspflanzen`, `bluete`, `ernte`.
- **Nachbau:** `flags.rebuild_required` bleibt Flag/Meta.
- **Robuster Import:** optionale Objekte + Defaults im Mapper.
- **Validierung:** Monate, Unique `variety_id`, Unique TubeCode.
- **Keine UI-Änderungen. Keine neue Fachlogik.**

