# Contributing

## English

### Scope

This repository contains the public Flutter app `samenbank-app`. Contributions should stay focused, understandable, and easy to review.

### Setup

```bash
flutter pub get
flutter analyze
flutter test
```

Optional before committing:

```bash
dart format .
```

### Working Style

- Keep changes small and logically grouped.
- Preserve the existing project structure and naming unless there is a clear reason to change them.
- If you change the data model, also review and update the relevant documentation in `docs/` when needed.
- Add tests for new logic whenever practical.
- Do not commit build artifacts, temporary files, or local export files.
- Publish release APKs through GitHub Releases instead of committing them to the repository.
- Do not commit private seed datasets; the repository should only contain demo or test data.

### Pull Requests

- Briefly describe what changed and why.
- Include relevant screenshots if the UI changed.
- Mention which tests were run locally.
- Clearly list open points or known limitations.

### Issues

Bug reports are most useful when they include:

- a short description of the expected and actual behavior
- the platform or target device
- steps to reproduce
- sample data or screenshots if available

## Deutsch

### Geltungsbereich

Dieses Repository dokumentiert und entwickelt die öffentliche Flutter-App `samenbank-app`. Beiträge sollten nachvollziehbar, klein und gut reviewbar bleiben.

### Setup

```bash
flutter pub get
flutter analyze
flutter test
```

Optional vor dem Commit:

```bash
dart format .
```

### Arbeitsweise

- Änderungen klein und thematisch zusammenhängend halten.
- Bestehende Projektstruktur und Benennungen beibehalten, sofern es keinen klaren Grund für Änderungen gibt.
- Bei Änderungen am Datenmodell die relevante Dokumentation in `docs/` mitprüfen und bei Bedarf aktualisieren.
- Neue Logik nach Möglichkeit mit Tests absichern.
- Keine Build-Artefakte, temporären Dateien oder lokalen Exportdateien committen.
- Release-APKs über GitHub Releases veröffentlichen und nicht im Repository committen.
- Keine privaten Seed-Datensätze committen; im Repository bleiben nur Demo- oder Testdaten.

### Pull Requests

- Kurz beschreiben, was geändert wurde und warum.
- Relevante Screenshots anhängen, falls die UI betroffen ist.
- Erwähnen, welche Tests lokal ausgeführt wurden.
- Offene Punkte oder bekannte Einschränkungen klar benennen.

### Issues

Bug-Reports sind am hilfreichsten mit:

- kurzer Beschreibung des erwarteten und tatsächlichen Verhaltens
- Plattform bzw. Zielgerät
- Schritten zur Reproduktion
- Beispiel-Daten oder Screenshots, falls vorhanden
