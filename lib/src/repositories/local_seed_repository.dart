import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/seed_json_mapper.dart';
import '../data/working_copy_v1_initializer.dart';
import '../models/month_range.dart';
import '../types/enums.dart';
import 'seed_repository.dart';

class LocalSeedRepository implements SeedRepository {
  LocalSeedRepository({
    required WorkingCopyV1Initializer initializer,
    SeedJsonMapper? mapper,
    Future<Directory> Function()? documentsDirectoryProvider,
    ExternalWorkingCopyDataSource? externalWorkingCopyDataSource,
    String? externalWorkingCopyUri,
  }) : _initializer = initializer,
       _mapper = mapper ?? const SeedJsonMapper(),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _externalWorkingCopyDataSource =
           externalWorkingCopyDataSource ??
           const NoopExternalWorkingCopyDataSource(),
       _configuredExternalWorkingCopyUri = _normalizeUri(
         externalWorkingCopyUri,
       );

  final WorkingCopyV1Initializer _initializer;
  final SeedJsonMapper _mapper;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final ExternalWorkingCopyDataSource _externalWorkingCopyDataSource;
  String? _configuredExternalWorkingCopyUri;
  String? _activeExternalWorkingCopyUri;
  String? _activeExternalSnapshotJson;
  String? _initWarning;

  List<Seed>? _cache;
  Future<void>? _initFuture;

  String? get activeExternalWorkingCopyUri => _activeExternalWorkingCopyUri;

  String? consumeInitWarning() {
    final warning = _initWarning;
    _initWarning = null;
    return warning;
  }

  /// Load and cache the seed data before calling getAllSeeds/getSeedById.
  /// AP4.3 wiring: call await init() in the composition root (e.g. main())
  /// before runApp to ensure the repository is ready.
  Future<void> init() async {
    _initFuture ??= _loadSeeds();
    await _initFuture;
  }

  Future<void> setExternalWorkingCopyUri(String uri) async {
    final normalizedUri = _normalizeUri(uri);
    if (normalizedUri == null) {
      throw const FormatException('Die URI der Arbeitsdatei ist leer.');
    }

    await _reloadExternalWorkingCopyIntoCache(normalizedUri);

    _configuredExternalWorkingCopyUri = normalizedUri;
    _activeExternalWorkingCopyUri = normalizedUri;
  }

  Future<void> clearExternalWorkingCopyUri() async {
    _configuredExternalWorkingCopyUri = null;
    _activeExternalWorkingCopyUri = null;
    _activeExternalSnapshotJson = null;
    _initFuture = null;
    await init();
  }

  Future<void> reloadFromActiveWorkingCopy() async {
    final activeExternalUri = _activeExternalWorkingCopyUri;
    if (activeExternalUri != null) {
      await _reloadExternalWorkingCopyIntoCache(activeExternalUri);
      return;
    }

    final workingCopyFile = await _workingCopyFile();
    if (!await workingCopyFile.exists()) {
      throw const FileSystemException('Working copy missing');
    }
    final seeds = await _loadWorkingCopySeeds(workingCopyFile);
    _validateUniqueSeeds(seeds);
    _cache = seeds;
  }

  @override
  List<Seed> getAllSeeds() {
    final seeds = _cache;
    if (seeds == null) {
      throw StateError(
        'LocalSeedRepository not initialized. Call init() first.',
      );
    }
    return List<Seed>.unmodifiable(seeds);
  }

  @override
  Seed getSeedById(String id) {
    final seeds = _cache;
    if (seeds == null) {
      throw StateError(
        'LocalSeedRepository not initialized. Call init() first.',
      );
    }
    final match = seeds.cast<Seed?>().firstWhere(
      (seed) => seed?.id == id,
      orElse: () => null,
    );
    if (match == null) {
      throw StateError('Seed with id "$id" not found.');
    }
    return match;
  }

  @override
  Future<void> createSeed(AppSeed seed) async {
    if (_activeExternalWorkingCopyUri != null) {
      await _reloadExternalWorkingCopyIntoCache(_activeExternalWorkingCopyUri!);
    }
    final seeds = _cache;
    if (seeds == null) {
      throw StateError(
        'LocalSeedRepository not initialized. Call init() first.',
      );
    }

    _validateSeedForSave(seed);

    final updatedSeeds = List<Seed>.from(seeds)..add(seed);
    _validateUniqueSeeds(updatedSeeds);

    final jsonPayload = <Map<String, dynamic>>[
      for (final item in updatedSeeds) _seedToAppFormatV1(item),
    ];
    await _writeWorkingCopyJson(jsonEncode(jsonPayload));

    _cache = updatedSeeds;
  }

