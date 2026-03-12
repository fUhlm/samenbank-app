import '../types/enums.dart';
import 'month_range.dart';

class ActivityWindow {
  final String windowId;
  final ActivityType type;
  final MonthRange range;

  const ActivityWindow({
    required this.windowId,
    required this.type,
    required this.range,
  });
}
