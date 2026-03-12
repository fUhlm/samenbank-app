# Mapping-Tabelle: `assets/seeds.json` → Domain/UI

Diese Übersicht beschreibt den **Ist-Stand im Code** beim Import über `SeedJsonLoader`/`SeedJsonMapper` und die Nutzung in der UI.

## 1) Direkt gemappte Felder

| JSON-Pfad in `seeds.json` | Domain-Ziel (Model) | UI-Nutzung | Status | Hinweise |
|---|---|---|---|---|
| `variety_id` | `SeedDetailModel.id`, `Variety.varietyId` | Navigation/Lookup (`seedId`) | ✅ korrekt | Zentrale technische ID. |
| `category` | `TaxonKey.category` (Enum-Mapping), `SeedDetailModel.gruppe` | Gruppierung/Sortierung + Detail „Identifikation“ | ✅ korrekt | Unbekannte Labels werden `Category.unknown`. |
| `species` | `TaxonKey.species`, `SeedDetailModel.art` | Listen-Subtitle + Detail „Identifikation“ | ✅ korrekt | |
| `variety_name` | `TaxonKey.varietyName`, `SeedDetailModel.sorte` | Listen-Titel + Detail-Header | ✅ korrekt | |
| `latin_name` | `SeedDetailModel.lateinischerName` | Detail-Kopfzeile (Botanikline) | ✅ korrekt | |
| `container.tube_number` | `SeedContainer.tubeCode.number`, `SeedDetailModel.codeNumber` | Badge/Kreisnummer in Listen + Detail | ✅ korrekt | String/Int wird als int geparst. |
| `container.tube_color_key` | `SeedContainer.tubeCode.color`, `SeedDetailModel.codeColorValue` | Badge/Kreisfarbe in Listen + Detail | ✅ korrekt | Nur `red/green/blue/yellow/white` erlaubt. |
| `calendar.aussaat[]` | `ActivityWindow(type: directSow, range: MonthRange)` | Monatsrelevanz + Kalendersektion Detail | ✅ korrekt | Monate werden zu Bereichen komprimiert. |
| `calendar.voranzucht[]` | `ActivityWindow(type: preCulture, range: MonthRange)` | Monatsrelevanz + Kalendersektion Detail | ✅ korrekt | Monate werden zu Bereichen komprimiert. |
| `botany.family` | `SeedDetailModel.familie` | Detail-Kopfzeile (Botanikline) | ✅ korrekt | |
| `properties.eigenschaft` | `SeedDetailModel.eigenschaft` | Detail „Eigenschaften“ | ✅ korrekt | |
| `cultivation.freiland` + Fallback `properties.freiland` | `SeedDetailModel.freiland` | Detail „Eigenschaften“ | ✅ korrekt | `cultivation` priorisiert. |
| `cultivation.gruenduengung` + Fallback `properties.gruenduengung` | `SeedDetailModel.gruenduengung` | Detail „Eigenschaften“ | ✅ korrekt | `cultivation` priorisiert. |
| `flags.rebuild_required` | `SeedDetailModel.nachbauNotwendig` (`bool`→`ja/nein`) | Badge/Filter „Nachbau notwendig“ + Detail | ✅ korrekt | Wenn Bool, Anzeige als `ja/nein`. |
| `cultivation.keimtemp_c` + Fallback `cultivation.germination_temp_c` + `meta.keimtemp_c` | `SeedDetailModel.keimtempC` | Detail „Keimung & Aussaat“ | ✅ korrekt | Reale Seeds-Keynamen berücksichtigt. |
| `cultivation.tiefe_cm` + Fallback `cultivation.sowing_depth_cm` + `meta.tiefe_cm` | `SeedDetailModel.tiefeCm` | Detail „Keimung & Aussaat“ | ✅ korrekt | Reale Seeds-Keynamen berücksichtigt. |
| `cultivation.row_spacing_cm` | `SeedDetailModel.abstandReiheCm` | Detail „Pflanzabstände“ | ✅ korrekt | |
| `cultivation.plant_spacing_cm` | `SeedDetailModel.abstandPflanzeCm` | Detail „Pflanzabstände“ | ✅ korrekt | |
| `cultivation.plant_height_cm` | `SeedDetailModel.hoehePflanzeCm` | Detail „Pflanzenhöhe“ | ✅ korrekt | |
| `calendar.auspflanzen[]` | `SeedDetailModel.auspflanzenRanges` | Modell vorhanden, aktuell keine Anzeige | ✅ korrekt | Display-only, keine Relevanzphase. |
| `calendar.bluete[]` | `SeedDetailModel.blueteRanges` | Modell vorhanden, aktuell keine Anzeige | ✅ korrekt | Display-only, keine Relevanzphase. |
| `calendar.ernte[]` | `SeedDetailModel.ernteRanges` | Modell vorhanden, aktuell keine Anzeige | ✅ korrekt | Display-only, keine Relevanzphase. |
| `meta.abstand_reihe_cm` | Fallback für `SeedDetailModel.abstandReiheCm` | Detail „Abstände & Wuchs“ | ✅ korrekt | Wird genutzt, wenn `cultivation.row_spacing_cm` fehlt. |
| `meta.abstand_pflanze_cm` | Fallback für `SeedDetailModel.abstandPflanzeCm` | Detail „Abstände & Wuchs“ | ✅ korrekt | Wird genutzt, wenn `cultivation.plant_spacing_cm` fehlt. |
| `meta.hoehe_cm` | Fallback für `SeedDetailModel.hoehePflanzeCm` | Detail „Abstände & Wuchs“ | ✅ korrekt | Wird genutzt, wenn `cultivation.plant_height_cm` fehlt. |
| `flags.variety_name_from_species` | `SeedDetailModel.varietyNameFromSpecies` | Aktuell keine explizite Anzeige | ✅ gemappt | Für spätere UI/QA verfügbar. |

