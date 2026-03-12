import '../containers/seed_container.dart';
import '../containers/tube_code.dart';
import '../models/variety.dart';
//import '../types/enums.dart';
import '../types/errors.dart';
import '../types/category_color.dart';

class ValidationService {
  const ValidationService();

  /// Contract 3.1: Two Varieties with identical taxonKey are invalid.
  void validateVarieties(List<Variety> varieties) {
    final seen = <Object, String>{};
    for (final v in varieties) {
      final key = v.taxonKey;
      final existing = seen[key];
      if (existing != null) {
        throw DuplicateTaxonKeyError(
          'Duplicate taxonKey: $key (varietyIds: $existing, ${v.varietyId})',
        );
      }
      seen[key] = v.varietyId;
    }
  }

  /// Contract 3.2 / 3.3:
  /// - Two SeedContainers must not reference the same Variety.
  /// - (color,number) is unique.
  void validateContainers(List<SeedContainer> containers) {
    final byVariety = <String, String>{};
    final byTube = <TubeCode, String>{};

    for (final c in containers) {
      final existingVar = byVariety[c.varietyRef];
      if (existingVar != null) {
        throw InvalidContainerAssignmentError(
          'Duplicate container assignment for varietyRef=${c.varietyRef} (containerIds: $existingVar, ${c.containerId})',
        );
      }
      byVariety[c.varietyRef] = c.containerId;

      final existingTube = byTube[c.tubeCode];
      if (existingTube != null) {
        throw InvalidTubeCodeError(
          'Duplicate tubeCode=${c.tubeCode} (containerIds: $existingTube, ${c.containerId})',
        );
      }
      byTube[c.tubeCode] = c.containerId;
    }
  }

  /// Contract 4.2: tube color deterministically derived from category.
  /// If a container exists, its color must match the category color map.
  void validateContainerColors({
    required List<Variety> varieties,
    required List<SeedContainer> containers,
  }) {
    final varietyById = {for (final v in varieties) v.varietyId: v};
    for (final c in containers) {
      final v = varietyById[c.varietyRef];
      if (v == null) continue; // contract doesn't require referential check
      final expected = tubeColorForCategory(v.taxonKey.category);
      if (c.tubeCode.color != expected) {
        throw InvalidTubeCodeError(
          'Tube color mismatch for variety=${v.varietyId} category=${v.taxonKey.category}: expected $expected, got ${c.tubeCode.color}',
        );
      }
    }
  }
}

/// Contract 4.2 CategoryColorMap (normativ)
//TubeColor categoryColor(Category c) {
//switch (c) {
//case Category.fruchtgemuese:
//return TubeColor.red;
//case Category.blattgemueseSalat:
//return TubeColor.green;
//case Category.kohlgewaechse:
//return TubeColor.blue;
//case Category.blumen:
//return TubeColor.yellow;
//default:
//return TubeColor.white;
//}
//}
