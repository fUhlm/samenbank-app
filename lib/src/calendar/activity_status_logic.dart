import '../models/month_range.dart';
//import '../types/enums.dart';
import 'month_math.dart';
import 'month_range_logic.dart';

/// Per contract:
/// - active in m: contains(range,m)
/// - starts: active(m) && !active(prevMonth(m))
/// - continues: active(m) && active(prevMonth(m))
/// - ends: active(m) && !active(nextMonth(m))
///
/// Note: a one-month window has starts==true and ends==true in that month.
class ActivityStatusFlags {
  final bool starts;
  final bool continues;
  final bool ends;

  const ActivityStatusFlags({
    required this.starts,
    required this.continues,
    required this.ends,
  });
}

ActivityStatusFlags statusFlagsForMonth(MonthRange range, int month) {
  validateMonth(month);
  final active = containsMonth(range, month);
  if (!active) {
    return const ActivityStatusFlags(
      starts: false,
      continues: false,
      ends: false,
    );
  }

  final prev = prevMonth(month);
  final next = nextMonth(month);

  final activePrev = containsMonth(range, prev);
  final activeNext = containsMonth(range, next);

  final starts = active && !activePrev;
  final continues = active && activePrev;
  final ends = active && !activeNext;

  return ActivityStatusFlags(starts: starts, continues: continues, ends: ends);
}
