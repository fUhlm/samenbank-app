import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samenbank/seed_detail_screen_v2.dart';
import 'package:samenbank/src/repositories/seed_repository.dart';

void main() {
  group('SeedDetailScreenV2 create mode', () {
    testWidgets('shows species/latin/family autocomplete suggestions', (
      tester,
    ) async {
      final repository = MockSeedRepository();
      final draft = SeedDetailScreenV2.createDraftSeed();

      await tester.pumpWidget(
        MaterialApp(
          home: SeedDetailScreenV2(
            repository: repository,
            contextItems: <Seed>[draft],
            initialIndex: 0,
            month: 4,
            mode: SeedDetailMode.create,
          ),
        ),
      );

      final speciesField = find.descendant(
        of: find.byKey(const ValueKey<String>('draft-species-input')),
        matching: find.byType(TextFormField),
      );
      final latinField = find.descendant(
        of: find.byKey(const ValueKey<String>('draft-latin-name-input')),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(speciesField, 'spi');
      await tester.pumpAndSettle();
      expect(find.text('Spinat'), findsWidgets);

      await tester.enterText(latinField, 'sol');
      await tester.pumpAndSettle();

      expect(find.text('Solanum lycopersicum'), findsWidgets);
    });

    testWidgets('cancel leaves create mode without adding a seed', (
      tester,
    ) async {
      final repository = MockSeedRepository();
      final initialCount = repository.getAllSeeds().length;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const ValueKey<String>('open-create-button'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SeedDetailScreenV2(
                            repository: repository,
                            contextItems: <Seed>[
                              SeedDetailScreenV2.createDraftSeed(),
                            ],
                            initialIndex: 0,
                            month: 4,
                            mode: SeedDetailMode.create,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('open-create-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Anlegen'), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('open-create-button')),
        findsOneWidget,
      );
      expect(repository.getAllSeeds().length, initialCount);
    });
  });
}
