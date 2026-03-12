# App-Format v1 (lokale Working Copy)

## A) Ziel & Prinzipien

- Das App-Format v1 ist das lokale **Working-Copy-Format** auf dem Gerät und dient als kanonische Datenbasis für UI/Domain.
- `assets/seeds.json` bleibt ein **Import-/Legacy-Format**; Import-Transformationen werden beim Überführen ins App-Format aufgelöst.
- Das App-Format enthält **MonthRange-basierte** Zeitfenster (`activityWindows`, `displayWindows`) statt Monatslisten.
- `displayWindows` sind **reine Anzeige-Daten** und steuern **keine Relevanzberechnung**.
- Relevanzberechnung basiert ausschließlich auf `activityWindows` mit Domain-Types `DIRECT_SOW` und `PRE_CULTURE`.
- Das App-Format enthält **keine Fallback-Auflösung zur Laufzeit** (z. B. `meta.*` nach `cultivation.*`); die Working Copy liegt bereits in konsumierbarer Zielstruktur vor.
- Identität bleibt stabil und unveränderlich über `varietyId` + `taxonKey`; falls ein Container vorhanden ist, bleibt auch dessen `tubeCode` stabil.
- Referenz-/Container-IDs (`containerId`, `varietyRef`) sind im Working-Copy-Modell unveränderlich.
- Editierbarkeit gilt nur für Felder, die heute bereits im Modell/JSON vorhanden sind.

---

## B) Datenstruktur im App-Format v1 (Feldliste + Datentypen)

> Struktur pro Sorte (ein Eintrag der Working Copy).

### Root

- `varietyId: string` (required)
- `taxonKey: object` (required)
  - `category: string` (required; **stabiler Category-Enum-Key**, z. B. `FRUCHTGEMUESE`)
  - `species: string` (required)
  - `varietyName: string` (required)
- `latin_name: string | null` (optional)
- `container: object | null` (optional)
  - `containerId: string` (required, wenn `container != null`)
  - `varietyRef: string` (required, wenn `container != null`; muss `varietyId` entsprechen)
  - `tubeCode: object` (required, wenn `container != null`)
    - `color_key: string` (required)
    - `number: int` (required)
- `activityWindows: ActivityWindow[]` (required; kann leer sein)
- `displayWindows: object` (optional)
  - `auspflanzen: MonthRange[]` (optional)
  - `bluete: MonthRange[]` (optional)
  - `ernte: MonthRange[]` (optional)
  - Hinweis: Keys sind in v1 konstant (`auspflanzen`/`bluete`/`ernte`).
- `cultivation: object` (optional, Werte in v1 als Strings)
  - `freiland: string | null`
  - `gruenduengung: string | null`
  - `keimtemp_c: string | null`
  - `tiefe_cm: string | null`
  - `row_spacing_cm: string | null`
  - `plant_spacing_cm: string | null`
  - `plant_height_cm: string | null`
- `properties: object` (optional)
  - `eigenschaft: string | null`
- `botany: object` (optional)
  - `family: string | null`
- `flags: object` (optional)
  - `rebuild_required: boolean | null`
  - `variety_name_from_species: boolean`

> Hinweis: `cultivation`-Felder bleiben in App-Format v1 bewusst String-basiert wie im aktuellen Datenbestand. Eine spätere Normalisierung auf Number-Typen ist möglich, aber nicht Teil von v1.

### ActivityWindow

- `windowId: string` (optional; UI-/Persistenz-Hilfe, **keine** Domain-Identität)
- Falls `windowId` fehlt, wird die Position in `activityWindows[]` als Identifikator im UI/Edit-Flow verwendet.
- `type: string` (required; Domain-Enum-Key, z. B. `DIRECT_SOW`, `PRE_CULTURE`)
- `range: MonthRange` (required)

### MonthRange

- `start: int` (required; 1..12)
- `end: int` (required; 1..12)
- Wrap-around ist zulässig (z. B. `start=11`, `end=2`).

---

## C) Edit-Matrix (verbindlich)

