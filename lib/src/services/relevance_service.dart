import '../calendar/activity_status_logic.dart';
import '../calendar/month_math.dart';
import '../calendar/month_range_logic.dart';
import '../containers/seed_container.dart';
import '../containers/tube_code.dart';
import '../models/activity_in_month.dart';
import '../models/activity_window.dart';
import '../models/relevance_result.dart';
import '../models/variety.dart';
import '../types/enums.dart';

class RelevanceService {
  const RelevanceService();

  /// Build an index varietyId -> TubeCode (optional)
  Map<String, TubeCode> buildTubeIndex(List<SeedContainer> containers) {
    return {for (final c in containers) c.varietyRef: c.tubeCode};
  }

  RelevanceResult evaluateVarietyForMonth({
    required Variety variety,
    required int month,
    TubeCode? tubeCode,
  }) {
    validateMonth(month);

    final windowsByType = <ActivityType, List<ActivityWindow>>{
      for (final t in ActivityType.values) t: <ActivityWindow>[],
    };

    for (final w in variety.activityWindows) {
      windowsByType[w.type]!.add(w);
    }

    final activities = <ActivityType, ActivityInMonth>{};

    bool startsAny = false;
    bool continuesAny = false;
    bool endsAny = false;
    bool anyActive = false;

    for (final t in ActivityType.values) {
      final activeWindows = <ActivityWindow>[];
      bool starts = false;
      bool continues = false;
      bool ends = false;

      for (final w in windowsByType[t]!) {
        if (!containsMonth(w.range, month)) continue;
        activeWindows.add(w);
        anyActive = true;

        final flags = statusFlagsForMonth(w.range, month);
        starts = starts || flags.starts;
        continues = continues || flags.continues;
        ends = ends || flags.ends;
      }

      startsAny = startsAny || starts;
      continuesAny = continuesAny || continues;
      endsAny = endsAny || ends;

      activities[t] = ActivityInMonth(
        type: t,
        starts: starts,
        continues: continues,
        ends: ends,
        activeWindowIds: activeWindows
            .map((e) => e.windowId)
            .toList(growable: false),
      );
    }

    final phase = _phase(
      startsAny: startsAny,
      continuesAny: continuesAny,
      endsAny: endsAny,
    );

    return RelevanceResult(
      variety: variety,
      month: month,
      phase: anyActive ? phase : RelevancePhase.none,
      activities: activities,
      tubeCode: tubeCode,
    );
  }

  List<RelevanceResult> relevantForMonth({
    required int month,
    required List<Variety> varieties,
    List<SeedContainer> containers = const [],
  }) {
    validateMonth(month);
    final tubeIndex = buildTubeIndex(containers);

    final results = <RelevanceResult>[];
    for (final v in varieties) {
      final res = evaluateVarietyForMonth(
        variety: v,
        month: month,
        tubeCode: tubeIndex[v.varietyId],
      );
      if (res.phase != RelevancePhase.none) results.add(res);
    }
    return results;
  }

  RelevancePhase _phase({
    required bool startsAny,
    required bool continuesAny,
    required bool endsAny,
  }) {
    // Contract 8.1 strict priority:
    // 1 NEW if exists starts==true
    // 2 ONGOING else if exists continues==true
    // 3 ENDING else if exists ends==true and others false
    // 4 NONE
    if (startsAny) return RelevancePhase.newPhase;
    if (continuesAny) return RelevancePhase.ongoing;
    if (endsAny) return RelevancePhase.ending;
    return RelevancePhase.none;
  }
}
