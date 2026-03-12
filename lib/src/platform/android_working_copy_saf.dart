import 'package:flutter/services.dart';

import '../repositories/local_seed_repository.dart';

class AndroidWorkingCopySaf {
  AndroidWorkingCopySaf({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'samenbank/working_copy_saf';

  final MethodChannel _channel;

  Future<String?> pickJsonDocument() async {
    final uri = await _channel.invokeMethod<String>(
      'pickWorkingCopyJsonDocument',
    );
    if (uri == null) {
      return null;
    }
    final normalized = uri.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<String?> createJsonDocument({required String fileName}) async {
    final uri = await _channel.invokeMethod<String>(
      'createWorkingCopyJsonDocument',
      <String, dynamic>{'fileName': fileName},
    );
    if (uri == null) {
      return null;
    }
    final normalized = uri.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<bool> canReadUri(String uri) async {
    final readable = await _channel.invokeMethod<bool>(
      'canReadUri',
      <String, dynamic>{'uri': uri},
    );
    return readable ?? false;
  }

  Future<String> readUri(String uri) {
    return _channel
        .invokeMethod<String>('readUri', <String, dynamic>{'uri': uri})
        .then((value) {
          if (value == null) {
            throw const FormatException(
              'Leere Antwort beim Lesen der Arbeitsdatei.',
            );
          }
          return value;
        });
  }

  Future<void> writeUri(String uri, String json) async {
    await _channel.invokeMethod<void>('writeUri', <String, dynamic>{
      'uri': uri,
      'content': json,
    });
  }
}

class AndroidSafExternalWorkingCopyDataSource
    implements ExternalWorkingCopyDataSource {
  AndroidSafExternalWorkingCopyDataSource({AndroidWorkingCopySaf? saf})
    : _saf = saf ?? AndroidWorkingCopySaf();

  final AndroidWorkingCopySaf _saf;

  @override
  Future<bool> canRead(String uri) => _saf.canReadUri(uri);

  @override
  Future<String> read(String uri) => _saf.readUri(uri);

  @override
  Future<void> write(String uri, String json) => _saf.writeUri(uri, json);
}
