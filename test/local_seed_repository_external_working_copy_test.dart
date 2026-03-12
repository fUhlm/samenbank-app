import 'dart:convert';
import 'dart:io';

import 'package:samenbank/src/data/working_copy_v1_initializer.dart';
import 'package:samenbank/src/containers/seed_container.dart';
import 'package:samenbank/src/containers/tube_code.dart';
import 'package:samenbank/src/repositories/local_seed_repository.dart';
import 'package:samenbank/src/models/seed_detail_model.dart';
import 'package:samenbank/src/models/variety.dart';
import 'package:samenbank/src/models/taxon_key.dart';
import 'package:test/test.dart';

void main() {
  group('LocalSeedRepository external working copy', () {
    test('uses external URI for load and write when configured', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'samenbank_external_repo_',
      );
      addTearDown(() async => tempDir.delete(recursive: true));

      final internalFile = File('${tempDir.path}/$appFormatV1FileName');
      await internalFile.writeAsString(jsonEncode(_datasetInternal()));

      const uri = 'content://test/working_copy.json';
      final externalDataSource = _FakeExternalWorkingCopyDataSource(
        initialData: <String, String>{uri: jsonEncode(_datasetExternal())},
      );

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
        externalWorkingCopyDataSource: externalDataSource,
        externalWorkingCopyUri: uri,
      );

      await repository.init();

      expect(repository.activeExternalWorkingCopyUri, uri);
      expect(repository.getAllSeeds().single.variety.varietyId, 'E01');

      final existing = repository.getAllSeeds().single;
      final created = _cloneWithVarietyId(existing, 'E02');

      await repository.createSeed(created);

      expect(externalDataSource.writeCountFor(uri), 1);
      final saved = jsonDecode(externalDataSource.payloadFor(uri)!) as List;
      expect(saved, hasLength(2));
      expect((saved[1] as Map<String, dynamic>)['varietyId'], 'E02');
    });

    test('invalid external JSON cannot be activated', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'samenbank_external_invalid_',
      );
      addTearDown(() async => tempDir.delete(recursive: true));

      final internalFile = File('${tempDir.path}/$appFormatV1FileName');
      await internalFile.writeAsString(jsonEncode(_datasetInternal()));

      const invalidUri = 'content://test/invalid_working_copy.json';
      final externalDataSource = _FakeExternalWorkingCopyDataSource(
        initialData: <String, String>{
          invalidUri: jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'varietyId': 'BROKEN',
              'taxonKey': <String, dynamic>{
                'category': 'FRUCHTGEMUESE',
                'species': 'Tomate',
              },
              'activityWindows': <dynamic>[],
            },
          ]),
        },
      );

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
        externalWorkingCopyDataSource: externalDataSource,
      );

      await repository.init();
      expect(repository.getAllSeeds().single.variety.varietyId, 'I01');

      await expectLater(
        repository.setExternalWorkingCopyUri(invalidUri),
        throwsA(isA<FormatException>()),
      );

      expect(repository.activeExternalWorkingCopyUri, isNull);
      expect(repository.getAllSeeds().single.variety.varietyId, 'I01');
    });

    test('activates external URI even when canRead returns false', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'samenbank_external_canread_false_',
      );
      addTearDown(() async => tempDir.delete(recursive: true));

      final internalFile = File('${tempDir.path}/$appFormatV1FileName');
      await internalFile.writeAsString(jsonEncode(_datasetInternal()));

      const uri = 'content://test/can_read_false_working_copy.json';
      final externalDataSource = _FakeExternalWorkingCopyDataSource(
        initialData: <String, String>{uri: jsonEncode(_datasetExternal())},
        forceCanReadFalse: true,
      );

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
        externalWorkingCopyDataSource: externalDataSource,
      );

      await repository.init();
      await repository.setExternalWorkingCopyUri(uri);

      expect(repository.activeExternalWorkingCopyUri, uri);
      expect(repository.getAllSeeds().single.variety.varietyId, 'E01');
    });

    test(
      'clearExternalWorkingCopyUri switches back to internal working copy',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'samenbank_external_clear_',
        );
        addTearDown(() async => tempDir.delete(recursive: true));

        final internalFile = File('${tempDir.path}/$appFormatV1FileName');
        await internalFile.writeAsString(jsonEncode(_datasetInternal()));

        const uri = 'content://test/working_copy_clear.json';
        final externalDataSource = _FakeExternalWorkingCopyDataSource(
          initialData: <String, String>{uri: jsonEncode(_datasetExternal())},
        );

        final repository = LocalSeedRepository(
          initializer: WorkingCopyV1Initializer(),
          documentsDirectoryProvider: () async => tempDir,
          externalWorkingCopyDataSource: externalDataSource,
          externalWorkingCopyUri: uri,
        );

        await repository.init();
        expect(repository.activeExternalWorkingCopyUri, uri);
        expect(repository.getAllSeeds().single.variety.varietyId, 'E01');

        await repository.clearExternalWorkingCopyUri();

        expect(repository.activeExternalWorkingCopyUri, isNull);
        expect(repository.getAllSeeds().single.variety.varietyId, 'I01');
      },
    );
  });
}