  @override
  Future<void> updateSeed(AppSeed updatedSeed) async {
    if (_activeExternalWorkingCopyUri != null) {
      await _reloadExternalWorkingCopyIntoCache(_activeExternalWorkingCopyUri!);
    }
    final seeds = _cache;
    if (seeds == null) {
      throw StateError(
        'LocalSeedRepository not initialized. Call init() first.',
      );
    }

    _validateSeedForSave(updatedSeed);

    final targetVarietyId = updatedSeed.variety.varietyId.trim();
    final index = seeds.indexWhere(
      (seed) => seed.variety.varietyId == targetVarietyId,
    );
    if (index < 0) {
      throw StateError('Seed with varietyId "$targetVarietyId" not found.');
    }

    final updatedSeeds = List<Seed>.from(seeds);
    updatedSeeds[index] = updatedSeed;

    _validateUniqueSeeds(updatedSeeds);

    final jsonPayload = <Map<String, dynamic>>[
      for (final seed in updatedSeeds) _seedToAppFormatV1(seed),
    ];
    await _writeWorkingCopyJson(jsonEncode(jsonPayload));

    _cache = updatedSeeds;
  }

  @override
  Future<void> deleteSeed(String varietyId) async {
    if (_activeExternalWorkingCopyUri != null) {
      await _reloadExternalWorkingCopyIntoCache(_activeExternalWorkingCopyUri!);
    }
    final seeds = _cache;
    if (seeds == null) {
      throw StateError(
        'LocalSeedRepository not initialized. Call init() first.',
      );
    }

    final targetVarietyId = varietyId.trim();
    final index = seeds.indexWhere(
      (seed) => seed.variety.varietyId == targetVarietyId,
    );
    if (index < 0) {
      throw StateError('Seed with varietyId "$targetVarietyId" not found.');
    }

    final updatedSeeds = List<Seed>.from(seeds)..removeAt(index);

    final jsonPayload = <Map<String, dynamic>>[
      for (final seed in updatedSeeds) _seedToAppFormatV1(seed),
    ];
    await _writeWorkingCopyJson(jsonEncode(jsonPayload));

    _cache = updatedSeeds;
  }

  @override
  Future<String> exportWorkingCopyJson() async {
    final seeds = _cache;
    if (seeds == null) {
      throw StateError(
        'LocalSeedRepository not initialized. Call init() first.',
      );
    }
    if (_activeExternalWorkingCopyUri != null) {
      final json = await _externalWorkingCopyDataSource.read(
        _activeExternalWorkingCopyUri!,
      );
      _activeExternalSnapshotJson = json;
      return json;
    }
    final workingCopyFile = await _workingCopyFile();
    if (!await workingCopyFile.exists()) {
      throw const FileSystemException('Working copy missing');
    }
    return workingCopyFile.readAsString();
  }

  @override
  Future<void> importWorkingCopyJson(String json) async {
    final seeds = _cache;
    if (seeds == null) {
      throw StateError(
        'LocalSeedRepository not initialized. Call init() first.',
      );
    }

    final importedSeeds = _decodeAndValidateImportPayload(json);
    _validateUniqueSeeds(importedSeeds);

    await _writeWorkingCopyJson(json);
    _cache = importedSeeds;
  }

  Future<void> _loadSeeds() async {
    final seeds = await loadSeedsWorkingCopyFirst();
    try {
      _validateUniqueSeeds(seeds);
    } catch (error) {
      rethrow;
    }

    _cache = seeds;
  }

