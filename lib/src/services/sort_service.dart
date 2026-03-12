import '../containers/tube_code.dart';
import '../models/relevance_result.dart';
import '../types/enums.dart';

class SortService {
  const SortService();

  List<RelevanceResult> sortMonthlyOverview(List<RelevanceResult> input) {
    final out = List<RelevanceResult>.from(input);
    out.sort(_compare);
    return out;
  }

  int _compare(RelevanceResult a, RelevanceResult b) {
    // 1) RelevancePhase: NEW -> ONGOING -> ENDING
    final phaseCmp = _phaseRank(a.phase).compareTo(_phaseRank(b.phase));
    if (phaseCmp != 0) return phaseCmp;

    // 2) CategoryOrder (rank)
    final catA = a.variety.taxonKey.category;
    final catB = b.variety.taxonKey.category;
    final catCmp = _categoryRank(catA).compareTo(_categoryRank(catB));
    if (catCmp != 0) return catCmp;

    // 3) species (alpha)
    final speciesCmp = a.variety.taxonKey.species.compareTo(
      b.variety.taxonKey.species,
    );
    if (speciesCmp != 0) return speciesCmp;

    // 4) varietyName (alpha)
    final nameCmp = a.variety.taxonKey.varietyName.compareTo(
      b.variety.taxonKey.varietyName,
    );
    if (nameCmp != 0) return nameCmp;

    // 5) TubeCode: category-rank, then number (numeric)
    return _tubeCompare(
      a.tubeCode,
      b.tubeCode,
      _categoryRank(catA),
      _categoryRank(catB),
    );
  }

  int _phaseRank(RelevancePhase p) {
    switch (p) {
      case RelevancePhase.newPhase:
        return 1;
      case RelevancePhase.ongoing:
        return 2;
      case RelevancePhase.ending:
        return 3;
      case RelevancePhase.none:
        return 4; // typically not in overview
    }
  }

  int _tubeCompare(TubeCode? a, TubeCode? b, int rankA, int rankB) {
    // If both null, equal. If one null, push null to the end.
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;

    // ranks usually equal here, but keep deterministic.
    final rCmp = rankA.compareTo(rankB);
    if (rCmp != 0) return rCmp;

    final numCmp = a.number.compareTo(b.number);
    if (numCmp != 0) return numCmp;

    // final deterministic fallback
    return a.color.index.compareTo(b.color.index);
  }
}

/// Contract 4.1 CategoryOrder
int _categoryRank(Category c) {
  switch (c) {
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
