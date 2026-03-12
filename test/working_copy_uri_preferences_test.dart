import 'package:flutter_test/flutter_test.dart';
import 'package:samenbank/src/data/working_copy_uri_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkingCopyUriPreferences', () {
    test('persists and restores working copy URI', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = WorkingCopyUriPreferences();

      await preferences.saveUri('content://example/doc/123');

      final restored = await preferences.loadUri();
      expect(restored, 'content://example/doc/123');
    });

    test('clears stored URI', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        WorkingCopyUriPreferences.key: 'content://example/doc/456',
      });
      final preferences = WorkingCopyUriPreferences();

      await preferences.clearUri();

      final restored = await preferences.loadUri();
      expect(restored, isNull);
    });

    test('initial setup flag defaults to false', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = WorkingCopyUriPreferences();

      final done = await preferences.isInitialSetupDone();

      expect(done, isFalse);
    });

    test('marks initial setup as done', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = WorkingCopyUriPreferences();

      await preferences.markInitialSetupDone();

      final done = await preferences.isInitialSetupDone();
      expect(done, isTrue);
    });
  });
}
