import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'src/data/working_copy_v1_initializer.dart';
import 'src/data/working_copy_uri_preferences.dart';
import 'src/platform/android_working_copy_saf.dart';
import 'src/repositories/local_seed_repository.dart';
import 'src/repositories/seed_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.uriPreferences,
    required this.saf,
  });

  final SeedRepository repository;
  final WorkingCopyUriPreferences uriPreferences;
  final AndroidWorkingCopySaf saf;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get _workingCopySelectionAvailable =>
      widget.repository is LocalSeedRepository;

  String get _workingCopyStatus {
    if (widget.repository is! LocalSeedRepository) {
      return 'Arbeitsdatei-Auswahl ist auf diesem Gerät nicht verfügbar.';
    }
    final repository = widget.repository as LocalSeedRepository;
    return repository.activeExternalWorkingCopyUri == null
        ? 'Aktiv: Interne Arbeitsdatei'
        : 'Aktiv: Externe Arbeitsdatei (z. B. Nextcloud)';
  }

  Future<void> _chooseWorkingCopy() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Bestehende Datei wählen'),
              onTap: () => Navigator.of(sheetContext).pop('existing'),
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Neue Datei anlegen'),
              onTap: () => Navigator.of(sheetContext).pop('create'),
            ),
          ],
        ),
      ),
    );

    if (action == 'existing') {
      await _chooseExistingWorkingCopy();
      return;
    }
    if (action == 'create') {
      await _createAndUseWorkingCopy();
    }
  }

  Future<void> _chooseExistingWorkingCopy() async {
    if (widget.repository is! LocalSeedRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arbeitsdatei-Auswahl ist nicht verfügbar.'),
        ),
      );
      return;
    }

    final repository = widget.repository as LocalSeedRepository;

    try {
      final uri = await widget.saf.pickJsonDocument();
      if (uri == null) {
        return;
      }

      await repository.setExternalWorkingCopyUri(uri);
      await widget.uriPreferences.saveUri(uri);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Arbeitsdatei gesetzt')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arbeitsdatei ungültig oder nicht lesbar: $error'),
        ),
      );
    }
  }

  Future<void> _createAndUseWorkingCopy() async {
    if (widget.repository is! LocalSeedRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arbeitsdatei-Auswahl ist nicht verfügbar.'),
        ),
      );
      return;
    }

    final repository = widget.repository as LocalSeedRepository;

    try {
      final initialPayload = await widget.repository.exportWorkingCopyJson();
      final uri = await widget.saf.createJsonDocument(
        fileName: appFormatV1FileName,
      );
      if (uri == null) {
        return;
      }

      await widget.saf.writeUri(uri, initialPayload);
      await repository.setExternalWorkingCopyUri(uri);
      await widget.uriPreferences.saveUri(uri);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neue Arbeitsdatei erstellt und gesetzt')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anlegen der Arbeitsdatei fehlgeschlagen: $error'),
        ),
      );
    }
  }

  Future<void> _resetWorkingCopyToInternal() async {
    if (widget.repository is! LocalSeedRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arbeitsdatei-Auswahl ist nicht verfügbar.'),
        ),
      );
      return;
    }

    final repository = widget.repository as LocalSeedRepository;

    try {
      await widget.uriPreferences.clearUri();
      await repository.clearExternalWorkingCopyUri();

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interne Arbeitsdatei aktiv')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zurücksetzen fehlgeschlagen: $error')),
      );
    }
  }

  Future<void> _reloadWorkingCopy() async {
    if (widget.repository is! LocalSeedRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arbeitsdatei-Auswahl ist nicht verfügbar.'),
        ),
      );
      return;
    }

    final repository = widget.repository as LocalSeedRepository;

    try {
      await repository.reloadFromActiveWorkingCopy();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arbeitsdatei neu geladen')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Neu laden fehlgeschlagen: $error')),
      );
    }
  }

  Future<void> _exportBackup() async {
    try {
      final json = await widget.repository.exportWorkingCopyJson();
      final path = await _saveBackupWithDialog(json);
      if (path == null || path.trim().isEmpty || !mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export gespeichert: $path')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export fehlgeschlagen: $error')));
    }
  }

  Future<String?> _saveBackupWithDialog(String json) async {
    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Backup speichern unter',
        fileName: appFormatV1FileName,
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        bytes: utf8.encode(json),
      );
      if (savedPath != null && savedPath.trim().isNotEmpty) {
        return savedPath.trim();
      }
      return null;
    } catch (_) {
      // saveFile is not available on all platforms. Fall back to folder picker.
    }

    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Backup-Ordner wählen',
    );
    if (directory == null || directory.trim().isEmpty) {
      return null;
    }
    final targetPath =
        '$directory${Platform.pathSeparator}$appFormatV1FileName';
    final file = File(targetPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(json);
    return targetPath;
  }

  Future<void> _importBackup() async {
    final shouldImport = await _showImportConfirmDialog();
    if (!shouldImport || !mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        allowMultiple: false,
      );
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null || path.trim().isEmpty) {
        throw const FormatException('Dateipfad konnte nicht gelesen werden.');
      }

      final payload = await File(path).readAsString();
      await widget.repository.importWorkingCopyJson(payload);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import erfolgreich übernommen.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ungültiges Datenformat. Import abgebrochen.'),
        ),
      );
    }
  }

  Future<bool> _showImportConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import bestätigen'),
        content: const Text(
          'Import überschreibt alle aktuellen Daten. Fortfahren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Export (Backup)'),
            subtitle: const Text('Aktuelle Arbeitsdatei als JSON speichern'),
            trailing: const Icon(Icons.upload_file_outlined),
            onTap: _exportBackup,
          ),
          ListTile(
            title: const Text('Import (überschreibt)'),
            subtitle: const Text('JSON laden und komplette Daten ersetzen'),
            trailing: const Icon(Icons.download_outlined),
            onTap: _importBackup,
          ),
          ListTile(
            title: const Text('Arbeitsdatei wählen'),
            subtitle: Text(_workingCopyStatus),
            trailing: const Icon(Icons.folder_open_outlined),
            onTap: _chooseWorkingCopy,
          ),
          if (_workingCopySelectionAvailable)
            const ListTile(
              title: Text('Erweitert'),
              dense: true,
            ),
          if (_workingCopySelectionAvailable)
            ListTile(
              title: const Text('Arbeitsdatei neu laden'),
              subtitle: const Text(
                'Aktuelle Datei manuell neu einlesen (selten nötig)',
              ),
              trailing: const Icon(Icons.refresh_outlined),
              onTap: _reloadWorkingCopy,
            ),
          if (_workingCopySelectionAvailable)
            ListTile(
              title: const Text('Auf Dummy-Daten zurücksetzen'),
              trailing: const Icon(Icons.restore_outlined),
              onTap: _resetWorkingCopyToInternal,
            ),
        ],
      ),
    );
  }
}
