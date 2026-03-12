import 'dart:convert';

import '../data/seed_json_mapper.dart';
import '../containers/seed_container.dart';
import '../containers/tube_code.dart';
import '../models/activity_window.dart';
import '../models/month_range.dart';
import '../models/seed_detail_model.dart';
import '../models/taxon_key.dart';
import '../models/variety.dart';
import '../types/enums.dart';

typedef Seed = SeedDetailModel;
typedef AppSeed = SeedDetailModel;

abstract class SeedRepository {
  List<Seed> getAllSeeds();
  Seed getSeedById(String id);
  Future<void> createSeed(AppSeed seed);
  Future<void> updateSeed(AppSeed updatedSeed);
  Future<void> deleteSeed(String varietyId);
  Future<String> exportWorkingCopyJson();
  Future<void> importWorkingCopyJson(String json);
}

class MockSeedRepository implements SeedRepository {
  static const SeedJsonMapper _mapper = SeedJsonMapper();
  static final List<Seed> _seeds = <Seed>[
    SeedDetailModel(
      id: 'V01',
      variety: const Variety(
        varietyId: 'V01',
        taxonKey: TaxonKey(
          category: Category.fruchtgemuese,
          species: 'Tomate',
          varietyName: 'Ruthje',
        ),
        activityWindows: [
          ActivityWindow(
            windowId: 'W01A',
            type: ActivityType.preCulture,
            range: MonthRange(start: 1, end: 3),
          ),
        ],
      ),
      container: const SeedContainer(
        containerId: 'C01',
        varietyRef: 'V01',
        tubeCode: TubeCode(color: TubeColor.red, number: 12),
      ),
      codeNumber: 12,
      codeColorValue: 0xFFE53935,
      gruppe: 'Fruchtgemüse',
      art: 'Tomate',
      sorte: 'Ruthje',
      lateinischerName: 'Solanum lycopersicum',
      familie: 'Solanaceae',
      eigenschaft: 'Rot, klassisch und ertragreich',
      freiland: 'bedingt',
      gruenduengung: '—',
      nachbauNotwendig: '—',
      keimtempC: '20–24',
      tiefeCm: '0.5–1',
      abstandReiheCm: '60',
      abstandPflanzeCm: '50',
      hoehePflanzeCm: '150',
    ),
    SeedDetailModel(
      id: 'V02',
      variety: const Variety(
        varietyId: 'V02',
        taxonKey: TaxonKey(
          category: Category.blattgemueseSalat,
          species: 'Salat',
          varietyName: 'Lollo Rosso',
        ),
        activityWindows: [
          ActivityWindow(
            windowId: 'W02A',
            type: ActivityType.directSow,
            range: MonthRange(start: 1, end: 2),
          ),
        ],
      ),
      container: const SeedContainer(
        containerId: 'C02',
        varietyRef: 'V02',
        tubeCode: TubeCode(color: TubeColor.blue, number: 5),
      ),
      codeNumber: 5,
      codeColorValue: 0xFF1E88E5,
      gruppe: 'Blattgemüse',
      art: 'Salat',
      sorte: 'Lollo Rosso',
      lateinischerName: 'Lactuca sativa',
      familie: 'Asteraceae',
      eigenschaft: 'Rot, fransig, für frühe Saaten',
      freiland: 'ja',
      gruenduengung: '—',
      nachbauNotwendig: '—',
      keimtempC: '10–18',
      tiefeCm: '0.5',
      abstandReiheCm: '25',
      abstandPflanzeCm: '25',
      hoehePflanzeCm: '25',
    ),
    SeedDetailModel(
      id: 'V03',
      variety: const Variety(
        varietyId: 'V03',
        taxonKey: TaxonKey(
          category: Category.blattgemueseSalat,
          species: 'Spinat',
          varietyName: 'Matador',
        ),
        activityWindows: [
          ActivityWindow(
            windowId: 'W03A',
            type: ActivityType.directSow,
            range: MonthRange(start: 12, end: 2),
          ),
        ],
      ),
      container: const SeedContainer(
        containerId: 'C03',
        varietyRef: 'V03',
        tubeCode: TubeCode(color: TubeColor.green, number: 7),
      ),
      codeNumber: 7,
      codeColorValue: 0xFF43A047,
      gruppe: 'Blattgemüse',
      art: 'Spinat',
      sorte: 'Matador',
      lateinischerName: 'Spinacia oleracea',
      familie: 'Amaranthaceae',
      eigenschaft: 'Robust, für frühe Sätze',
      freiland: 'ja',
      gruenduengung: '—',
      nachbauNotwendig: '—',
      keimtempC: '8–15',
      tiefeCm: '2',
      abstandReiheCm: '20',
      abstandPflanzeCm: '5',
      hoehePflanzeCm: '20',
    ),
    SeedDetailModel(
      id: 'V04',
      variety: const Variety(
        varietyId: 'V04',
        taxonKey: TaxonKey(
          category: Category.blumen,
          species: 'Cosmea',
          varietyName: 'White Wonder',
        ),
        activityWindows: [
          ActivityWindow(
            windowId: 'W04A',
            type: ActivityType.preCulture,
            range: MonthRange(start: 10, end: 1),
          ),
        ],
      ),
      container: const SeedContainer(
        containerId: 'C04',
        varietyRef: 'V04',
        tubeCode: TubeCode(color: TubeColor.white, number: 99),
      ),
      codeNumber: 99,
      codeColorValue: 0xFFFFFFFF,
      gruppe: 'Blumensamen',
      art: 'Cosmea',
      sorte: 'White Wonder',
      lateinischerName: 'Cosmos bipinnatus',
      familie: 'Asteraceae',
      eigenschaft: 'Weiß blühend, filigran',
      freiland: 'ja',
      gruenduengung: '—',
      nachbauNotwendig: '—',
      keimtempC: '18–22',
      tiefeCm: '0.5–1',
      abstandReiheCm: '30',
      abstandPflanzeCm: '25',
      hoehePflanzeCm: '80',
    ),
    SeedDetailModel(
      id: 'V05',
      variety: const Variety(
        varietyId: 'V05',
        taxonKey: TaxonKey(
          category: Category.sonstigesGemuese,
          species: 'Möhre',
          varietyName: 'Nantes 2',
        ),
        activityWindows: [
          ActivityWindow(
            windowId: 'W05A',
            type: ActivityType.directSow,
            range: MonthRange(start: 11, end: 1),
          ),
        ],
      ),
      container: const SeedContainer(
        containerId: 'C05',
        varietyRef: 'V05',
        tubeCode: TubeCode(color: TubeColor.yellow, number: 31),
      ),
      codeNumber: 31,
      codeColorValue: 0xFFFDD835,
      gruppe: 'Wurzelgemüse',
      art: 'Möhre',
      sorte: 'Nantes 2',
      lateinischerName: 'Daucus carota',
      familie: 'Apiaceae',
      eigenschaft: 'Fein, süß, für frühen Satz',
      freiland: 'ja',
      gruenduengung: '—',
      nachbauNotwendig: '—',
      keimtempC: '8–18',
      tiefeCm: '1–2',
      abstandReiheCm: '30',
      abstandPflanzeCm: '4',
      hoehePflanzeCm: '35',
    ),
  ];

