import '../types/enums.dart';

class TubeCode {
  final TubeColor color;
  final int number;

  const TubeCode({required this.color, required this.number});

  @override
  bool operator ==(Object other) =>
      other is TubeCode && other.color == color && other.number == number;

  @override
  int get hashCode => Object.hash(color, number);

  @override
  String toString() => 'TubeCode($color,$number)';
}
