import 'errors.dart';

class Month {
  final int value; // 1..12

  const Month._(this.value);

  factory Month.of(int month) {
    if (month < 1 || month > 12) throw InvalidMonthError(month);
    return Month._(month);
  }

  Month prev() => Month.of(((value + 10) % 12) + 1);
  Month next() => Month.of((value % 12) + 1);
}
