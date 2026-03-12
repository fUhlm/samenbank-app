import '../models/month_range.dart';
import 'month_math.dart';

bool containsMonth(MonthRange range, int month) {
  validateMonth(month);
  validateMonth(range.start);
  validateMonth(range.end);

  final start = range.start;
  final end = range.end;

  if (start <= end) {
    return start <= month && month <= end;
  } else {
    // wrap-around
    return month >= start || month <= end;
  }
}
