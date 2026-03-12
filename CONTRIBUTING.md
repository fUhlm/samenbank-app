# Contributing

## Scope

Dieses Repository dokumentiert und entwickelt die öffentliche Flutter-App `samenbank-app`. Beiträge sollten sich auf nachvollziehbare, kleine Änderungen mit klarer Begründung konzentrieren.

## Setup

```bash
flutter pub get
flutter analyze
flutter test
```

Optional vor dem Commit:

```bash
dart format .
```

## Arbeitsweise

- Änderungen klein und thematisch zusammenhängend halten
- Bestehende Projektstruktur und Benennungen beibehalten
- Bei Änderungen am Datenmodell die Dokumentation in `docs/` mitprüfen und bei Bedarf aktualisieren
- Neue Logik nach Möglichkeit mit Tests absichern
- Keine Build-Artefakte, temporären Dateien oder lokalen Exportdateien committen
- Keine privaten Seed-Datensätze committen; im Repository bleiben nur Demo- oder Testdaten

## Pull Requests

- Kurz beschreiben, was geändert wurde und warum
- Relevante Screenshots anhängen, falls UI betroffen ist
- Erwähnen, welche Tests lokal ausgeführt wurden
- Offene Punkte oder bekannte Einschränkungen klar benennen

## Issues

Bug-Reports sind am hilfreichsten mit:

- kurzer Beschreibung des erwarteten und tatsächlichen Verhaltens
- Plattform bzw. Zielgerät
- Schritten zur Reproduktion
- falls möglich Beispiel-Daten oder Screenshots