  Future<List<Seed>> loadSeedsWorkingCopyFirst() async {
    final uri = _configuredExternalWorkingCopyUri;
    if (uri != null) {
      try {
        final seeds = await _reloadExternalWorkingCopyIntoCache(uri);
        return seeds;
      } catch (error) {
        _activeExternalWorkingCopyUri = null;
        _activeExternalSnapshotJson = null;
        _configuredExternalWorkingCopyUri = null;
        _initWarning =
            'Gespeicherte Arbeitsdatei nicht lesbar. Interne Datei wird verwendet.';
      }
    }

    final workingCopyFile = await _workingCopyFile();
    try {
      if (!await workingCopyFile.exists()) {
        throw const FileSystemException('Working copy missing');
      }

      final seeds = await _loadWorkingCopySeeds(workingCopyFile);
      return seeds;
    } catch (_) {
      if (await workingCopyFile.exists()) {
        await workingCopyFile.delete();
      }
      await _initializer.ensureWorkingCopy();
      final seeds = await _loadWorkingCopySeeds(workingCopyFile);
      return seeds;
    }
  }

  Future<File> _workingCopyFile() async {
    final documentsDirectory = await _documentsDirectoryProvider();
    return File('${documentsDirectory.path}/$appFormatV1FileName');
  }

  Future<void> _writeAtomicJsonString(File targetFile, String json) async {
    final tmpFile = File('${targetFile.path}.tmp');
    await tmpFile.writeAsString(json);
    await tmpFile.rename(targetFile.path);
  }

  Future<void> _writeWorkingCopyJson(String json) async {
    final uri = _activeExternalWorkingCopyUri;
    if (uri != null) {
      final currentJson = await _externalWorkingCopyDataSource.read(uri);
      final baseSnapshot = _activeExternalSnapshotJson;
      if (baseSnapshot != null && currentJson != baseSnapshot) {
        throw const WorkingCopyConflictException(
          'Die Arbeitsdatei wurde auf einem anderen Gerät geändert. Bitte in den Einstellungen unter "Erweitert" die Datei neu laden.',
        );
      }
      await _externalWorkingCopyDataSource.write(uri, json);
      _activeExternalSnapshotJson = json;
      return;
    }

    final workingCopyFile = await _workingCopyFile();
    if (!await workingCopyFile.exists()) {
      throw const FileSystemException('Working copy missing');
    }
    await _writeAtomicJsonString(workingCopyFile, json);
  }

  Future<List<Seed>> _reloadExternalWorkingCopyIntoCache(String uri) async {
    // Some SAF providers (e.g. cloud-backed providers) can report
    // canRead=false even though reading works once the URI is resolved.
    // Prefer the read result as the single source of truth.
    final json = await _externalWorkingCopyDataSource.read(uri);
    final importedSeeds = _decodeAndValidateImportPayload(json);
    _validateUniqueSeeds(importedSeeds);

    _activeExternalWorkingCopyUri = uri;
    _activeExternalSnapshotJson = json;
    _cache = importedSeeds;
    return importedSeeds;
  }

  List<Seed> _decodeAndValidateImportPayload(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Import file must be a JSON array.');
    }

    final legacySeeds = <Map<String, dynamic>>[];
    for (var i = 0; i < decoded.length; i++) {
      final rawSeed = decoded[i];
      _validateAppFormatSeed(rawSeed, index: i);
      legacySeeds.add(_v1SeedToLegacy(rawSeed, index: i));
    }

