import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String seedJsonAssetPath = 'assets/seeds.json';

class SeedJsonLoader {
  Future<Map<String, dynamic>> load({String? assetPath}) async {
    final decoded = await loadDecoded(assetPath: assetPath);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw FormatException(
      'Seed JSON asset "${assetPath ?? seedJsonAssetPath}" must decode to a JSON object.',
    );
  }

  Future<dynamic> loadDecoded({String? assetPath}) async {
    final resolvedPath = assetPath ?? seedJsonAssetPath;
    final String rawJson;
    try {
      rawJson = await rootBundle.loadString(resolvedPath);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FlutterError(
          'Seed JSON asset could not be loaded. '
          'Check that "$resolvedPath" is listed in pubspec.yaml. '
          'Original error: $error',
        ),
        stackTrace,
      );
    }

    try {
      return jsonDecode(rawJson);
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FormatException(
          'Seed JSON asset "$resolvedPath" has invalid JSON. '
          'Cause: ${error.message}',
          error.source,
          error.offset,
        ),
        stackTrace,
      );
    }
  }
}
