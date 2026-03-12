import 'activity_window.dart';
import 'taxon_key.dart';

class Variety {
  final String varietyId;
  final TaxonKey taxonKey;
  final List<ActivityWindow> activityWindows;

  const Variety({
    required this.varietyId,
    required this.taxonKey,
    required this.activityWindows,
  });
}
