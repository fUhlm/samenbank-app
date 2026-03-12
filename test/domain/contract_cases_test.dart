import 'package:test/test.dart';
import 'package:samenbank/samenbank_domain.dart';

import 'helpers.dart';

RelevancePhase phaseFromString(String s) {
  return RelevancePhase.values.firstWhere((e) => e.name == s);
}

void main() {
  final varieties = loadVarieties();
  final containers = loadContainers();

  final relevance = RelevanceService();
  final sorter = SortService();
  final validator = ValidationService();

  group('Dataset validation', () {
    test(
      'valid fixtures pass (taxonKey uniqueness + containers uniqueness + color map)',
      () {
        expect(() => validator.validateVarieties(varieties), returnsNormally);
        expect(() => validator.validateContainers(containers), returnsNormally);
        expect(
          () => validator.validateContainerColors(
            varieties: varieties,
            containers: containers,
          ),
          returnsNormally,
        );
      },
    );

    test('invalid_dataset.json throws', () {
      final inv = loadInvalidDataset();

      final invVarietiesRaw = (inv['invalidVarieties'] as List<dynamic>);
      final invVarieties = invVarietiesRaw
          .map((e) => varietyFromJson(e as Map<String, dynamic>))
          .toList();

      expect(
        () => validator.validateVarieties(invVarieties),
        throwsA(isA<DuplicateTaxonKeyError>()),
      );

      final invContainersRaw = (inv['invalidContainers'] as List<dynamic>);
      final invContainers = invContainersRaw
          .map((e) => containerFromJson(e as Map<String, dynamic>))
          .toList();

      expect(
        () => validator.validateContainers(invContainers),
        throwsA(
          anyOf(
            isA<InvalidContainerAssignmentError>(),
            isA<InvalidTubeCodeError>(),
          ),
        ),
      );
    });
  });

  group('Expected cases (expected.json)', () {
    final byId = {for (final v in varieties) v.varietyId: v};
    final tubeIndex = relevance.buildTubeIndex(containers);

    for (final rawCase in loadExpectedCases()) {
      final c = rawCase as Map<String, dynamic>;
      final caseId = c['caseId'] as String;

      if (c.containsKey('varietyId')) {
        test(caseId, () {
          final varietyId = c['varietyId'] as String;
          final v = byId[varietyId]!;
          final checks = c['checks'] as List<dynamic>;

          for (final chkRaw in checks) {
            final chk = chkRaw as Map<String, dynamic>;
            final month = chk['month'] as int;

            final res = relevance.evaluateVarietyForMonth(
              variety: v,
              month: month,
              tubeCode: tubeIndex[v.varietyId],
            );

            expect(
              res.phase != RelevancePhase.none,
              equals(chk['isRelevant'] as bool),
              reason: '$caseId month=$month relevance',
            );
            expect(
              res.phase.name,
              equals(chk['phase'] as String),
              reason: '$caseId month=$month phase',
            );

            if (chk.containsKey('activity')) {
              final act = chk['activity'] as Map<String, dynamic>;
              for (final entry in act.entries) {
                final t = ActivityType.values.firstWhere(
                  (e) => e.name == entry.key,
                );
                final expected = entry.value as Map<String, dynamic>;
                final a = res.activities[t]!;
                expect(
                  a.starts,
                  expected['starts'] as bool,
                  reason: '$caseId month=$month $t starts',
                );
                expect(
                  a.continues,
                  expected['continues'] as bool,
                  reason: '$caseId month=$month $t continues',
                );
                expect(
                  a.ends,
                  expected['ends'] as bool,
                  reason: '$caseId month=$month $t ends',
                );

                final expectedIds =
                    (expected['activeWindowIds'] as List<dynamic>)
                        .cast<String>();
                expect(
                  a.activeWindowIds,
                  orderedEquals(expectedIds),
                  reason: '$caseId month=$month $t activeWindowIds',
                );
              }
            }
          }
        });
      } else if (c.containsKey('overview')) {
        test(caseId, () {
          final ov = c['overview'] as Map<String, dynamic>;
          final month = ov['month'] as int;
          final inputIds = (ov['inputVarietyIds'] as List<dynamic>)
              .cast<String>();
          final expectedSorted =
              (ov['expectedSortedVarietyIds'] as List<dynamic>).cast<String>();

          final inputVarieties = inputIds.map((id) => byId[id]!).toList();

          final results = relevance.relevantForMonth(
            month: month,
            varieties: inputVarieties,
            containers: containers,
          );
          final sorted = sorter.sortMonthlyOverview(results);

          final gotIds = sorted.map((r) => r.variety.varietyId).toList();
          expect(gotIds, orderedEquals(expectedSorted));
        });
      } else {
        test(caseId, () {
          fail('Unknown case shape in expected.json for $caseId');
        });
      }
    }
  });
}
