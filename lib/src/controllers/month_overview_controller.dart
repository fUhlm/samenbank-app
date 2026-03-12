import 'dart:developer' as developer;

import '../models/relevance_result.dart';
import '../types/enums.dart';
import '../repositories/seed_repository.dart';
import '../services/relevance_service.dart';

/// Month overview builder + presentation sorting.
///
/// Sorting rule (Felix):
/// 1) Category (fixed rank)
/// 2) Within each category: NEW -> ONGOING -> ENDING
/// 3) Then: species -> varietyName (alphabetical)
class MonthOverviewController {
  MonthOverviewController({
    required this.repository,
    int? selectedMonth,
    RelevanceService? relevanceService,
  }) : selectedMonth = selectedMonth ?? DateTime.now().month,
       _relevanceService = relevanceService ?? const RelevanceService();

  final SeedRepository repository;
  int selectedMonth;
  final RelevanceService _relevanceService;

  List<({Seed seed, RelevanceResult relevance})> buildOverview() {
    final seeds = repository.getAllSeeds();

    // IMPORTANT:
    // varieties and containers MUST be built from the same seed list to keep
    // index alignment for domain computation.
    final seedsWithContainer = seeds
        .where((seed) => seed.container != null)
        .toList(growable: false);

    final varieties = seedsWithContainer
        .map((seed) => seed.variety)
        .toList(growable: false);

    final containers = seedsWithContainer
        .map((seed) => seed.container!)
        .toList(growable: false);

    final results = _relevanceService.relevantForMonth(
      month: selectedMonth,
      varieties: varieties,
      containers: containers,
    );

    final seedByVarietyId = {
      for (final seed in seedsWithContainer) seed.variety.varietyId: seed,
    };

    final items = <({Seed seed, RelevanceResult relevance})>[];
    for (final result in results) {
      final seed = seedByVarietyId[result.variety.varietyId];
      if (seed == null) {
        assert(() {
          developer.log(
            'Seed not found for varietyId=${result.variety.varietyId}',
            name: 'MonthOverviewController',
          );
          return true;
        }());
        continue;
      }
      items.add((seed: seed, relevance: result));
    }

    items.sort(_compare);
    return items;
  }

  void nextMonth() {
    selectedMonth = selectedMonth == 12 ? 1 : selectedMonth + 1;
  }

  void previousMonth() {
    selectedMonth = selectedMonth == 1 ? 12 : selectedMonth - 1;
  }

  int _compare(
    ({Seed seed, RelevanceResult relevance}) a,
    ({Seed seed, RelevanceResult relevance}) b,
  ) {
    // 1) Category
    final aKey = a.relevance.variety.taxonKey;
    final bKey = b.relevance.variety.taxonKey;

    final categoryCmp = _categoryRank(
      aKey.category,
    ).compareTo(_categoryRank(bKey.category));
    if (categoryCmp != 0) return categoryCmp;

    // 2) Phase within category: NEW -> ONGOING -> ENDING
    final phaseCmp = _phaseRank(
      a.relevance.phase,
    ).compareTo(_phaseRank(b.relevance.phase));
    if (phaseCmp != 0) return phaseCmp;

    // 3) Species
    final speciesCmp = aKey.species.compareTo(bKey.species);
    if (speciesCmp != 0) return speciesCmp;

    // 4) Variety name
    final nameCmp = aKey.varietyName.compareTo(bKey.varietyName);
    if (nameCmp != 0) return nameCmp;

    // 5) Optional: tube number as stable tiebreaker (nulls last)
    final aTube = a.relevance.tubeCode;
    final bTube = b.relevance.tubeCode;
    if (aTube == null && bTube == null) return 0;
    if (aTube == null) return 1;
    if (bTube == null) return -1;
    return aTube.number.compareTo(bTube.number);
  }
}

int _phaseRank(RelevancePhase phase) {
  switch (phase) {
    case RelevancePhase.newPhase:
      return 1;
    case RelevancePhase.ongoing:
      return 2;
    case RelevancePhase.ending:
      return 3;
    case RelevancePhase.none:
      return 9999;
  }
}

int _categoryRank(Category category) {
  switch (category) {
    case Category.fruchtgemuese:
      return 1;
    case Category.kuerbisartige:
      return 2;
    case Category.kohlgewaechse:
      return 3;
    case Category.blattgemueseSalat:
      return 4;
    case Category.leguminosen:
      return 5;
    case Category.sonstigesGemuese:
      return 6;
    case Category.kraeuter:
      return 7;
    case Category.blumen:
      return 8;
    case Category.unknown:
      return 9999;
  }
}
