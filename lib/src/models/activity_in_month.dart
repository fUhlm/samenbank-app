import '../types/enums.dart';

class ActivityInMonth {
  final ActivityType type;
  final bool starts;
  final bool continues;
  final bool ends;
  final List<String> activeWindowIds;

  const ActivityInMonth({
    required this.type,
    required this.starts,
    required this.continues,
    required this.ends,
    required this.activeWindowIds,
  });
}
