import 'package:test/test.dart';
import 'package:samenbank/src/data/seed_json_mapper.dart';

void main() {
  group('SeedJsonMapper', () {
    test('maps display-only calendar fields and meta fallback values', () {
      const mapper = SeedJsonMapper();

      final seed = mapper.fromJson({
        'variety_id': 'v1',
        'category': 'Fruchtgemüse',
        'species': 'Tomate',
        'variety_name': 'Ruthje',
        'container': {'tube_number': '7', 'tube_color_key': 'red'},
        'calendar': {
          'aussaat': [3, 4],
          'voranzucht': [2],
          'auspflanzen': [5, 6],
          'bluete': [7],
          'ernte': [8, 9],
        },
        'cultivation': {},
        'meta': {
          'abstand_reihe_cm': 70,
          'abstand_pflanze_cm': 40,
          'hoehe_cm': 120,
        },
        'flags': {'rebuild_required': true, 'variety_name_from_species': true},
      });

      expect(seed.auspflanzenRanges, hasLength(1));
      expect(seed.auspflanzenRanges.first.start, 5);
      expect(seed.auspflanzenRanges.first.end, 6);

      expect(seed.blueteRanges, hasLength(1));
      expect(seed.blueteRanges.first.start, 7);
      expect(seed.blueteRanges.first.end, 7);

      expect(seed.ernteRanges, hasLength(1));
      expect(seed.ernteRanges.first.start, 8);
      expect(seed.ernteRanges.first.end, 9);

      expect(seed.abstandReiheCm, '70');
      expect(seed.abstandPflanzeCm, '40');
      expect(seed.hoehePflanzeCm, '120');
      expect(seed.varietyNameFromSpecies, isTrue);
    });

    test('prefers cultivation values over meta fallback values', () {
      const mapper = SeedJsonMapper();

      final seed = mapper.fromJson({
        'variety_id': 'v2',
        'category': 'Fruchtgemüse',
        'species': 'Paprika',
        'variety_name': 'KOLA',
        'container': {'tube_number': 8, 'tube_color_key': 'green'},
        'calendar': {
          'aussaat': [],
          'voranzucht': [3],
        },
        'cultivation': {
          'row_spacing_cm': 50,
          'plant_spacing_cm': 30,
          'plant_height_cm': 90,
        },
        'meta': {
          'abstand_reihe_cm': 70,
          'abstand_pflanze_cm': 40,
          'hoehe_cm': 120,
        },
      });

      expect(seed.abstandReiheCm, '50');
      expect(seed.abstandPflanzeCm, '30');
      expect(seed.hoehePflanzeCm, '90');
    });

    test('supports missing optional calendar and optional lists as empty', () {
      const mapper = SeedJsonMapper();

      final seed = mapper.fromJson({
        'variety_id': 'v3',
        'category': 'Fruchtgemüse',
        'species': 'Aubergine',
        'variety_name': 'Moneymaker',
        'container': {'tube_number': '9', 'tube_color_key': 'blue'},
      });

      expect(seed.variety.activityWindows, isEmpty);
      expect(seed.auspflanzenRanges, isEmpty);
      expect(seed.blueteRanges, isEmpty);
      expect(seed.ernteRanges, isEmpty);
      expect(seed.varietyNameFromSpecies, isFalse);
    });

    test('rejects duplicate months in calendar lists', () {
      const mapper = SeedJsonMapper();

      expect(
        () => mapper.fromJson({
          'variety_id': 'v4',
          'category': 'Fruchtgemüse',
          'species': 'Tomate',
          'variety_name': 'Test',
          'container': {'tube_number': '10', 'tube_color_key': 'red'},
          'calendar': {
            'aussaat': [3, 3],
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects null calendar list entries', () {
      const mapper = SeedJsonMapper();

      expect(
        () => mapper.fromJson({
          'variety_id': 'v5',
          'category': 'Fruchtgemüse',
          'species': 'Tomate',
          'variety_name': 'Test',
          'container': {'tube_number': '11', 'tube_color_key': 'red'},
          'calendar': {'aussaat': null},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'maps freiland/gruenduengung from cultivation with properties fallback',
      () {
        const mapper = SeedJsonMapper();

        final withCultivation = mapper.fromJson({
          'variety_id': 'v7',
          'category': 'Fruchtgemüse',
          'species': 'Tomate',
          'variety_name': 'Alpha',
          'container': {'tube_number': '13', 'tube_color_key': 'red'},
          'properties': {'freiland': 'nein', 'gruenduengung': 'prop'},
          'cultivation': {'freiland': 'ja', 'gruenduengung': 'cult'},
        });

        expect(withCultivation.freiland, 'ja');
        expect(withCultivation.gruenduengung, 'cult');

        final fallbackProperties = mapper.fromJson({
          'variety_id': 'v8',
          'category': 'Fruchtgemüse',
          'species': 'Tomate',
          'variety_name': 'Beta',
          'container': {'tube_number': '14', 'tube_color_key': 'red'},
          'properties': {'freiland': 'nein', 'gruenduengung': 'prop'},
          'cultivation': {},
        });

        expect(fallbackProperties.freiland, 'nein');
        expect(fallbackProperties.gruenduengung, 'prop');
      },
    );

    test('maps keimtemp/tiefe from real keys with fallback', () {
      const mapper = SeedJsonMapper();

      final fromMeta = mapper.fromJson({
        'variety_id': 'v9',
        'category': 'Blattgemüse/Salat',
        'species': 'Neuseeländer Spinat',
        'variety_name': 'Neuseeländer Spinat',
        'container': {'tube_number': '15', 'tube_color_key': 'green'},
        'meta': {'keimtemp_c': 20, 'tiefe_cm': 3},
      });

      expect(fromMeta.keimtempC, '20');
      expect(fromMeta.tiefeCm, '3');

      final fromCultivationCanonical = mapper.fromJson({
        'variety_id': 'v10',
        'category': 'Fruchtgemüse',
        'species': 'Paprika',
        'variety_name': 'Gamma',
        'container': {'tube_number': '16', 'tube_color_key': 'yellow'},
        'cultivation': {'keimtemp_c': 24, 'tiefe_cm': 1},
      });

      expect(fromCultivationCanonical.keimtempC, '24');
      expect(fromCultivationCanonical.tiefeCm, '1');

      final fromCultivationLegacy = mapper.fromJson({
        'variety_id': 'v11',
        'category': 'Fruchtgemüse',
        'species': 'Chili',
        'variety_name': 'Delta',
        'container': {'tube_number': '17', 'tube_color_key': 'blue'},
        'cultivation': {'germination_temp_c': 26, 'sowing_depth_cm': 2},
      });

      expect(fromCultivationLegacy.keimtempC, '26');
      expect(fromCultivationLegacy.tiefeCm, '2');
    });

    test('rejects non-boolean flags.rebuild_required', () {
      const mapper = SeedJsonMapper();

      expect(
        () => mapper.fromJson({
          'variety_id': 'v6',
          'category': 'Fruchtgemüse',
          'species': 'Tomate',
          'variety_name': 'Test',
          'container': {'tube_number': '12', 'tube_color_key': 'red'},
          'flags': {'rebuild_required': 'ja'},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
