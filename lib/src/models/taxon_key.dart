import '../types/enums.dart';

class TaxonKey {
  final Category category;
  final String species;
  final String varietyName;

  const TaxonKey({
    required this.category,
    required this.species,
    required this.varietyName,
  });

  @override
  bool operator ==(Object other) =>
      other is TaxonKey &&
      other.category == category &&
      other.species == species &&
      other.varietyName == varietyName;

  @override
  int get hashCode => Object.hash(category, species, varietyName);

  @override
  String toString() => 'TaxonKey($category, $species, $varietyName)';
}
