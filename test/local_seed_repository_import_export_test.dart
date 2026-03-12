import 'dart:convert';
import 'dart:io';

import 'package:samenbank/src/data/working_copy_v1_initializer.dart';
import 'package:samenbank/src/repositories/local_seed_repository.dart';
import 'package:test/test.dart';

void main() {
  group('LocalSeedRepository import/export', () {
    test('exportWorkingCopyJson returns parseable app-format JSON', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'samenbank_export_',
      );
      addTearDown(() async => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}/$appFormatV1FileName');
      await file.writeAsString(jsonEncode(_datasetA()));

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
      );
      await repository.init();

      final exportedJson = await repository.exportWorkingCopyJson();
      final decoded = jsonDecode(exportedJson);

      expect(decoded, isA<List>());
      expect((decoded as List), isNotEmpty);
      final first = decoded.first;
      expect(first, isA<Map>());
      expect((first as Map)['varietyId'], isNotNull);
      expect(first['taxonKey'], isNotNull);
      expect(first['activityWindows'], isNotNull);
    });

    test(
      'importWorkingCopyJson(valid) replaces all data and persists',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'samenbank_import_valid_',
        );
        addTearDown(() async => tempDir.delete(recursive: true));

        final file = File('${tempDir.path}/$appFormatV1FileName');
        await file.writeAsString(jsonEncode(_datasetA()));

        final repository = LocalSeedRepository(
          initializer: WorkingCopyV1Initializer(),
          documentsDirectoryProvider: () async => tempDir,
        );
        await repository.init();

        expect(repository.getAllSeeds(), hasLength(1));
        expect(repository.getAllSeeds().first.variety.varietyId, 'A01');

        await repository.importWorkingCopyJson(jsonEncode(_datasetB()));

        expect(repository.getAllSeeds(), hasLength(1));
        expect(repository.getAllSeeds().first.variety.varietyId, 'B99');

        final reloaded = LocalSeedRepository(
          initializer: WorkingCopyV1Initializer(),
          documentsDirectoryProvider: () async => tempDir,
        );
        await reloaded.init();
        expect(reloaded.getAllSeeds(), hasLength(1));
        expect(reloaded.getAllSeeds().first.variety.varietyId, 'B99');
      },
    );

    test(
      'importWorkingCopyJson(invalid) keeps existing working copy unchanged',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'samenbank_import_invalid_',
        );
        addTearDown(() async => tempDir.delete(recursive: true));

        final file = File('${tempDir.path}/$appFormatV1FileName');
        await file.writeAsString(jsonEncode(_datasetA()));
        final before = await file.readAsString();

        final repository = LocalSeedRepository(
          initializer: WorkingCopyV1Initializer(),
          documentsDirectoryProvider: () async => tempDir,
        );
        await repository.init();

        await expectLater(
          repository.importWorkingCopyJson(jsonEncode(_invalidDataset())),
          throwsA(isA<FormatException>()),
        );

        final after = await file.readAsString();
        expect(after, before);
        expect(repository.getAllSeeds(), hasLength(1));
        expect(repository.getAllSeeds().first.variety.varietyId, 'A01');
      },
    );
  });
}

List<Map<String, dynamic>> _datasetA() {
  return [
    {
      'varietyId': 'A01',
      'taxonKey': {
        'category': 'FRUCHTGEMUESE',
        'species': 'Tomate',
        'varietyName': 'Alpha',
      },
      'latin_name': 'Solanum lycopersicum',
      'container': {
        'containerId': 'CA01',
        'varietyRef': 'A01',
        'tubeCode': {'color_key': 'red', 'number': 1},
      },
      'activityWindows': [
        {
          'type': 'DIRECT_SOW',
          'range': {'start': 3, 'end': 4},
        },
      ],
      'displayWindows': {
        'auspflanzen': [
          {'start': 5, 'end': 6},
        ],
        'bluete': [
          {'start': 7, 'end': 8},
        ],
        'ernte': [
          {'start': 9, 'end': 10},
        ],
      },
      'cultivation': {
        'freiland': 'ja',
        'gruenduengung': null,
        'keimtemp_c': '18-22',
        'tiefe_cm': '0.5',
        'row_spacing_cm': '50',
        'plant_spacing_cm': '40',
        'plant_height_cm': '120',
      },
      'properties': {'eigenschaft': 'fruchtig'},
      'botany': {'family': 'Solanaceae'},
      'flags': {'rebuild_required': false, 'variety_name_from_species': false},
    },
  ];
}

List<Map<String, dynamic>> _datasetB() {
  return [
    {
      'varietyId': 'B99',
      'taxonKey': {
        'category': 'BLUMEN',
        'species': 'Tagetes',
        'varietyName': 'Beta',
      },
      'latin_name': 'Tagetes patula',
      'container': {
        'containerId': 'CB99',
        'varietyRef': 'B99',
        'tubeCode': {'color_key': 'yellow', 'number': 99},
      },
      'activityWindows': [
        {
          'type': 'PRE_CULTURE',
          'range': {'start': 2, 'end': 3},
        },
      ],
      'cultivation': {
        'freiland': null,
        'gruenduengung': null,
        'keimtemp_c': '16-20',
        'tiefe_cm': '1',
        'row_spacing_cm': '25',
        'plant_spacing_cm': '20',
        'plant_height_cm': '35',
      },
      'properties': {'eigenschaft': 'niedrig'},
      'botany': {'family': 'Asteraceae'},
      'flags': {'rebuild_required': null, 'variety_name_from_species': false},
    },
  ];
}

List<Map<String, dynamic>> _invalidDataset() {
  return [
    {
      'varietyId': 'BROKEN',
      'taxonKey': {'category': 'FRUCHTGEMUESE', 'species': 'Tomate'},
      'activityWindows': const [],
    },
  ];
}
