import 'dart:convert';
import 'dart:io';

import 'package:samenbank/samenbank_domain.dart';

String loadTestData(String filename) {
  return File('test/domain/data/$filename').readAsStringSync();
}

List<Variety> loadVarieties() {
  final raw = jsonDecode(loadTestData('varieties.json')) as List<dynamic>;
  return raw.map((e) => varietyFromJson(e as Map<String, dynamic>)).toList();
}

List<SeedContainer> loadContainers() {
  final raw = jsonDecode(loadTestData('containers.json')) as List<dynamic>;
  return raw.map((e) => containerFromJson(e as Map<String, dynamic>)).toList();
}

Map<String, dynamic> loadInvalidDataset() {
  return jsonDecode(loadTestData('invalid_dataset.json'))
      as Map<String, dynamic>;
}

List<dynamic> loadExpectedCases() {
  return jsonDecode(loadTestData('expected.json')) as List<dynamic>;
}

Category categoryFromString(String s) {
  for (final c in Category.values) {
    if (c.name == s) return c;
  }
  return Category.unknown;
}

TubeColor tubeColorFromString(String s) {
  return TubeColor.values.firstWhere((e) => e.name == s);
}

ActivityType activityTypeFromString(String s) {
  return ActivityType.values.firstWhere((e) => e.name == s);
}

Variety varietyFromJson(Map<String, dynamic> j) {
  final tax = j['taxonKey'] as Map<String, dynamic>;
  final windows = (j['activityWindows'] as List<dynamic>)
      .map((w) => activityWindowFromJson(w as Map<String, dynamic>))
      .toList();

  return Variety(
    varietyId: j['varietyId'] as String,
    taxonKey: TaxonKey(
      category: categoryFromString(tax['category'] as String),
      species: tax['species'] as String,
      varietyName: tax['varietyName'] as String,
    ),
    activityWindows: windows,
  );
}

ActivityWindow activityWindowFromJson(Map<String, dynamic> j) {
  final range = j['range'] as Map<String, dynamic>;
  return ActivityWindow(
    windowId: j['windowId'] as String,
    type: activityTypeFromString(j['type'] as String),
    range: MonthRange(start: range['start'] as int, end: range['end'] as int),
  );
}

SeedContainer containerFromJson(Map<String, dynamic> j) {
  final tc = j['tubeCode'] as Map<String, dynamic>;
  return SeedContainer(
    containerId: j['containerId'] as String,
    varietyRef: j['varietyRef'] as String,
    tubeCode: TubeCode(
      color: tubeColorFromString(tc['color'] as String),
      number: tc['number'] as int,
    ),
  );
}