SeedDetailModel _cloneWithVarietyId(
  SeedDetailModel original,
  String varietyId,
) {
  return SeedDetailModel(
    id: varietyId,
    variety: Variety(
      varietyId: varietyId,
      taxonKey: TaxonKey(
        category: original.variety.taxonKey.category,
        species: original.variety.taxonKey.species,
        varietyName: '${original.variety.taxonKey.varietyName} $varietyId',
      ),
      activityWindows: original.variety.activityWindows,
    ),
    container: original.container == null
        ? null
        : SeedContainer(
            containerId: 'C$varietyId',
            varietyRef: varietyId,
            tubeCode: TubeCode(
              color: original.container!.tubeCode.color,
              number: original.container!.tubeCode.number + 1,
            ),
          ),
    codeNumber: original.codeNumber,
    codeColorValue: original.codeColorValue,
    gruppe: original.gruppe,
    art: original.art,
    sorte: '${original.sorte} $varietyId',
    lateinischerName: original.lateinischerName,
    familie: original.familie,
    eigenschaft: original.eigenschaft,
    freiland: original.freiland,
    gruenduengung: original.gruenduengung,
    nachbauNotwendig: original.nachbauNotwendig,
    keimtempC: original.keimtempC,
    tiefeCm: original.tiefeCm,
    abstandReiheCm: original.abstandReiheCm,
    abstandPflanzeCm: original.abstandPflanzeCm,
    hoehePflanzeCm: original.hoehePflanzeCm,
    auspflanzenRanges: original.auspflanzenRanges,
    blueteRanges: original.blueteRanges,
    ernteRanges: original.ernteRanges,
    varietyNameFromSpecies: original.varietyNameFromSpecies,
  );
}

class _FakeExternalWorkingCopyDataSource
    implements ExternalWorkingCopyDataSource {
  _FakeExternalWorkingCopyDataSource({
    required Map<String, String> initialData,
    this.forceCanReadFalse = false,
  }) : _store = Map<String, String>.from(initialData);

  final Map<String, String> _store;
  final Map<String, int> _writeCount = <String, int>{};
  final bool forceCanReadFalse;

  @override
  Future<bool> canRead(String uri) async =>
      !forceCanReadFalse && _store.containsKey(uri);

  @override
  Future<String> read(String uri) async {
    final payload = _store[uri];
    if (payload == null) {
      throw const FileSystemException('URI not found');
    }
    return payload;
  }

  @override
  Future<void> write(String uri, String json) async {
    _store[uri] = json;
    _writeCount[uri] = (_writeCount[uri] ?? 0) + 1;
  }

  String? payloadFor(String uri) => _store[uri];

  int writeCountFor(String uri) => _writeCount[uri] ?? 0;
}

List<Map<String, dynamic>> _datasetInternal() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'varietyId': 'I01',
      'taxonKey': <String, dynamic>{
        'category': 'FRUCHTGEMUESE',
        'species': 'Tomate',
        'varietyName': 'Intern',
      },
      'latin_name': 'Solanum lycopersicum',
      'container': <String, dynamic>{
        'containerId': 'CI01',
        'varietyRef': 'I01',
        'tubeCode': <String, dynamic>{'color_key': 'red', 'number': 1},
      },
      'activityWindows': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'DIRECT_SOW',
          'range': <String, dynamic>{'start': 3, 'end': 4},
        },
      ],
      'cultivation': <String, dynamic>{'freiland': 'ja'},
      'properties': <String, dynamic>{'eigenschaft': 'intern'},
      'botany': <String, dynamic>{'family': 'Solanaceae'},
      'flags': <String, dynamic>{
        'rebuild_required': false,
        'variety_name_from_species': false,
      },
    },
  ];
}

List<Map<String, dynamic>> _datasetExternal() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'varietyId': 'E01',
      'taxonKey': <String, dynamic>{
        'category': 'FRUCHTGEMUESE',
        'species': 'Paprika',
        'varietyName': 'Extern',
      },
      'latin_name': 'Capsicum annuum',
      'container': <String, dynamic>{
        'containerId': 'CE01',
        'varietyRef': 'E01',
        'tubeCode': <String, dynamic>{'color_key': 'yellow', 'number': 2},
      },
      'activityWindows': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'PRE_CULTURE',
          'range': <String, dynamic>{'start': 2, 'end': 3},
        },
      ],
      'cultivation': <String, dynamic>{'freiland': 'ja'},
      'properties': <String, dynamic>{'eigenschaft': 'extern'},
      'botany': <String, dynamic>{'family': 'Solanaceae'},
      'flags': <String, dynamic>{
        'rebuild_required': false,
        'variety_name_from_species': false,
      },
    },
  ];
}
