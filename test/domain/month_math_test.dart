import 'package:test/test.dart';
import 'package:samenbank/samenbank_domain.dart';

void main() {
  group('Month (contract v1.1) – prev/next are cyclic and validate 1..12', () {
    test('prevMonth(1) = 12 (cyclic)', () {
      expect(Month.of(1).prev().value, 12);
    });

    test('nextMonth(12) = 1 (cyclic)', () {
      expect(Month.of(12).next().value, 1);
    });

    test('prev/next for inner months', () {
      expect(Month.of(2).prev().value, 1);
      expect(Month.of(2).next().value, 3);

      expect(Month.of(11).prev().value, 10);
      expect(Month.of(11).next().value, 12);
    });

    test('invalid months throw', () {
      expect(() => Month.of(0), throwsA(isA<InvalidMonthError>()));
      expect(() => Month.of(13), throwsA(isA<InvalidMonthError>()));
      expect(() => Month.of(-1), throwsA(isA<InvalidMonthError>()));
    });
  });
}