  @override
  List<Seed> getAllSeeds() => List<Seed>.unmodifiable(_seeds);

  @override
  Seed getSeedById(String id) {
    return _seeds.firstWhere((seed) => seed.id == id);
  }

  @override
  Future<void> createSeed(AppSeed seed) async {
    final targetVarietyId = seed.variety.varietyId.trim();
    final exists = _seeds.any(
      (existing) => existing.variety.varietyId == targetVarietyId,
    );
    if (exists) {
      throw StateError(
        'Seed with varietyId "$targetVarietyId" already exists.',
      );
    }
    _seeds.add(seed);
  }

  @override
  Future<void> updateSeed(AppSeed updatedSeed) async {
    final index = _seeds.indexWhere(
      (seed) => seed.variety.varietyId == updatedSeed.variety.varietyId,
    );
    if (index < 0) {
      throw StateError(
        'Seed with varietyId "${updatedSeed.variety.varietyId}" not found.',
      );
    }
    _seeds[index] = updatedSeed;
  }

  @override
  Future<void> deleteSeed(String varietyId) async {
    final targetVarietyId = varietyId.trim();
    final index = _seeds.indexWhere(
      (seed) => seed.variety.varietyId == targetVarietyId,
    );
    if (index < 0) {
      throw StateError('Seed with varietyId "$targetVarietyId" not found.');
    }
    _seeds.removeAt(index);
  }

  @override
  Future<String> exportWorkingCopyJson() async {
    final payload = <Map<String, dynamic>>[
      for (final seed in _seeds) _seedToAppFormatV1(seed),
    ];
    return jsonEncode(payload);
  }

