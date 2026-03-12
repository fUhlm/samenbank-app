# Samenbank – Domain Contract v1.2

Status: verbindlich für Domain-Logik (Monatsrelevanz)  
Zweck: Single Source of Truth für Begriffe, Invarianten und Relevanzlogik der App.

---

## 1. Zweck & Nicht-Ziele

Die Domain beantwortet ausschließlich:

- **Welche Sorten sind in einem Monat relevant?**

Nicht Teil der Domain:
- To-Dos, Erinnerungen, Benachrichtigungen
- Priorisierung/Dringlichkeit
- Wetter/Standort/Mikroklima
- UI- oder Backend-Details

**Kernfestlegung v1.2:**  
- **Kalenderrelevanz** wird ausschließlich aus **Aussaat** und **Voranzucht** abgeleitet.  
- **Auspflanzen**, **Blüte**, **Ernte** sind **reine Anzeige** und erzeugen **keine** Relevanz.  
- **Nachbau** ist **kein** Kalender-Event; bleibt als Flag/Feld (Meta/Anzeige).

---

## 2. Zeitmodell

### MonthOfYear
- Wertebereich: **1..12**
- Zyklisch (Ringmodell)

Hilfsfunktionen (normativ):
- `prevMonth(m) = ((m + 10) mod 12) + 1`
- `nextMonth(m) = (m mod 12) + 1`

---

## 3. Entitäten & Identität

### 3.1 Variety (Sorte)
Repräsentiert eine Sorte als fachliches Konzept.

Pflichtattribute:
- `varietyId`
- `taxonKey`: `category`, `species`, `varietyName`
- `activityWindows: List<ActivityWindow>` (**nur** Aussaat/Voranzucht)

Optionale Anzeigeattribute (nicht relevant-machend):
- `displayWindows` (Auspflanzen/Blüte/Ernte; Anzeige)
- `seedSaving` (Nachbau-Info; Anzeige/Meta)

Identitätsregeln:
- `varietyId` ist primäre technische Identität.
- `taxonKey` ist fachlich eindeutig.
- Zwei Varieties mit identischem `taxonKey` sind unzulässig.

### 3.2 TubeCode (Röhrchen-Code)
Physischer Identifikationscode:
- `colorKey`
- `number`

Regeln:
- `(colorKey, number)` ist eindeutig.
- `number` wird numerisch sortiert (2 < 10).

> Hinweis: Die Variety existiert unabhängig vom Röhrchen. Röhrchen können später recycelt werden.

---

## 4. Kalenderlogik: Aktivitäten & Zeitfenster

### 4.1 ActivityType (NUR kalenderrelevant)
- `DIRECT_SOW`  (Aussaat)
- `PRE_CULTURE` (Voranzucht)

Es gibt **keinen** ActivityType für:
- Auspflanzen
- Blüte
- Ernte
- Nachbau

### 4.2 ActivityWindow
Attribute:
- `type: ActivityType`
- `range: MonthRange(start, end)` (inklusive; ggf. wrap-around)

`MonthRange.contains(m)`:
- Falls `start <= end`: `start <= m <= end`
- Falls `start > end`: `m >= start OR m <= end`

---

## 5. Statuslogik (START / LÄUFT / ENDET)

Für ein ActivityWindow, das in Monat `m` aktiv ist:

- `starts`: aktiv in `m` UND NICHT aktiv in `prevMonth(m)`
- `continues`: aktiv in `m` UND aktiv in `prevMonth(m)`
- `ends`: aktiv in `m` UND NICHT aktiv in `nextMonth(m)`

Ein-Monats-Fenster (`start == end`):
- `starts == true`
- `ends == true`
(im selben Monat)

---

## 6. Aggregation: ActivityInMonth

Für jede Variety, jeden Monat `m` und jeden ActivityType `t`:

- `activeWindows = alle Fenster dieses Typs, die in m aktiv sind`
- `starts = OR(starts(window) über activeWindows)`
- `continues = OR(continues(window) über activeWindows)`
- `ends = OR(ends(window) über activeWindows)`

Wenn `activeWindows` leer:
- alle Flags `false`

---

## 7. Relevanz & Phase (NUR Aussaat/Voranzucht)

### 7.1 Relevanz
Eine Variety ist in Monat `m` **relevant**, wenn mindestens ein ActivityWindow
vom Typ `DIRECT_SOW` oder `PRE_CULTURE` in `m` aktiv ist.

Anzeige-Felder (Auspflanzen/Blüte/Ernte) beeinflussen Relevanz **nicht**.

### 7.2 RelevancePhase (pro Variety, pro Monat)
Priorität ist strikt:

1. `NEW`  
   wenn EXISTS ActivityInMonth mit `starts == true`
2. `ONGOING`  
   sonst, wenn EXISTS ActivityInMonth mit `continues == true`
3. `ENDING`  
   sonst, wenn EXISTS ActivityInMonth mit `ends == true`
4. `NONE`

Ein-Monats-Fenster werden immer als `NEW` klassifiziert.

---

## 8. Sortierlogik (Domain-verbindlich)

Sortierung in Monatsübersichten:

1. `RelevancePhase`: `NEW` → `ONGOING` → `ENDING`
2. CategoryOrder (fachliche Reihenfolge; falls vorhanden)
3. `species` (alphabetisch)
4. `varietyName` (alphabetisch)
5. TubeCode: `number` (numerisch)

---

## 9. Display-Daten (nicht relevant-machend)

### 9.1 DisplayWindows (optional)
- `transplantMonths` (Auspflanzen; Anzeige)
- `bloomMonths` (Blüte; Anzeige)
- `harvestMonths` (Ernte; Anzeige)

### 9.2 SeedSaving (Nachbau; optional)
- `rebuildRequired: boolean?`
- optional `note: string?`

**Regel:** Display/SeedSaving erzeugen **keine** Kalenderrelevanz.

---

**Ende – Domain Contract v1.2**
