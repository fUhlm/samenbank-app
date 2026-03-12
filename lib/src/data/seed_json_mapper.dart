import '../containers/seed_container.dart';
import '../containers/tube_code.dart';
import '../models/activity_window.dart';
import '../models/month_range.dart';
import '../models/seed_detail_model.dart';
import '../models/taxon_key.dart';
import '../models/variety.dart';
import '../repositories/seed_repository.dart';
import '../types/enums.dart';

class SeedJsonMapper {
  const SeedJsonMapper();

  Seed fromJson(Map<String, dynamic> json, {int? seedIndex}) {
    final seedContext = seedIndex == null ? 'seed' : 'seed[$seedIndex]';
    final varietyId = _requiredString(
      json,
      'variety_id',
      seedContext,
      path: 'variety_id',
    );
    final id = varietyId;

    final categoryLabel = _requiredString(
      json,
      'category',
      id,
      path: 'category',
    );
    final species = _requiredString(json, 'species', id, path: 'species');
    final varietyName = _requiredString(
      json,
      'variety_name',
      id,
      path: 'variety_name',
    );

    final taxonKey = TaxonKey(
      category: _categoryFromLabel(categoryLabel),
      species: species,
      varietyName: varietyName,
    );

    final containerMap = _optionalMap(json, 'container', id);
    final tubeNumber = containerMap == null
        ? 0
        : _requiredInt(
            containerMap,
            'tube_number',
            id,
            path: 'container.tube_number',
          );
    final tubeColor = containerMap == null
        ? TubeColor.white
        : _tubeColorFromKey(
            _requiredString(
              containerMap,
              'tube_color_key',
              id,
              path: 'container.tube_color_key',
            ),
            id,
            'container.tube_color_key',
          );

    final container = containerMap == null
        ? null
        : SeedContainer(
            containerId: 'C$varietyId',
            varietyRef: varietyId,
            tubeCode: TubeCode(color: tubeColor, number: tubeNumber),
          );

    final calendar =
        _optionalMap(json, 'calendar', id) ?? const <String, dynamic>{};
    final directSowRanges = _monthRangesFromList(
      _optionalList(calendar, 'aussaat', id),
      id,
      'calendar.aussaat',
    );
    final preCultureRanges = _monthRangesFromList(
      _optionalList(calendar, 'voranzucht', id),
      id,
      'calendar.voranzucht',
    );
    final auspflanzenRanges = _monthRangesFromList(
      _optionalList(calendar, 'auspflanzen', id),
      id,
      'calendar.auspflanzen',
    );
    final blueteRanges = _monthRangesFromList(
      _optionalList(calendar, 'bluete', id),
      id,
      'calendar.bluete',
    );
    final ernteRanges = _monthRangesFromList(
      _optionalList(calendar, 'ernte', id),
      id,
      'calendar.ernte',
    );

    final activityWindows = <ActivityWindow>[
      ..._windowsFor(ActivityType.directSow, directSowRanges, id),
      ..._windowsFor(ActivityType.preCulture, preCultureRanges, id),
    ];

    final botany = _optionalMap(json, 'botany', id);
    final properties = _optionalMap(json, 'properties', id);
    final cultivation = _optionalMap(json, 'cultivation', id);
    final meta = _optionalMap(json, 'meta', id);
    final flags = _optionalMap(json, 'flags', id);

    return SeedDetailModel(
      id: id,
      variety: Variety(
        varietyId: varietyId,
        taxonKey: taxonKey,
        activityWindows: activityWindows,
      ),
      container: container,
      codeNumber: tubeNumber,
      codeColorValue: _codeColorValue(tubeColor),
      gruppe: categoryLabel,
      art: species,
      sorte: varietyName,
      lateinischerName: _optionalString(json, 'latin_name', id),
      familie: _optionalString(botany, 'family', id),
      eigenschaft: _optionalString(properties, 'eigenschaft', id),
      freiland:
          _optionalString(cultivation, 'freiland', id) ??
          _optionalString(properties, 'freiland', id),
      gruenduengung:
          _optionalString(cultivation, 'gruenduengung', id) ??
          _optionalString(properties, 'gruenduengung', id),
      nachbauNotwendig: _optionalFlagValue(flags, 'rebuild_required', id),
      keimtempC:
          _optionalString(cultivation, 'keimtemp_c', id) ??
          _optionalString(cultivation, 'germination_temp_c', id) ??
          _optionalString(meta, 'keimtemp_c', id),
      tiefeCm:
          _optionalString(cultivation, 'tiefe_cm', id) ??
          _optionalString(cultivation, 'sowing_depth_cm', id) ??
          _optionalString(meta, 'tiefe_cm', id),
      abstandReiheCm:
          _optionalString(cultivation, 'row_spacing_cm', id) ??
          _optionalString(meta, 'abstand_reihe_cm', id),
      abstandPflanzeCm:
          _optionalString(cultivation, 'plant_spacing_cm', id) ??
          _optionalString(meta, 'abstand_pflanze_cm', id),
      hoehePflanzeCm:
          _optionalString(cultivation, 'plant_height_cm', id) ??
          _optionalString(meta, 'hoehe_cm', id),
      auspflanzenRanges: auspflanzenRanges,
      blueteRanges: blueteRanges,
      ernteRanges: ernteRanges,
      varietyNameFromSpecies:
          _optionalBool(flags, 'variety_name_from_species', id) ?? false,
    );
  }
}

String _requiredString(
  Map<String, dynamic> json,
  String key,
  String seedContext, {
  required String path,
}) {
  final value = json[key];
  if (value == null) {
    throw FormatException(
      'Missing required field "$key" for $seedContext at "$path".',
    );
  }
  final result = value.toString().trim();
  if (result.isEmpty) {
    throw FormatException('Field "$key" is empty for $seedContext at "$path".');
  }
  return result;
}