## 2) Fehlende bzw. nicht korrekt zugeordnete Felder

| JSON-Pfad in `seeds.json` | Erwartung (fachlich/Contract) | Ist-Stand im Code | Wirkung in UI | Status |
|---|---|---|---|---|
| `calendar.auspflanzen[]` | Display-only Anzeige | In Modell gemappt, aktuell nicht gerendert | Kein UI-Effekt | ℹ️ nicht angezeigt |
| `calendar.bluete[]` | Display-only Anzeige | In Modell gemappt, aktuell nicht gerendert | Kein UI-Effekt | ℹ️ nicht angezeigt |
| `calendar.ernte[]` | Display-only Anzeige | In Modell gemappt, aktuell nicht gerendert | Kein UI-Effekt | ℹ️ nicht angezeigt |
| `flags.variety_name_from_species` | Datenqualitäts-Flag | Wird ins Modell gemappt, aber nicht visualisiert | Kein UI-Effekt | ℹ️ nicht angezeigt |
| Top-Level `version` | Metadatum | Wird geladen, aber nicht genutzt | Kein UI-Effekt | ℹ️ ungenutzt |
| Top-Level `generated_at` | Metadatum | Wird geladen, aber nicht genutzt | Kein UI-Effekt | ℹ️ ungenutzt |

## 3) Validierung/Fehlerfälle beim Import

| Bereich | Validierung im Code | Fehlerverhalten |
|---|---|---|
| Asset laden | Datei muss in `pubspec` als Asset verfügbar sein | `FlutterError` mit Hinweis auf Pfad |
| JSON parsebar | Top-Level muss Objekt sein | `FormatException` |
| Struktur | Top-Level `seeds` muss Liste sein | `FormatException` |
| Pflichtfelder | z. B. `variety_id`, `category`, `species`, `variety_name`, `container` | `FormatException` |
| Monate | Werte müssen `1..12` sein | `FormatException` |
| Tube-Farbe | Nur bekannte Farbkeys | `FormatException` |
| Eindeutigkeit | `variety_id` und `tubeCode` eindeutig | `StateError` |

## 4) Kurzfazit

- Das produktive Mapping deckt die Kernfelder für Listen/Detailansicht sauber ab.
- Mapping für Kernfelder inkl. Display-Kalender (`auspflanzen`, `bluete`, `ernte`) ist im Modell vorhanden, aber aktuell noch nicht sichtbar in der UI.
- `meta.*`-Werte für Abstände/Höhe werden als Fallback verwendet, falls in `cultivation.*` keine Werte stehen.
