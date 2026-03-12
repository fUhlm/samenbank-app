import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'seed_json_loader.dart';

const String appFormatV1FileName = 'seeds_app_v1.json';

class WorkingCopyV1Initializer {
  WorkingCopyV1Initializer({
    SeedJsonLoader? loader,
    AppFormatV1SeedTransformer? transformer,
  }) : _loader = loader ?? SeedJsonLoader(),
       _transformer = transformer ?? const AppFormatV1SeedTransformer();

  final SeedJsonLoader _loader;
  final AppFormatV1SeedTransformer _transformer;

  Future<void> ensureWorkingCopy() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final workingCopyFile = File(
      '${documentsDirectory.path}/$appFormatV1FileName',
    );

    if (await workingCopyFile.exists()) {
      return;
    }

    final decoded = await _loader.loadDecoded();
    final rawSeeds = _extractSeedList(decoded);

    final transformedSeeds = <Map<String, dynamic>>[];
    for (var i = 0; i < rawSeeds.length; i++) {
      final rawSeed = rawSeeds[i];
      if (rawSeed is! Map) {
        throw FormatException('Seed[$i]: entry must be a JSON object.');
      }

      final normalizedSeed = Map<String, dynamic>.from(rawSeed);
      final varietyIdForContext = _varietyIdForContext(normalizedSeed);
      final context = _seedContext(i, varietyIdForContext);

      try {
        transformedSeeds.add(_transformer.transform(normalizedSeed));
      } on FormatException catch (error) {
        throw FormatException('$context: ${error.message}');
      }
    }

    await workingCopyFile.writeAsString(jsonEncode(transformedSeeds));
  }

  List<dynamic> _extractSeedList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final wrappedSeeds = decoded['seeds'];
      if (wrappedSeeds is List) {
        return wrappedSeeds;
      }
    }

    throw const FormatException(
      'Seed JSON asset must be either a root array or an object with a "seeds" array.',
    );
  }

  String _seedContext(int index, String? varietyId) {
    if (varietyId == null) return 'Seed[$index]';
    return 'Seed[$index] (variety_id=$varietyId)';
  }

  String? _varietyIdForContext(Map<String, dynamic> seed) {
    final value = seed['variety_id'];
    if (value == null) return null;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? null : parsed;
  }
}

class AppFormatV1SeedTransformer {
  const AppFormatV1SeedTransformer();

  Map<String, dynamic> transform(Map<String, dynamic> legacySeed) {
    final varietyId = _requiredString(legacySeed, 'variety_id');

    final directSowRanges = _monthRangesFromCalendarList(legacySeed, 'aussaat');
    final preCultureRanges = _monthRangesFromCalendarList(
      legacySeed,
      'voranzucht',
    );
    final auspflanzenRanges = _monthRangesFromCalendarList(
      legacySeed,
      'auspflanzen',
    );
    final blueteRanges = _monthRangesFromCalendarList(legacySeed, 'bluete');
    final ernteRanges = _monthRangesFromCalendarList(legacySeed, 'ernte');

    final activityWindows = <Map<String, dynamic>>[];
    activityWindows.addAll(
      _toActivityWindows(directSowRanges, typeKey: 'DIRECT_SOW'),
    );
    activityWindows.addAll(
      _toActivityWindows(preCultureRanges, typeKey: 'PRE_CULTURE'),
    );

    final seed = <String, dynamic>{
      'varietyId': varietyId,
      'taxonKey': {
        'category': _categoryEnumKey(_requiredString(legacySeed, 'category')),
        'species': _requiredString(legacySeed, 'species'),
        'varietyName': _requiredString(legacySeed, 'variety_name'),
      },
      'latin_name': _optionalString(legacySeed, 'latin_name'),
      'container': _mapContainer(legacySeed['container'], varietyId),
      'activityWindows': activityWindows,
      'cultivation': _canonicalCultivation(
        legacySeed['cultivation'],
        legacySeed['meta'],
      ),
      'properties': {
        'eigenschaft': _optionalStringMapValue(
          legacySeed['properties'],
          'eigenschaft',
        ),
      },
      'botany': {
        'family': _optionalStringMapValue(legacySeed['botany'], 'family'),
      },
      'flags': {
        'rebuild_required': _optionalBoolMapValue(
          legacySeed['flags'],
          'rebuild_required',
        ),
        'variety_name_from_species':
            _optionalBoolMapValue(
              legacySeed['flags'],
              'variety_name_from_species',
            ) ??
            false,
      },
    };

    final hasDisplayWindows =
        auspflanzenRanges.isNotEmpty ||
        blueteRanges.isNotEmpty ||
        ernteRanges.isNotEmpty;
    if (hasDisplayWindows) {
      seed['displayWindows'] = {
        'auspflanzen': auspflanzenRanges,
        'bluete': blueteRanges,
        'ernte': ernteRanges,
      };
    }

    return seed;
  }

