import 'package:flutter/material.dart';

import 'seed_detail_screen_v2.dart';
import 'src/repositories/seed_repository.dart';
import 'src/types/enums.dart';
import 'src/ui/variety_list_helpers.dart';

class AllSeedsScreen extends StatefulWidget {
  const AllSeedsScreen({
    super.key,
    required this.repository,
    required this.month,
  });

  final SeedRepository repository;
  final int month;

  static const Color appBackground = Color(0xFFF6F6F4);
  static const Color dividerColor = Color(0xFFE6E6E2);
  static const Color itemBackground = Color(0xFFEDEDED);

  @override
  State<AllSeedsScreen> createState() => _AllSeedsScreenState();
}

class _AllSeedsScreenState extends State<AllSeedsScreen> {
  final TextEditingController _filterController = TextEditingController();
  String _filterText = '';
  bool _filterVisible = false;
  bool _rebuildFilterActive = false;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _clearFilter() {
    _filterController.clear();
    setState(() {
      _filterText = '';
    });
  }

  void _toggleFilterVisibility() {
    setState(() {
      _filterVisible = !_filterVisible;
    });
  }

  void _toggleRebuildFilter() {
    setState(() {
      _rebuildFilterActive = !_rebuildFilterActive;
    });
  }

  Future<void> _openCreateSeed() async {
    final draft = SeedDetailScreenV2.createDraftSeed();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeedDetailScreenV2(
          repository: widget.repository,
          contextItems: <Seed>[draft],
          initialIndex: 0,
          month: widget.month,
          mode: SeedDetailMode.create,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allSeeds = widget.repository.getAllSeeds();
    final seeds = _sortedSeeds(allSeeds);
    final filteredSeeds = _filteredSeeds(
      seeds,
      _filterText,
      rebuildFilterActive: _rebuildFilterActive,
    );
    final normalizedQuery = _filterText.trim().toLowerCase();
    final isTextFilterActive = normalizedQuery.isNotEmpty;
    final isNachbauFilterActive = _rebuildFilterActive == true;
    final isAnyFilterActive = isTextFilterActive || isNachbauFilterActive;
    final title = allSeeds.isNotEmpty ? '${allSeeds.length} Sorten' : 'Sorten';

    return Scaffold(
      backgroundColor: AllSeedsScreen.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 25),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: _toggleFilterVisibility,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 25),
                        icon: Icon(
                          _filterVisible
                              ? Icons.filter_list_off
                              : Icons.filter_list,
                        ),
                      ),
                      if (isAnyFilterActive)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: SizedBox(
                            width: 8,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: _openCreateSeed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 25),
                    icon: const Icon(Icons.add),
                    tooltip: 'Neu',
                  ),
                ],
              ),
            ),
            if (_filterVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AllSeedsScreen.dividerColor),
                      ),
                      child: TextField(
                        controller: _filterController,
                        onChanged: (value) {
                          setState(() {
                            _filterText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Filtern…',
                          border: InputBorder.none,
                          isDense: true,
                          suffixIcon: _filterText.trim().isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearFilter,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filteredSeeds.isEmpty
                  ? buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                      itemCount: filteredSeeds.length,
                      itemBuilder: (context, index) {
                        final seed = filteredSeeds[index];
                        final badgeColor = _badgeColorForCategory(
                          seed.variety.taxonKey.category,
                        );
                        final previousColor = index > 0
                            ? _badgeColorForCategory(
                                filteredSeeds[index - 1]
                                    .variety
                                    .taxonKey
                                    .category,
                              )
                            : null;
                        final addSpacing = previousColor != null
                            ? badgeColor != previousColor
                            : false;

                        return Column(
                          children: [
                            if (addSpacing) const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SeedDetailScreenV2(
                                      repository: widget.repository,
                                      contextItems: filteredSeeds,
                                      initialIndex: index,
                                      month: widget.month,
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                setState(() {});
                              },
                              child: _SeedListRow(
                                seed: seed,
                                badgeColor: badgeColor,
                                rebuildFilterActive: _rebuildFilterActive,
                                onRebuildChipTap: _toggleRebuildFilter,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeedListRow extends StatelessWidget {
  final Seed seed;
  final Color badgeColor;
  final bool rebuildFilterActive;
  final VoidCallback onRebuildChipTap;

  const _SeedListRow({
    required this.seed,
    required this.badgeColor,
    required this.rebuildFilterActive,
    required this.onRebuildChipTap,
  });

  @override
  Widget build(BuildContext context) {
    final showRebuildChip = _isRebuildRequired(seed.nachbauNotwendig);
    final varietyName = safeVarietyName(seed.variety.taxonKey.varietyName);
    final species = safeOptionalText(seed.variety.taxonKey.species);
    final titleParts = <TextSpan>[
      TextSpan(
        text: varietyName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ];
    if (species.isNotEmpty) {
      titleParts.addAll([const TextSpan(text: ' • '), TextSpan(text: species)]);
    }

    return Container(
      color: AllSeedsScreen.itemBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _CodeCircle(label: codeLabel(seed.codeNumber), color: badgeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: titleParts),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showRebuildChip) ...[
                  const SizedBox(height: 8),
                  _StatusBadge(
                    label: 'Nachbau notwendig',
                    isActive: rebuildFilterActive,
                    onTap: onRebuildChipTap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Seed> _sortedSeeds(List<Seed> seeds) {
  final indexed = seeds.indexed.toList(growable: false);
  final sorted = indexed.toList()
    ..sort((a, b) {
      final categoryOrder = _categorySortOrder(
        a.$2.variety.taxonKey.category,
      ).compareTo(_categorySortOrder(b.$2.variety.taxonKey.category));
      if (categoryOrder != 0) return categoryOrder;

      final aValid = _hasValidCodeNumber(a.$2.codeNumber);
      final bValid = _hasValidCodeNumber(b.$2.codeNumber);
      if (aValid != bValid) return aValid ? -1 : 1;

      if (aValid && bValid) {
        final numberOrder = a.$2.codeNumber.compareTo(b.$2.codeNumber);
        if (numberOrder != 0) return numberOrder;
      }

      return a.$1.compareTo(b.$1);
    });

  return sorted.map((entry) => entry.$2).toList(growable: false);
}

List<Seed> _filteredSeeds(
  List<Seed> seeds,
  String query, {
  required bool rebuildFilterActive,
}) {
  final parsedQuery = _parseSearchQuery(query);
  final normalizedQuery = parsedQuery.remainingQuery.trim().toLowerCase();
  final rebuildQueryRequested = _queryRequestsRebuild(normalizedQuery);

  return seeds
      .where((seed) {
        final varietyName = normalizedText(seed.variety.taxonKey.varietyName);
        final species = normalizedText(seed.variety.taxonKey.species);
        final category = _categoryLabel(seed.variety.taxonKey.category);
        final codeNumber = seed.codeNumber.toString();
        final rebuildRequired = _isRebuildRequired(seed.nachbauNotwendig);
        final matchesFreilandFilter =
            !parsedQuery.freilandRequired || hasFreilandFlag(seed.freiland);
        final matchesRebuildFilter = !rebuildFilterActive || rebuildRequired;
        final matchesTextFilter =
            normalizedQuery.isEmpty ||
            (rebuildQueryRequested && rebuildRequired) ||
            varietyName.contains(normalizedQuery) ||
            species.contains(normalizedQuery) ||
            category.contains(normalizedQuery) ||
            codeNumber.contains(normalizedQuery);

        return matchesFreilandFilter &&
            matchesRebuildFilter &&
            matchesTextFilter;
      })
      .toList(growable: false);
}

({bool freilandRequired, String remainingQuery}) _parseSearchQuery(
  String rawQuery,
) {
  final tokens = rawQuery.trim().split(RegExp(r'\s+'));
  final remainingTokens = <String>[];
  var freilandRequired = false;

  for (final token in tokens) {
    if (token.isEmpty) {
      continue;
    }

    final normalizedToken = token.toLowerCase();
    if (normalizedToken == 'freiland') {
      freilandRequired = true;
      continue;
    }

    if (normalizedToken.startsWith('freiland:')) {
      final value = normalizedToken.substring('freiland:'.length).trim();
      if (value.isEmpty ||
          value == 'ja' ||
          value == 'true' ||
          value == '1' ||
          value == 'x') {
        freilandRequired = true;
      } else if (value == '-' ||
          value == 'nein' ||
          value == 'false' ||
          value == '0') {
        freilandRequired = false;
      }
      continue;
    }

    remainingTokens.add(token);
  }

  return (
    freilandRequired: freilandRequired,
    remainingQuery: remainingTokens.join(' ').trim(),
  );
}

bool hasFreilandFlag(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  if (value.isEmpty) {
    return false;
  }
  if (value == '-' || value == 'nein') {
    return false;
  }
  return true;
}

bool _hasValidCodeNumber(int number) => number > 0;

bool _queryRequestsRebuild(String query) {
  const rebuildTerms = ['nachbau', 'nachbauen', 'nachbau notwendig'];
  return rebuildTerms.any(query.contains);
}

int _categorySortOrder(Category category) {
  switch (category) {
    case Category.fruchtgemuese:
      return 0;
    case Category.kohlgewaechse:
      return 1;
    case Category.blattgemueseSalat:
      return 2;
    case Category.leguminosen:
    case Category.sonstigesGemuese:
      return 3;
    case Category.blumen:
      return 4;
    case Category.kuerbisartige:
    case Category.kraeuter:
    case Category.unknown:
      return 3;
  }
}

String _categoryLabel(Category category) {
  switch (category) {
    case Category.fruchtgemuese:
      return 'fruchtgemuese';
    case Category.kuerbisartige:
      return 'kuerbisartige';
    case Category.kohlgewaechse:
      return 'kohlgewaechse';
    case Category.blattgemueseSalat:
      return 'blattgemuese salat';
    case Category.leguminosen:
      return 'leguminosen';
    case Category.sonstigesGemuese:
      return 'sonstiges gemuese';
    case Category.kraeuter:
      return 'kraeuter';
    case Category.blumen:
      return 'blumen';
    case Category.unknown:
      return 'unknown';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _StatusBadge({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive ? Colors.black26 : Colors.black12;
    final borderColor = isActive ? Colors.black38 : Colors.black12;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    if (onTap == null) {
      return badge;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: badge,
      ),
    );
  }
}

class _CodeCircle extends StatelessWidget {
  final String label;
  final Color color;

  const _CodeCircle({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isLight = color.computeLuminance() > 0.8;

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: isLight ? Border.all(color: Colors.black26) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isLight ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}

bool _isRebuildRequired(String? value) {
  if (value == null) return false;
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized == '—') return false;
  const positive = {'yes', 'ja', 'true', 'positiv'};
  return positive.contains(normalized);
}

Color _badgeColorForCategory(Category category) {
  switch (category) {
    case Category.fruchtgemuese:
      return const Color(0xFFE53935);
    case Category.kohlgewaechse:
      return const Color(0xFF1E88E5);
    case Category.blattgemueseSalat:
      return const Color(0xFF43A047);
    case Category.leguminosen:
    case Category.sonstigesGemuese:
      return const Color(0xFFFFFFFF);
    case Category.blumen:
      return const Color(0xFFFDD835);
    case Category.kuerbisartige:
    case Category.kraeuter:
    case Category.unknown:
      return const Color(0xFFFFFFFF);
  }
}