    return [
      for (var i = 0; i < legacySeeds.length; i++)
        _mapper.fromJson(legacySeeds[i], seedIndex: i),
    ];
  }

  Map<String, dynamic> _seedToAppFormatV1(Seed seed) {
    return {
      'varietyId': seed.variety.varietyId,
      'taxonKey': {
        'category': _categoryEnumKey(seed.variety.taxonKey.category),
        'species': seed.variety.taxonKey.species,
        'varietyName': seed.variety.taxonKey.varietyName,
      },
      'latin_name': seed.lateinischerName,
      'container': _containerToAppFormat(seed),
      'activityWindows': [
        for (final window in seed.variety.activityWindows)
          {
            'type': _activityTypeEnumKey(window.type),
            'range': {'start': window.range.start, 'end': window.range.end},
          },
      ],
      'cultivation': {
        'freiland': seed.freiland,
        'gruenduengung': seed.gruenduengung,
        'keimtemp_c': seed.keimtempC,
        'tiefe_cm': seed.tiefeCm,
        'row_spacing_cm': seed.abstandReiheCm,
        'plant_spacing_cm': seed.abstandPflanzeCm,
        'plant_height_cm': seed.hoehePflanzeCm,
      },
      'properties': {'eigenschaft': seed.eigenschaft},
      'botany': {'family': seed.familie},
      'flags': {
        'rebuild_required': _yesNoToBool(seed.nachbauNotwendig),
        'variety_name_from_species': seed.varietyNameFromSpecies,
      },
      if (seed.auspflanzenRanges.isNotEmpty ||
          seed.blueteRanges.isNotEmpty ||
          seed.ernteRanges.isNotEmpty)
        'displayWindows': {
          'auspflanzen': _rangesToJson(seed.auspflanzenRanges),
          'bluete': _rangesToJson(seed.blueteRanges),
          'ernte': _rangesToJson(seed.ernteRanges),
        },
    };
  }

  Map<String, dynamic>? _containerToAppFormat(Seed seed) {
    final container = seed.container;
    if (container == null) return null;
    return {
      'containerId': container.containerId,
      'varietyRef': container.varietyRef,
      'tubeCode': {
        'color_key': container.tubeCode.color.name,
        'number': container.tubeCode.number,
      },
    };
  }

  List<Map<String, int>> _rangesToJson(List<MonthRange> ranges) {
    return [
      for (final range in ranges) {'start': range.start, 'end': range.end},
    ];
  }

  bool? _yesNoToBool(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'ja') return true;
    if (normalized == 'nein') return false;
    return null;
  }

  String _categoryEnumKey(Category category) {
    switch (category) {
      case Category.fruchtgemuese:
        return 'FRUCHTGEMUESE';
      case Category.kuerbisartige:
        return 'KUERBISARTIGE';
      case Category.kohlgewaechse:
        return 'KOHLGEWAECHSE';
      case Category.blattgemueseSalat:
        return 'BLATTGEMUESE_SALAT';
      case Category.leguminosen:
        return 'LEGUMINOSEN';
      case Category.sonstigesGemuese:
        return 'SONSTIGES_GEMUESE';
      case Category.kraeuter:
        return 'KRAEUTER';
      case Category.blumen:
        return 'BLUMEN';
      case Category.unknown:
        return 'UNKNOWN';
    }
  }

  String _activityTypeEnumKey(ActivityType type) {
    switch (type) {
      case ActivityType.directSow:
        return 'DIRECT_SOW';
      case ActivityType.preCulture:
        return 'PRE_CULTURE';
      case ActivityType.seedSaving:
        return 'SEED_SAVING';
    }
  }

  void _validateSeedForSave(AppSeed updatedSeed) {
    final varietyId = updatedSeed.variety.varietyId.trim();
    if (varietyId.isEmpty) {
      throw const FormatException(
        'updatedSeed.varietyId must not be null/empty.',
      );
    }
    final species = updatedSeed.variety.taxonKey.species.trim();
    final varietyName = updatedSeed.variety.taxonKey.varietyName.trim();
    if (species.isEmpty) {
      throw const FormatException('updatedSeed.species must not be empty.');
    }
    if (varietyName.isEmpty) {
      throw const FormatException('updatedSeed.varietyName must not be empty.');
    }

    final container = updatedSeed.container;
    if (container != null) {
      if (container.containerId.trim().isEmpty) {
        throw const FormatException(
          'container.containerId must not be null/empty.',
        );
      }
      if (container.varietyRef != varietyId) {
        throw const FormatException(
          'container.varietyRef must match updatedSeed.varietyId.',
        );
      }
      if (container.tubeCode.number < 1) {
        throw const FormatException(
          'container.tubeCode.number must be greater than zero.',
        );
      }
    }

    for (final window in updatedSeed.variety.activityWindows) {
      final typeKey = _activityTypeEnumKey(window.type);
      if (typeKey.isEmpty) {
        throw const FormatException(
          'activityWindows.type must be an enum key.',
        );
      }
      final start = window.range.start;
      final end = window.range.end;
      if (start < 1 || start > 12 || end < 1 || end > 12) {
        throw const FormatException(
          'activityWindows.range start/end must be between 1 and 12.',
        );
      }
    }
  }

  Future<List<Seed>> _loadWorkingCopySeeds(File workingCopyFile) async {
    final rawJson = await workingCopyFile.readAsString();
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException('Working copy must decode to a JSON array.');
    }

    final seeds = <Seed>[];
    for (var i = 0; i < decoded.length; i++) {
      final rawSeed = _v1SeedToLegacy(decoded[i], index: i);
      seeds.add(_mapper.fromJson(rawSeed, seedIndex: i));
    }
    return seeds;
  }

  Map<String, dynamic> _v1SeedToLegacy(dynamic v1Seed, {required int index}) {
    if (v1Seed is! Map) {
      throw FormatException(
        'Working copy entry[$index] must be a JSON object.',
      );
    }

    final seed = Map<String, dynamic>.from(v1Seed);
    final taxonKey = _asMap(
      seed['taxonKey'],
      fieldName: 'taxonKey',
      index: index,
    );
    final cultivation = _asNullableMap(seed['cultivation']);
    final properties = _asNullableMap(seed['properties']);
    final botany = _asNullableMap(seed['botany']);
    final flags = _asNullableMap(seed['flags']);

    return {
      'variety_id': seed['varietyId'],
      'category': _categoryToLegacyLabel(taxonKey['category']),
      'species': taxonKey['species'],
      'variety_name': taxonKey['varietyName'],
      'latin_name': seed['latin_name'],
      'container': _mapContainerToLegacy(seed['container'], index: index),
      'calendar': _mapCalendarToLegacy(seed, index: index),
      'botany': botany,
      'properties': properties,
      'cultivation': cultivation,
      'flags': flags,
    };
  }

  String _categoryToLegacyLabel(dynamic value) {
    final key = value?.toString().trim();
    switch (key) {
      case 'FRUCHTGEMUESE':
        return 'Fruchtgemüse';
      case 'KUERBISARTIGE':
        return 'Kürbisartige';
      case 'KOHLGEWAECHSE':
        return 'Kohlgewächse';
      case 'BLATTGEMUESE_SALAT':
        return 'Blattgemüse/Salat';
      case 'LEGUMINOSEN':
        return 'Leguminosen';
      case 'SONSTIGES_GEMUESE':
        return 'Sonstiges Gemüse';
      case 'KRAEUTER':
        return 'Kräuter';
      case 'BLUMEN':
        return 'Blumen';
      case 'UNKNOWN':
        return 'unknown';
      default:
        return key ?? '';
    }
  }

  Map<String, dynamic>? _mapContainerToLegacy(
    dynamic container, {
    required int index,
  }) {
    if (container == null) return null;
    final containerMap = _asMap(
      container,
      fieldName: 'container',
      index: index,
    );
    final tubeCode = _asMap(
      containerMap['tubeCode'],
      fieldName: 'container.tubeCode',
      index: index,
    );
    return {
      'tube_number': tubeCode['number'],
      'tube_color_key': tubeCode['color_key'],
    };
  }

  void _validateAppFormatSeed(dynamic rawSeed, {required int index}) {
    if (rawSeed is! Map) {
      throw FormatException('Import entry[$index] must be a JSON object.');
    }
    final seed = Map<String, dynamic>.from(rawSeed);

    final varietyId = _requiredStringField(
      seed,
      key: 'varietyId',
      path: '[$index].varietyId',
    );
    final taxonKey = _requiredMapField(
      seed,
      key: 'taxonKey',
      path: '[$index].taxonKey',
    );

    _requiredCategoryKey(
      taxonKey,
      key: 'category',
      path: '[$index].taxonKey.category',
    );
    _requiredStringField(
      taxonKey,
      key: 'species',
      path: '[$index].taxonKey.species',
    );
    _requiredStringField(
      taxonKey,
      key: 'varietyName',
      path: '[$index].taxonKey.varietyName',
    );

    _optionalStringOrNull(seed, key: 'latin_name', path: '[$index].latin_name');

    final container = seed['container'];
    if (container != null) {
      final containerMap = _requiredMapField(
        seed,
        key: 'container',
        path: '[$index].container',
      );
      final containerId = _requiredStringField(
        containerMap,
        key: 'containerId',
        path: '[$index].container.containerId',
      );
      if (containerId.isEmpty) {
        throw FormatException(
          'Import entry[$index].container.containerId is empty.',
        );
      }

      final varietyRef = _requiredStringField(
        containerMap,
        key: 'varietyRef',
        path: '[$index].container.varietyRef',
      );
      if (varietyRef != varietyId) {
        throw FormatException(
          'Import entry[$index].container.varietyRef must equal varietyId.',
        );
      }

      final tubeCode = _requiredMapField(
        containerMap,
        key: 'tubeCode',
        path: '[$index].container.tubeCode',
      );
      final colorKey = _requiredStringField(
        tubeCode,
        key: 'color_key',
        path: '[$index].container.tubeCode.color_key',
      );
      final allowedTubeColors = <String>{
        'red',
        'green',
        'blue',
        'yellow',
        'white',
      };
      if (!allowedTubeColors.contains(colorKey)) {
        throw FormatException(
          'Import entry[$index].container.tubeCode.color_key must be one of ${allowedTubeColors.join(', ')}.',
        );
      }
      _requiredPositiveIntField(
        tubeCode,
        key: 'number',
        path: '[$index].container.tubeCode.number',
      );
    }

    final activityWindows = seed['activityWindows'];
    if (activityWindows is! List) {
      throw FormatException(
        'Import entry[$index].activityWindows must be a list.',
      );
    }
    for (var i = 0; i < activityWindows.length; i++) {
      final window = activityWindows[i];
      if (window is! Map) {
        throw FormatException(
          'Import entry[$index].activityWindows[$i] must be an object.',
        );
      }
      final windowMap = Map<String, dynamic>.from(window);
      final type = _requiredStringField(
        windowMap,
        key: 'type',
        path: '[$index].activityWindows[$i].type',
      );
      final allowedTypes = <String>{'DIRECT_SOW', 'PRE_CULTURE', 'SEED_SAVING'};
      if (!allowedTypes.contains(type)) {
        throw FormatException(
          'Import entry[$index].activityWindows[$i].type is invalid.',
        );
      }
      final range = _requiredMapField(
        windowMap,
        key: 'range',
        path: '[$index].activityWindows[$i].range',
      );
      _requiredMonthField(
        range,
        key: 'start',
        path: '[$index].activityWindows[$i].range.start',
      );
      _requiredMonthField(
        range,
        key: 'end',
        path: '[$index].activityWindows[$i].range.end',
      );
    }

    _validateDisplayWindows(seed['displayWindows'], index: index);
    _validateOptionalStringMap(
      seed['cultivation'],
      index: index,
      key: 'cultivation',
      allowedKeys: const <String>{
        'freiland',
        'gruenduengung',
        'keimtemp_c',
        'tiefe_cm',
        'row_spacing_cm',
        'plant_spacing_cm',
        'plant_height_cm',
      },
    );
    _validateOptionalStringMap(
      seed['properties'],
      index: index,
      key: 'properties',
      allowedKeys: const <String>{'eigenschaft'},
    );
    _validateOptionalStringMap(
      seed['botany'],
      index: index,
      key: 'botany',
      allowedKeys: const <String>{'family'},
    );

    final flags = seed['flags'];
    if (flags != null) {
      if (flags is! Map) {
        throw FormatException('Import entry[$index].flags must be an object.');
      }
      final map = Map<String, dynamic>.from(flags);
      if (!map.containsKey('variety_name_from_species')) {
        throw FormatException(
          'Import entry[$index].flags.variety_name_from_species is required when flags is present.',
        );
      }
      final varietyNameFromSpecies = map['variety_name_from_species'];
      if (varietyNameFromSpecies is! bool) {
        throw FormatException(
          'Import entry[$index].flags.variety_name_from_species must be bool.',
        );
      }
      if (map.containsKey('rebuild_required')) {
        final rebuild = map['rebuild_required'];
        if (rebuild != null && rebuild is! bool) {
          throw FormatException(
            'Import entry[$index].flags.rebuild_required must be bool or null.',
          );
        }
      }
    }
  }

  void _validateDisplayWindows(dynamic value, {required int index}) {
    if (value == null) return;
    if (value is! Map) {
      throw FormatException(
        'Import entry[$index].displayWindows must be an object.',
      );
    }
    final windows = Map<String, dynamic>.from(value);
    const keys = <String>{'auspflanzen', 'bluete', 'ernte'};
    for (final key in keys) {
      if (!windows.containsKey(key) || windows[key] == null) {
        continue;
      }
      final ranges = windows[key];
      if (ranges is! List) {
        throw FormatException(
          'Import entry[$index].displayWindows.$key must be a list.',
        );
      }
      for (var i = 0; i < ranges.length; i++) {
        final range = ranges[i];
        if (range is! Map) {
          throw FormatException(
            'Import entry[$index].displayWindows.$key[$i] must be an object.',
          );
        }
        final rangeMap = Map<String, dynamic>.from(range);
        _requiredMonthField(
          rangeMap,
          key: 'start',
          path: '[$index].displayWindows.$key[$i].start',
        );
        _requiredMonthField(
          rangeMap,
          key: 'end',
          path: '[$index].displayWindows.$key[$i].end',
        );
      }
    }
  }

  void _validateOptionalStringMap(
    dynamic value, {
    required int index,
    required String key,
    required Set<String> allowedKeys,
  }) {
    if (value == null) return;
    if (value is! Map) {
      throw FormatException('Import entry[$index].$key must be an object.');
    }
    final map = Map<String, dynamic>.from(value);
    for (final field in allowedKeys) {
      if (!map.containsKey(field)) continue;
      final fieldValue = map[field];
      if (fieldValue != null && fieldValue is! String) {
        throw FormatException(
          'Import entry[$index].$key.$field must be string or null.',
        );
      }
    }
  }

  Map<String, dynamic> _requiredMapField(
    Map<String, dynamic> map, {
    required String key,
    required String path,
  }) {
    final value = map[key];
    if (value is! Map) {
      throw FormatException('Import field "$path" must be an object.');
    }
    return Map<String, dynamic>.from(value);
  }

  String _requiredStringField(
    Map<String, dynamic> map, {
    required String key,
    required String path,
  }) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing required import field "$path".');
    }
    final normalized = value.toString().trim();
    if (normalized.isEmpty) {
      throw FormatException('Import field "$path" must not be empty.');
    }
    return normalized;
  }

  void _requiredCategoryKey(
    Map<String, dynamic> map, {
    required String key,
    required String path,
  }) {
    final value = _requiredStringField(map, key: key, path: path);
    const allowed = <String>{
      'FRUCHTGEMUESE',
      'KUERBISARTIGE',
      'KOHLGEWAECHSE',
      'BLATTGEMUESE_SALAT',
      'LEGUMINOSEN',
      'SONSTIGES_GEMUESE',
      'KRAEUTER',
      'BLUMEN',
      'UNKNOWN',
    };
    if (!allowed.contains(value)) {
      throw FormatException(
        'Import field "$path" has unsupported enum key "$value".',
      );
    }
  }

  void _requiredPositiveIntField(
    Map<String, dynamic> map, {
    required String key,
    required String path,
  }) {
    final value = map[key];
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < 1) {
      throw FormatException('Import field "$path" must be a positive integer.');
    }
  }

  void _requiredMonthField(
    Map<String, dynamic> map, {
    required String key,
    required String path,
  }) {
    final value = map[key];
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < 1 || parsed > 12) {
      throw FormatException(
        'Import field "$path" must be a month in range 1..12.',
      );
    }
  }

  void _optionalStringOrNull(
    Map<String, dynamic> map, {
    required String key,
    required String path,
  }) {
    if (!map.containsKey(key)) return;
    final value = map[key];
    if (value != null && value is! String) {
      throw FormatException('Import field "$path" must be a string or null.');
    }
  }

  Map<String, dynamic> _mapCalendarToLegacy(
    Map<String, dynamic> seed, {
    required int index,
  }) {
    final activityWindows = seed['activityWindows'];
    if (activityWindows is! List) {
      throw FormatException(
        'Working copy entry[$index].activityWindows must be a list.',
      );
    }

    final directSow = <int>[];
    final preCulture = <int>[];
    for (final rawWindow in activityWindows) {
      final window = _asMap(
        rawWindow,
        fieldName: 'activityWindows[]',
        index: index,
      );
      final type = window['type']?.toString();
      final months = _expandMonthRange(window['range'], index: index);
      if (type == 'DIRECT_SOW') {
        directSow.addAll(months);
      }
      if (type == 'PRE_CULTURE') {
        preCulture.addAll(months);
      }
    }

    final displayWindows = _asNullableMap(seed['displayWindows']);
    final auspflanzen = _expandDisplayRanges(
      displayWindows?['auspflanzen'],
      index: index,
    );
    final bluete = _expandDisplayRanges(
      displayWindows?['bluete'],
      index: index,
    );
    final ernte = _expandDisplayRanges(displayWindows?['ernte'], index: index);

    return {
      'aussaat': directSow,
      'voranzucht': preCulture,
      'auspflanzen': auspflanzen,
      'bluete': bluete,
      'ernte': ernte,
    };
  }

  List<int> _expandDisplayRanges(dynamic ranges, {required int index}) {
    if (ranges == null) return const [];
    if (ranges is! List) {
      throw FormatException(
        'Working copy display window in entry[$index] must be a list.',
      );
    }
    final result = <int>[];
    for (final range in ranges) {
      result.addAll(_expandMonthRange(range, index: index));
    }
    return result;
  }

  List<int> _expandMonthRange(dynamic rawRange, {required int index}) {
    final range = _asMap(rawRange, fieldName: 'range', index: index);
    final start = _asMonth(range['start'], 'start', index);
    final end = _asMonth(range['end'], 'end', index);
    if (start <= end) {
      return [for (var month = start; month <= end; month++) month];
    }
    return [
      for (var month = start; month <= 12; month++) month,
      for (var month = 1; month <= end; month++) month,
    ];
  }

  int _asMonth(dynamic value, String fieldName, int index) {
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < 1 || parsed > 12) {
      throw FormatException(
        'Working copy entry[$index].$fieldName must be month 1..12.',
      );
    }
    return parsed;
  }

  Map<String, dynamic>? _asNullableMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected JSON object.');
  }

  Map<String, dynamic> _asMap(
    dynamic value, {
    required String fieldName,
    required int index,
  }) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException(
      'Working copy entry[$index].$fieldName must be an object.',
    );
  }

  void _validateUniqueSeeds(List<Seed> seeds) {
    final varietyIds = <String, int>{};
    for (var i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final varietyId = seed.variety.varietyId;
      final existingIndex = varietyIds[varietyId];
      if (existingIndex != null) {
        final firstName = seeds[existingIndex].variety.taxonKey.varietyName;
        final secondName = seed.variety.taxonKey.varietyName;
        throw StateError(
          'Duplicate variety_id="$varietyId" found at indices '
          '$existingIndex and $i (varietyNames: "$firstName", "$secondName").',
        );
      }
      varietyIds[varietyId] = i;
    }

    final taxonKeys = <Object, int>{};
    for (var i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final key = seed.variety.taxonKey;
      final existingIndex = taxonKeys[key];
      if (existingIndex != null) {
        throw StateError(
          'Duplicate taxonKey="$key" found at indices $existingIndex and $i.',
        );
      }
      taxonKeys[key] = i;
    }

    final tubeCodes = <String, int>{};
    for (var i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final tubeCode = seed.container?.tubeCode;
      final tubeKey = tubeCode?.toString();
      if (tubeKey == null) {
        continue;
      }
      final existingIndex = tubeCodes[tubeKey];
      if (existingIndex != null) {
        final firstVariety = seeds[existingIndex].variety.varietyId;
        final secondVariety = seed.variety.varietyId;
        throw StateError(
          'Duplicate tubeCode="$tubeKey" found at indices '
          '$existingIndex and $i (varietyIds: "$firstVariety", "$secondVariety").',
        );
      }
      tubeCodes[tubeKey] = i;
    }
  }

  static String? _normalizeUri(String? uri) {
    if (uri == null) return null;
    final normalized = uri.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

abstract class ExternalWorkingCopyDataSource {
  Future<bool> canRead(String uri);
  Future<String> read(String uri);
  Future<void> write(String uri, String json);
}

class NoopExternalWorkingCopyDataSource
    implements ExternalWorkingCopyDataSource {
  const NoopExternalWorkingCopyDataSource();

  @override
  Future<bool> canRead(String uri) async => false;

  @override
  Future<String> read(String uri) async {
    throw UnsupportedError('External working copy access is not available.');
  }

  @override
  Future<void> write(String uri, String json) async {
    throw UnsupportedError('External working copy access is not available.');
  }
}

class WorkingCopyConflictException implements Exception {
  const WorkingCopyConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}
