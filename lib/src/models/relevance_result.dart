import '../containers/tube_code.dart';
import '../types/enums.dart';
import 'activity_in_month.dart';
import 'variety.dart';

class RelevanceResult {
  final Variety variety;
  final int month; // 1..12
  final RelevancePhase phase;

  /// Per contract: for each ActivityType exactly one ActivityInMonth exists.
  final Map<ActivityType, ActivityInMonth> activities;

  /// Optional, because a Variety may have no SeedContainer.
  final TubeCode? tubeCode;

  const RelevanceResult({
    required this.variety,
    required this.month,
    required this.phase,
    required this.activities,
    required this.tubeCode,
  });
}
