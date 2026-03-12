import 'enums.dart';

/// Contract 4.2 CategoryColorMap (normativ)
TubeColor tubeColorForCategory(Category c) {
  switch (c) {
    case Category.fruchtgemuese:
      return TubeColor.red;
    case Category.blattgemueseSalat:
      return TubeColor.green;
    case Category.kohlgewaechse:
      return TubeColor.blue;
    case Category.blumen:
      return TubeColor.yellow;
    default:
      return TubeColor.white;
  }
}
