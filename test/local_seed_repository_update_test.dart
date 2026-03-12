import 'dart:convert';
import 'dart:io';

import 'package:samenbank/src/data/working_copy_v1_initializer.dart';
import 'package:samenbank/src/containers/seed_container.dart';
import 'package:samenbank/src/containers/tube_code.dart';
import 'package:samenbank/src/models/activity_window.dart';
import 'package:samenbank/src/models/month_range.dart';
import 'package:samenbank/src/models/seed_detail_model.dart';
import 'package:samenbank/src/models/taxon_key.dart';
import 'package:samenbank/src/models/variety.dart';
import 'package:samenbank/src/repositories/local_seed_repository.dart';
import 'package:samenbank/src/types/enums.dart';
import 'package:test/test.dart';

void main() {
  group('LocalSeedRepository.createSeed', () {
    test('adds seed and persists to seeds_app_v1.json', () async {
      final tempDir = await Directory.systemTemp.createTemp('samenbank_add_');
      addTearDown(() async => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}/$appFormatV1FileName');
      await file.writeAsString(jsonEncode(_v1Seeds()));

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
      );
      await repository.init();

      final created = _copySeed(
        repository.getSeedById('V01'),
        variety: const Variety(
          varietyId: 'V99',
          taxonKey: TaxonKey(
            category: Category.fruchtgemuese,
            species: 'Paprika',
            varietyName: 'Nova',
          ),
          activityWindows: [
            ActivityWindow(
              windowId: 'W99A',
              type: ActivityType.directSow,
              range: MonthRange(start: 4, end: 5),
            ),
          ],
        ),
        container: const SeedContainer(
          containerId: 'CV99',
          varietyRef: 'V99',
          tubeCode: TubeCode(color: TubeColor.red, number: 99),
        ),
      );

      await repository.createSeed(created);

      expect(repository.getAllSeeds(), hasLength(2));
      expect(await File('${file.path}.tmp').exists(), isFalse);

      final reloaded = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
      );
      await reloaded.init();
      expect(reloaded.getAllSeeds(), hasLength(2));
      expect(reloaded.getSeedById('V99').sorte, 'Nova');
    });
  });

  group('LocalSeedRepository.updateSeed', () {
    test('persists replacement to seeds_app_v1.json', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'samenbank_update_',
      );
      addTearDown(() async => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}/$appFormatV1FileName');
      await file.writeAsString(jsonEncode(_v1Seeds()));

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
      );

      await repository.init();
      final original = repository.getSeedById('V01');
      final updated = _copySeed(original, freiland: 'nein');

      await repository.updateSeed(updated);

      final reloaded = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
      );
      await reloaded.init();

      expect(reloaded.getSeedById('V01').freiland, 'nein');
      expect(await File('${file.path}.tmp').exists(), isFalse);
    });

    test('throws when working copy file is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'samenbank_missing_',
      );
      addTearDown(() async => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}/$appFormatV1FileName');
      await file.writeAsString(jsonEncode(_v1Seeds()));

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
      );
      await repository.init();
      await file.delete();

      final original = repository.getSeedById('V01');
      await expectLater(
        repository.updateSeed(_copySeed(original, freiland: 'ja')),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('validates activity window month range bounds', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'samenbank_validate_',
      );
      addTearDown(() async => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}/$appFormatV1FileName');
      await file.writeAsString(jsonEncode(_v1Seeds()));

      final repository = LocalSeedRepository(
        initializer: WorkingCopyV1Initializer(),
        documentsDirectoryProvider: () async => tempDir,
      );
      await repository.init();

      final original = repository.getSeedById('V01');
      final windows = <ActivityWindow>[
        ActivityWindow(
          windowId: original.variety.activityWindows.first.windowId,
          type: original.variety.activityWindows.first.type,
          range: const MonthRange(start: 0, end: 2),
        ),
      ];

      final invalid = _copySeed(
        original,
        variety: Variety(
          varietyId: original.variety.varietyId,
          taxonKey: original.variety.taxonKey,
          activityWindows: windows,
        ),
      );

      await expectLater(
        repository.updateSeed(invalid),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LocalSeedRepository.deleteSeed', () {
    test(
      'removes seed from cache and persists removal to seeds_app_v1.json',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'samenbank_delete_',
        );
        addTearDown(() async => tempDir.delete(recursive: true));

        final file = File('${tempDir.path}/$appFormatV1FileName');
        await file.writeAsString(jsonEncode(_v1Seeds()));

        final repository = LocalSeedRepository(
          initializer: WorkingCopyV1Initializer(),
          documentsDirectoryProvider: () async => tempDir,
        );
        await repository.init();

        await repository.deleteSeed('V01');

        expect(repository.getAllSeeds(), isEmpty);
        expect(await File('${file.path}.tmp').exists(), isFalse);

        final reloaded = LocalSeedRepository(
          initializer: WorkingCopyV1Initializer(),
          documentsDirectoryProvider: () async => tempDir,
        );
        await reloaded.init();
        expect(reloaded.getAllSeeds(), isEmpty);
      },
    );
  });
}

SeedDetailModel _copySeed(
  SeedDetailModel original, {
  String? freiland,
  Variety? variety,
  SeedContainer? container,
}) {
  return SeedDetailModel(
    id: original.id,
    variety: variety ?? original.variety,
    container: container ?? original.container,
    codeNumber: original.codeNumber,
    codeColorValue: original.codeColorValue,
    gruppe: original.gruppe,
    art: original.art,
    sorte: original.sorte,
    lateinischerName: original.lateinischerName,
    familie: original.familie,
    eigenschaft: original.eigenschaft,
    freiland: freiland ?? original.freiland,
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

List<Map<String, dynamic>> _v1Seeds() {
  return [
    {
      'varietyId': 'V01',
      'taxonKey': {
        'category': 'FRUCHTGEMUESE',
        'species': 'Tomate',
        'varietyName': 'Ruthje',
      },
      'latin_name': 'Solanum lycopersicum',
      'container': {
        'containerId': 'CV01',
        'varietyRef': 'V01',
        'tubeCode': {'color_key': 'red', 'number': 12},
      },
      'activityWindows': [
        {
          'type': 'DIRECT_SOW',
          'range': {'start': 3, 'end': 5},
        },
      ],
      'cultivation': {'freiland': 'ja'},
      'properties': {'eigenschaft': 'x'},
      'botany': {'family': 'Solanaceae'},
      'flags': {'rebuild_required': false, 'variety_name_from_species': false},
    },
  ];
}
