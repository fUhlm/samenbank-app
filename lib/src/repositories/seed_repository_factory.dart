import 'package:flutter/foundation.dart';

import '../data/seed_json_loader.dart';
import '../data/working_copy_v1_initializer.dart';
import 'local_seed_repository.dart';
import 'seed_repository.dart';

class SeedRepositoryFactory {
  factory SeedRepositoryFactory({
    SeedJsonLoader? loader,
    WorkingCopyV1Initializer? initializer,
    ExternalWorkingCopyDataSource? externalWorkingCopyDataSource,
    String? externalWorkingCopyUri,
  }) {
    final resolvedLoader = loader ?? SeedJsonLoader();
    return SeedRepositoryFactory._(
      initializer:
          initializer ?? WorkingCopyV1Initializer(loader: resolvedLoader),
      externalWorkingCopyDataSource: externalWorkingCopyDataSource,
      externalWorkingCopyUri: externalWorkingCopyUri,
    );
  }

  SeedRepositoryFactory._({
    required WorkingCopyV1Initializer initializer,
    ExternalWorkingCopyDataSource? externalWorkingCopyDataSource,
    String? externalWorkingCopyUri,
  }) : _initializer = initializer,
       _externalWorkingCopyDataSource = externalWorkingCopyDataSource,
       _externalWorkingCopyUri = externalWorkingCopyUri;

  final WorkingCopyV1Initializer _initializer;
  final ExternalWorkingCopyDataSource? _externalWorkingCopyDataSource;
  final String? _externalWorkingCopyUri;

  Future<SeedRepository> build() async {
    final localRepository = LocalSeedRepository(
      initializer: _initializer,
      externalWorkingCopyDataSource: _externalWorkingCopyDataSource,
      externalWorkingCopyUri: _externalWorkingCopyUri,
    );

    try {
      await localRepository.init();
      return localRepository;
    } catch (error, stackTrace) {
      debugPrint(
        'SeedRepositoryFactory: Falling back to MockSeedRepository. Error: $error\n'
        'StackTrace: $stackTrace',
      );
      return MockSeedRepository();
    }
  }
}