| Feld | Editierbar? | Hinweis |
|---|---|---|
| `varietyId` | Nein (gesperrt) | Technische Identität, unveränderlich |
| `taxonKey.category` | Nein (gesperrt) | Teil der stabilen Identität |
| `taxonKey.species` | Nein (gesperrt) | Teil der stabilen Identität |
| `taxonKey.varietyName` | Nein (gesperrt) | Teil der stabilen Identität |
| `container.tubeCode.color_key` | Nein (gesperrt) | Teil des stabilen TubeCodes (falls Container vorhanden) |
| `container.tubeCode.number` | Nein (gesperrt) | Teil des stabilen TubeCodes (falls Container vorhanden) |
| `container.containerId` | Nein (gesperrt) | ID/Ref ist nicht änderbar (nur wenn `container != null`) |
| `container.varietyRef` | Nein (gesperrt) | ID/Ref ist nicht änderbar (nur wenn `container != null`) |
| `activityWindows` | Ja | Nur vorhandene Struktur/Felder |
| `displayWindows.*` | Ja | Nur vorhandene Struktur/Felder |
| `cultivation.*` | Ja | Nur vorhandene Struktur/Felder |
| `properties.*` | Ja | Nur vorhandene Struktur/Felder |
| `botany.*` | Ja | Nur vorhandene Struktur/Felder |
| `flags.*` | Ja | Nur vorhandene Struktur/Felder |
| `latin_name` | Ja | Falls vorhanden |

---

## D) Beispiel-JSON (genau 1 Sorte)

```json
{
  "varietyId": "paprika-rubin-glanz-a1b2c3",
  "taxonKey": {
    "category": "FRUCHTGEMUESE",
    "species": "Paprika",
    "varietyName": "Rubin Glanz"
  },
  "latin_name": "Capsicum annuum",
  "container": {
    "containerId": "Cpaprika-rubin-glanz-a1b2c3",
    "varietyRef": "paprika-rubin-glanz-a1b2c3",
    "tubeCode": {
      "color_key": "red",
      "number": 17
    }
  },
  "activityWindows": [
    {
      "windowId": "paprika-rubin-glanz-a1b2c3-directSow-1",
      "type": "DIRECT_SOW",
      "range": { "start": 4, "end": 5 }
    },
    {
      "type": "PRE_CULTURE",
      "range": { "start": 2, "end": 4 }
    }
  ],
  "displayWindows": {
    "auspflanzen": [
      { "start": 5, "end": 6 }
    ],
    "bluete": [
      { "start": 7, "end": 9 }
    ],
    "ernte": [
      { "start": 11, "end": 2 }
    ]
  },
  "cultivation": {
    "freiland": "nach den Eisheiligen",
    "gruenduengung": "Starkzehrer",
    "keimtemp_c": "20-24",
    "tiefe_cm": "0.5-1",
    "row_spacing_cm": "60",
    "plant_spacing_cm": "45",
    "plant_height_cm": "80"
  },
  "properties": {
    "eigenschaft": "mild, dickwandig"
  },
  "botany": {
    "family": "Solanaceae"
  },
  "flags": {
    "rebuild_required": null,
    "variety_name_from_species": false
  }
}
```

---

## E) Migration / Kompatibilität (kurz)

- `assets/seeds.json` ist **Import/Legacy**.
- Die lokale Working Copy im **App-Format v1 ist kanonisch**.
- Ein Legacy-Export zurück nach `assets/seeds.json` ist **optional und später**.

---

## Open Questions

1. Falls zukünftig `SEED_SAVING` als Activity-Typ verwendet wird: bleibt dieser strikt display-/meta-nah oder wird er als eigener Domain-ActivityType geführt?
2. Soll bei `container: null` zusätzlich eine explizite Kennzeichnung für „noch nicht eingetütet“ eingeführt werden, oder reicht `null` semantisch aus?
3. Sollen künftig alle String-Zahlenfelder in `cultivation` versioniert auf Number normalisiert werden (mit eindeutigem Migrationspfad)?
4. Falls später zwischen deutscher Art-Bezeichnung und lateinischer Art unterschieden wird: Soll `taxonKey.species` erweitert oder aufgeteilt werden?