  Map<String, dynamic>? _mapContainer(dynamic value, String varietyId) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException(
        'Field "container" must be an object when provided.',
      );
    }
    final map = Map<String, dynamic>.from(value);
    final number = _requiredInt(map, 'tube_number');
    final colorKey = _requiredString(map, 'tube_color_key');
    return {
      'containerId': 'C$varietyId',
      'varietyRef': varietyId,
      'tubeCode': {'color_key': colorKey, 'number': number},
    };
  }

  Map<String, dynamic> _canonicalCultivation(dynamic value, dynamic metaValue) {
    final map = value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final meta = metaValue is Map
        ? Map<String, dynamic>.from(metaValue)
        : const <String, dynamic>{};
    return {
      'freiland': _optionalStringMapValue(map, 'freiland'),
      'gruenduengung': _optionalStringMapValue(map, 'gruenduengung'),
      'keimtemp_c':
          _optionalStringMapValue(map, 'keimtemp_c') ??
          _optionalStringMapValue(meta, 'keimtemp_c'),
      'tiefe_cm':
          _optionalStringMapValue(map, 'tiefe_cm') ??
          _optionalStringMapValue(meta, 'tiefe_cm'),
      'row_spacing_cm':
          _optionalStringMapValue(map, 'row_spacing_cm') ??
          _optionalStringMapValue(meta, 'abstand_reihe_cm'),
      'plant_spacing_cm':
          _optionalStringMapValue(map, 'plant_spacing_cm') ??
          _optionalStringMapValue(meta, 'abstand_pflanze_cm'),
      'plant_height_cm':
          _optionalStringMapValue(map, 'plant_height_cm') ??
          _optionalStringMapValue(meta, 'hoehe_cm'),
    };
  }

  List<Map<String, dynamic>> _toActivityWindows(
    List<Map<String, int>> ranges, {
    required String typeKey,
  }) {
    return [
      for (final range in ranges)
        {
          'type': typeKey,
          'range': {'start': range['start'], 'end': range['end']},
        },
    ];
  }

  List<Map<String, int>> _monthRangesFromCalendarList(
    Map<String, dynamic> seed,
    String key,
  ) {
    final calendar = seed['calendar'];
    if (calendar != null && calendar is! Map) {
      throw const FormatException(
        'Field "calendar" must be an object when provided.',
      );
    }
    final calendarMap = calendar == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(calendar);
    final rawMonths = calendarMap[key];
    if (rawMonths == null) return const [];
    if (rawMonths is! List) {
      throw FormatException('Field "calendar.$key" must be a list.');
    }
    final months = <int>{};
    for (var i = 0; i < rawMonths.length; i++) {
      final raw = rawMonths[i];
      final month = raw is int ? raw : int.tryParse(raw.toString());
      if (month == null || month < 1 || month > 12) {
        throw FormatException(
          'Invalid month value "$raw" in calendar.$key[$i].',
        );
      }
      months.add(month);
    }
    return _monthRangesFromSet(months);
  }

  List<Map<String, int>> _monthRangesFromSet(Set<int> months) {
    if (months.isEmpty) return const [];
    if (months.length == 12) {
      return const [
        {'start': 1, 'end': 12},
      ];
    }

    final included = List<bool>.filled(13, false);
    for (final month in months) {
      included[month] = true;
    }

    int startGap = -1;
    for (var month = 1; month <= 12; month++) {
      if (!included[month]) {
        startGap = month;
        break;
      }
    }

    final startMonth = startGap == -1 ? 1 : (startGap == 12 ? 1 : startGap + 1);
    final ranges = <Map<String, int>>[];

    int? currentStart;
    var previousMonth = startMonth;

    for (var offset = 0; offset < 12; offset++) {
      final month = ((startMonth + offset - 1) % 12) + 1;
      final isIncluded = included[month];

      if (isIncluded) {
        currentStart ??= month;
      }

      final nextMonth = month == 12 ? 1 : month + 1;
      final nextIncluded = included[nextMonth];
      if (isIncluded && !nextIncluded && currentStart != null) {
        ranges.add({'start': currentStart, 'end': month});
        currentStart = null;
      }

      previousMonth = month;
    }

    if (ranges.isEmpty && included[previousMonth]) {
      ranges.add({'start': startMonth, 'end': previousMonth});
    }

    return ranges;
  }

  String _categoryEnumKey(String rawCategory) {
    final normalized = rawCategory.trim().toUpperCase();
    const directKeys = {
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
    if (directKeys.contains(normalized)) {
      return normalized;
    }

    final folded = rawCategory.trim().toLowerCase();
    switch (folded) {
      case 'fruchtgemüse':
      case 'fruchtgemuese':
        return 'FRUCHTGEMUESE';
      case 'kürbisartige':
      case 'kuerbisartige':
        return 'KUERBISARTIGE';
      case 'kohlgewächse':
      case 'kohlgewaechse':
        return 'KOHLGEWAECHSE';
      case 'blattgemüse/salat':
      case 'blattgemuese/salat':
      case 'blattgemüse':
      case 'blattgemuese':
        return 'BLATTGEMUESE_SALAT';
      case 'leguminose':
      case 'leguminosen':
        return 'LEGUMINOSEN';
      case 'sonstige':
      case 'sonstiges gemüse':
      case 'sonstiges gemuese':
        return 'SONSTIGES_GEMUESE';
      case 'kräuter':
      case 'kraeuter':
        return 'KRAEUTER';
      case 'blumen':
        return 'BLUMEN';
      default:
        return 'UNKNOWN';
    }
  }

  String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing required field "$key".');
    }
    final result = value.toString().trim();
    if (result.isEmpty) {
      throw FormatException('Field "$key" must not be empty.');
    }
    return result;
  }

  int _requiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing required field "$key".');
    }
    if (value is int) return value;
    final parsed = int.tryParse(value.toString());
    if (parsed == null) {
      throw FormatException('Field "$key" must be an int.');
    }
    return parsed;
  }

  String? _optionalString(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return null;
    final value = map[key];
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  String? _optionalStringMapValue(dynamic mapValue, String key) {
    if (mapValue is! Map) return null;
    final map = Map<String, dynamic>.from(mapValue);
    final value = map[key];
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  bool? _optionalBoolMapValue(dynamic mapValue, String key) {
    if (mapValue is! Map) return null;
    final map = Map<String, dynamic>.from(mapValue);
    final value = map[key];
    if (value == null) return null;
    if (value is bool) return value;
    throw FormatException('Field "$key" must be a bool.');
  }
}
