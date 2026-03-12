import 'package:test/test.dart';
import 'package:samenbank/samenbank_domain.dart';

/// Contract-driven tests for:
/// - MonthRange inclusivity + wrap-around behavior (indirectly via RelevanceService)
/// - Status flags (starts / continues / ends) per month
///
/// Important:
/// - Uses ONLY the public domain API: package:samenbank/samenbank_domain.dart
/// - Does NOT import any internal calendar helpers from src/.
void main() {
  final relevance = RelevanceService();

  Variety varietyWithSingleWindow({
    required String varietyId,
    required String windowId,
    required MonthRange range,
    ActivityType type = ActivityType.directSow,
  }) {
    return Variety(
      varietyId: varietyId,
      taxonKey: const TaxonKey(
        category: Category.fruchtgemuese,
        species: 'Tomate',
        varietyName: 'Ruthje',
      ),

      activityWindows: [
        ActivityWindow(windowId: windowId, type: type, range: range),
      ],
    );
  }

  ActivityInMonth activityForMonth({
    required Variety variety,
    required int month,
    ActivityType type = ActivityType.directSow,
  }) {
    final res = relevance.evaluateVarietyForMonth(
      variety: variety,
      month: month,
      tubeCode: null,
    );
    return res.activities[type]!;
  }

  void expectFlags(
    ActivityInMonth a, {
    required bool starts,
    required bool continues,
    required bool ends,
    required List<String> activeWindowIds,
  }) {
    expect(a.starts, starts, reason: 'starts');
    expect(a.continues, continues, reason: 'continues');
    expect(a.ends, ends, reason: 'ends');
    expect(
      a.activeWindowIds,
      orderedEquals(activeWindowIds),
      reason: 'activeWindowIds',
    );
  }

  group('MonthRange behavior via RelevanceService (public API)', () {
    test('normal range is inclusive (3..5)', () {
      final v = varietyWithSingleWindow(
        varietyId: 'v1',
        windowId: 'w1',
        range: const MonthRange(start: 3, end: 5),
      );

      // outside before
      expectFlags(
        activityForMonth(variety: v, month: 2),
        starts: false,
        continues: false,
        ends: false,
        activeWindowIds: const [],
      );

      // start month
      expectFlags(
        activityForMonth(variety: v, month: 3),
        starts: true,
        continues: false,
        ends: false,
        activeWindowIds: const ['w1'],
      );

      // middle month
      expectFlags(
        activityForMonth(variety: v, month: 4),
        starts: false,
        continues: true,
        ends: false,
        activeWindowIds: const ['w1'],
      );

      // end month (continues + ends)
      expectFlags(
        activityForMonth(variety: v, month: 5),
        starts: false,
        continues: true,
        ends: true,
        activeWindowIds: const ['w1'],
      );

      // outside after
      expectFlags(
        activityForMonth(variety: v, month: 6),
        starts: false,
        continues: false,
        ends: false,
        activeWindowIds: const [],
      );
    });

    test('wrap-around range (11..2)', () {
      final v = varietyWithSingleWindow(
        varietyId: 'v2',
        windowId: 'wWrap',
        range: const MonthRange(start: 11, end: 2),
      );

      // outside before start
      expectFlags(
        activityForMonth(variety: v, month: 10),
        starts: false,
        continues: false,
        ends: false,
        activeWindowIds: const [],
      );

      // start at 11
      expectFlags(
        activityForMonth(variety: v, month: 11),
        starts: true,
        continues: false,
        ends: false,
        activeWindowIds: const ['wWrap'],
      );

      // 12 continues
      expectFlags(
        activityForMonth(variety: v, month: 12),
        starts: false,
        continues: true,
        ends: false,
        activeWindowIds: const ['wWrap'],
      );

      // 1 continues (prev=12 active, next=2 active)
      expectFlags(
        activityForMonth(variety: v, month: 1),
        starts: false,
        continues: true,
        ends: false,
        activeWindowIds: const ['wWrap'],
      );

      // 2 ends (next=3 inactive)
      expectFlags(
        activityForMonth(variety: v, month: 2),
        starts: false,
        continues: true,
        ends: true,
        activeWindowIds: const ['wWrap'],
      );

      // outside after end
      expectFlags(
        activityForMonth(variety: v, month: 3),
        starts: false,
        continues: false,
        ends: false,
        activeWindowIds: const [],
      );
    });
  });

  group('Status flags via RelevanceService (public API)', () {
    test('one-month window: starts and ends in same month (4..4)', () {
      final v = varietyWithSingleWindow(
        varietyId: 'v3',
        windowId: 'wOne',
        range: const MonthRange(start: 4, end: 4),
      );

      // inactive months around
      expectFlags(
        activityForMonth(variety: v, month: 3),
        starts: false,
        continues: false,
        ends: false,
        activeWindowIds: const [],
      );

      // active month (starts + ends)
      expectFlags(
        activityForMonth(variety: v, month: 4),
        starts: true,
        continues: false,
        ends: true,
        activeWindowIds: const ['wOne'],
      );

      // inactive after
      expectFlags(
        activityForMonth(variety: v, month: 5),
        starts: false,
        continues: false,
        ends: false,
        activeWindowIds: const [],
      );
    });
  });
}
