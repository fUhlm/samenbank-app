import 'tube_code.dart';

class SeedContainer {
  final String containerId;
  final String varietyRef; // varietyId
  final TubeCode tubeCode;

  const SeedContainer({
    required this.containerId,
    required this.varietyRef,
    required this.tubeCode,
  });
}
