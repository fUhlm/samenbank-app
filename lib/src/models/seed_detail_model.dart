import '../containers/seed_container.dart';
import 'month_range.dart';
import 'variety.dart';

class SeedDetailModel {
  final String id;
  final Variety variety;
  final SeedContainer? container;

  final int codeNumber;
  final int codeColorValue;

  final String gruppe;
  final String art;
  final String sorte;

  final String? lateinischerName;
  final String? familie;

  final String? eigenschaft;
  final String? freiland;
  final String? gruenduengung;
  final String? nachbauNotwendig;

  final String? keimtempC;
  final String? tiefeCm;

  final String? abstandReiheCm;
  final String? abstandPflanzeCm;
  final String? hoehePflanzeCm;

  final List<MonthRange> auspflanzenRanges;
  final List<MonthRange> blueteRanges;
  final List<MonthRange> ernteRanges;

  final bool varietyNameFromSpecies;

  const SeedDetailModel({
    required this.id,
    required this.variety,
    this.container,
    required this.codeNumber,
    required this.codeColorValue,
    required this.gruppe,
    required this.art,
    required this.sorte,
    this.lateinischerName,
    this.familie,
    this.eigenschaft,
    this.freiland,
    this.gruenduengung,
    this.nachbauNotwendig,
    this.keimtempC,
    this.tiefeCm,
    this.abstandReiheCm,
    this.abstandPflanzeCm,
    this.hoehePflanzeCm,
    this.auspflanzenRanges = const [],
    this.blueteRanges = const [],
    this.ernteRanges = const [],
    this.varietyNameFromSpecies = false,
  });
}