  @override
  Future<void> importWorkingCopyJson(String json) async {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Import must be a JSON array.');
    }
    final importedSeeds = <Seed>[];
    for (var i = 0; i < decoded.length; i++) {
      importedSeeds.add(_mapper.fromJson(_v1SeedToLegacy(decoded[i], i)));
    }

    _seeds
      ..clear()
      ..addAll(importedSeeds);
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

  Map<String, dynamic> _v1SeedToLegacy(dynamic rawSeed, int index) {
    if (rawSeed is! Map) {
      throw FormatException(
        'Working copy entry[$index] must be a JSON object.',
      );
    }
    final seed = Map<String, dynamic>.from(rawSeed);
    final taxonKey = seed['taxonKey'];
    if (taxonKey is! Map) {
      throw FormatException(
        'Working copy entry[$index].taxonKey must be an object.',
      );
    }
    final taxon = Map<String, dynamic>.from(taxonKey);
    final categoryKey = taxon['category']?.toString();

    return {
      'variety_id': seed['varietyId'],
      'category': _categoryToLegacyLabel(categoryKey),
      'species': taxon['species'],
      'variety_name': taxon['varietyName'],
      'latin_name': seed['latin_name'],
      'container': _mapContainerToLegacy(seed['container']),
      'calendar': _mapCalendarToLegacy(seed),
      'botany': seed['botany'],
      'properties': seed['properties'],
      'cultivation': seed['cultivation'],
      'flags': seed['flags'],
    };
  }

  Map<String, dynamic>? _mapContainerToLegacy(dynamic container) {
    if (container == null) return null;
    if (container is! Map) {
      throw const FormatException('container must be an object when provided.');
    }
    final containerMap = Map<String, dynamic>.from(container);
    final tubeCode = containerMap['tubeCode'];
    if (tubeCode is! Map) {
      throw const FormatException('container.tubeCode must be an object.');
    }
    final tubeMap = Map<String, dynamic>.from(tubeCode);
    return {
      'tube_number': tubeMap['number'],
      'tube_color_key': tubeMap['color_key'],
    };
  }

  Map<String, dynamic> _mapCalendarToLegacy(Map<String, dynamic> seed) {
    final activityWindows = seed['activityWindows'];
    if (activityWindows is! List) {
      throw const FormatException('activityWindows must be a list.');
    }

    final directSow = <int>[];
    final preCulture = <int>[];
    for (final rawWindow in activityWindows) {
      if (rawWindow is! Map) {
        throw const FormatException('activityWindows entries must be objects.');
      }
      final window = Map<String, dynamic>.from(rawWindow);
      final months = _expandMonthRange(window['range']);
      if (window['type'] == 'DIRECT_SOW') {
        directSow.addAll(months);
      }
      if (window['type'] == 'PRE_CULTURE') {
        preCulture.addAll(months);
      }
    }

    final displayWindowsRaw = seed['displayWindows'];
    final displayWindows = displayWindowsRaw is Map
        ? Map<String, dynamic>.from(displayWindowsRaw)
        : const <String, dynamic>{};

    return {
      'aussaat': directSow,
      'voranzucht': preCulture,
      'auspflanzen': _expandDisplayRanges(displayWindows['auspflanzen']),
      'bluete': _expandDisplayRanges(displayWindows['bluete']),
      'ernte': _expandDisplayRanges(displayWindows['ernte']),
    };
  }

  List<int> _expandDisplayRanges(dynamic ranges) {
    if (ranges == null) return const [];
    if (ranges is! List) {
      throw const FormatException('display window value must be a list.');
    }
    final result = <int>[];
    for (final range in ranges) {
      result.addAll(_expandMonthRange(range));
    }
    return result;
  }

  List<int> _expandMonthRange(dynamic rawRange) {
    if (rawRange is! Map) {
      throw const FormatException('range must be an object.');
    }
    final range = Map<String, dynamic>.from(rawRange);
    final start = _asMonth(range['start']);
    final end = _asMonth(range['end']);
    if (start <= end) {
      return [for (var month = start; month <= end; month++) month];
    }
    return [
      for (var month = start; month <= 12; month++) month,
      for (var month = 1; month <= end; month++) month,
    ];
  }

  int _asMonth(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < 1 || parsed > 12) {
      throw const FormatException('Month must be 1..12.');
    }
    return parsed;
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

  String _categoryToLegacyLabel(String? key) {
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
}