int _requiredInt(
  Map<String, dynamic> json,
  String key,
  String seedId, {
  required String path,
}) {
  final value = json[key];
  if (value == null) {
    throw FormatException(
      'Missing required field "$key" for seed $seedId at "$path".',
    );
  }
  if (value is int) return value;
  final parsed = int.tryParse(value.toString());
  if (parsed == null) {
    throw FormatException(
      'Field "$key" must be an int for seed $seedId at "$path".',
    );
  }
  return parsed;
}

Map<String, dynamic>? _optionalMap(
  Map<String, dynamic> json,
  String key,
  String seedId,
) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value == null) return null;
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('Field "$key" must be an object for seed $seedId.');
}

List<dynamic> _optionalList(
  Map<String, dynamic> json,
  String key,
  String seedId,
) {
  if (!json.containsKey(key)) return const [];
  final value = json[key];
  if (value == null) {
    throw FormatException(
      'Field "$key" cannot be null for seed $seedId (omit or provide list).',
    );
  }
  if (value is List) return value;
  throw FormatException('Field "$key" must be a list for seed $seedId.');
}

bool? _optionalBool(Map<String, dynamic>? json, String key, String seedId) {
  if (json == null || !json.containsKey(key)) return null;
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException('Field $key must be a bool for seed $seedId.');
}

String? _optionalString(Map<String, dynamic>? json, String key, String seedId) {
  if (json == null) return null;
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value == null) return null;
  if (value is String) {
    final result = value.trim();
    return result.isEmpty ? null : result;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  throw FormatException('Field $key must be a string for seed $seedId.');
}

String? _optionalFlagValue(
  Map<String, dynamic>? json,
  String key,
  String seedId,
) {
  if (json == null) return null;
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value ? 'ja' : 'nein';
  throw FormatException('Field $key must be a bool for seed $seedId.');
}

Category _categoryFromLabel(String label) {
  final normalized = label.trim().toLowerCase();
  switch (normalized) {
    case 'fruchtgemüse':
    case 'fruchtgemuese':
      return Category.fruchtgemuese;
    case 'kürbisartige':
    case 'kuerbisartige':
      return Category.kuerbisartige;
    case 'kohlgewächse':
    case 'kohlgewaechse':
      return Category.kohlgewaechse;
    case 'blattgemüse/salat':
    case 'blattgemuese/salat':
    case 'blattgemüse':
    case 'blattgemuese':
      return Category.blattgemueseSalat;
    case 'leguminose':
    case 'leguminosen':
      return Category.leguminosen;
    case 'sonstige':
    case 'sonstiges gemüse':
    case 'sonstiges gemuese':
      return Category.sonstigesGemuese;
    case 'kräuter':
    case 'kraeuter':
      return Category.kraeuter;
    case 'blumen':
      return Category.blumen;
    default:
      return Category.unknown;
  }
}

TubeColor _tubeColorFromKey(String key, String seedId, String path) {
  switch (key.trim().toLowerCase()) {
    case 'red':
      return TubeColor.red;
    case 'green':
      return TubeColor.green;
    case 'blue':
      return TubeColor.blue;
    case 'yellow':
      return TubeColor.yellow;
    case 'white':
      return TubeColor.white;
    default:
      throw FormatException(
        'Unknown tube color "$key" for seed $seedId at "$path".',
      );
  }
}

int _codeColorValue(TubeColor color) {
  switch (color) {
    case TubeColor.red:
      return 0xFFE53935;
    case TubeColor.green:
      return 0xFF43A047;
    case TubeColor.blue:
      return 0xFF1E88E5;
    case TubeColor.yellow:
      return 0xFFFDD835;
    case TubeColor.white:
      return 0xFFFFFFFF;
  }
}

List<ActivityWindow> _windowsFor(
  ActivityType type,
  List<MonthRange> ranges,
  String seedId,
) {
  return List<ActivityWindow>.generate(
    ranges.length,
    (index) => ActivityWindow(
      windowId: '${seedId}_${type.name}_$index',
      type: type,
      range: ranges[index],
    ),
    growable: false,
  );
}

List<MonthRange> _monthRangesFromList(
  List<dynamic> rawMonths,
  String seedId,
  String path,
) {
  if (rawMonths.isEmpty) return const [];
  final months = <int>{};
  for (var i = 0; i < rawMonths.length; i++) {
    final value = rawMonths[i];
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < 1 || parsed > 12) {
      throw FormatException(
        'Invalid month value "$value" for seed $seedId at "$path[$i]".',
      );
    }
    if (!months.add(parsed)) {
      throw FormatException(
        'Duplicate month value "$parsed" for seed $seedId at "$path[$i]".',
      );
    }
  }
  return _monthRangesFromSet(months);
}

List<MonthRange> _monthRangesFromSet(Set<int> months) {
  if (months.isEmpty) return const [];
  if (months.length == 12) {
    return const [MonthRange(start: 1, end: 12)];
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
  final ranges = <MonthRange>[];

  int? currentStart;
  int previousMonth = startMonth;

  for (var offset = 0; offset < 12; offset++) {
    final month = ((startMonth + offset - 1) % 12) + 1;
    final isIncluded = included[month];

    if (isIncluded && currentStart == null) {
      currentStart = month;
    } else if (!isIncluded && currentStart != null) {
      ranges.add(MonthRange(start: currentStart, end: previousMonth));
      currentStart = null;
    }
    previousMonth = month;
  }

  if (currentStart != null) {
    ranges.add(MonthRange(start: currentStart, end: previousMonth));
  }

  return ranges;
}
