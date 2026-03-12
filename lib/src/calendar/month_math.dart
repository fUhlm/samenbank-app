import '../types/errors.dart';

void validateMonth(int month) {
  if (month < 1 || month > 12) throw InvalidMonthError(month);
}

/// prevMonth(m) = ((m + 10) mod 12) + 1
int prevMonth(int month) {
  validateMonth(month);
  return ((month + 10) % 12) + 1;
}

/// nextMonth(m) = (m mod 12) + 1
int nextMonth(int month) {
  validateMonth(month);
  return (month % 12) + 1;
}
