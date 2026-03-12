import 'dart:convert';

import 'package:flutter/material.dart';

import 'src/containers/seed_container.dart';
import 'src/containers/tube_code.dart';
import 'src/calendar/month_range_logic.dart';
import 'src/models/activity_window.dart';
import 'src/models/month_range.dart';
import 'src/models/seed_detail_model.dart';
import 'src/models/taxon_key.dart';
import 'src/models/variety.dart';
import 'src/repositories/local_seed_repository.dart';
import 'src/repositories/seed_repository.dart';
import 'src/types/category_color.dart';
import 'src/types/enums.dart';

enum SeedDetailMode { view, create }

class SeedDetailScreenV2 extends StatefulWidget {
  const SeedDetailScreenV2({
    super.key,
    required this.repository,
    required this.contextItems,
    required this.initialIndex,
    required this.month,
    this.mode = SeedDetailMode.view,
  }) : assert(contextItems.length > 0);

  final SeedRepository repository;
  final List<Seed> contextItems;
  final int initialIndex;
  final int month;
  final SeedDetailMode mode;

  static const Color appBackground = Color(0xFFF6F6F4);
  static const Color dividerColor = Color(0xFFE6E6E2);

  static Seed createDraftSeed() {
    final category = Category.unknown;
    final varietyId = _generateVarietyId(
      category: category,
      species: '',
      varietyName: '',
    );
    final tubeColor = tubeColorForCategory(category);
    return SeedDetailModel(
      id: varietyId,
      variety: Variety(
        varietyId: varietyId,
        taxonKey: TaxonKey(category: category, species: '', varietyName: ''),
        activityWindows: const <ActivityWindow>[],
      ),
      container: SeedContainer(
        containerId: 'C$varietyId',
        varietyRef: varietyId,
        tubeCode: TubeCode(color: tubeColor, number: 0),
      ),
      codeNumber: 0,
      codeColorValue: _colorValueForTubeColor(tubeColor),
      gruppe: _categoryLabel(category),
      art: '',
      sorte: '',
      varietyNameFromSpecies: false,
    );
  }

  @override
  State<SeedDetailScreenV2> createState() => _SeedDetailScreenV2State();
}

class _SeedDetailScreenV2State extends State<SeedDetailScreenV2> {
  late final PageController _pageController;
  late int _currentIndex;
  late List<Seed> _contextItems;
  final Map<int, bool> _pageEditingStates = <int, bool>{};
  late final List<String> _latinSuggestions;
  late final List<String> _familySuggestions;
  late final List<String> _speciesSuggestions;
  double _dragDistance = 0;

  static const double _swipeDistanceThreshold = 38;
  static const double _swipeVelocityThreshold = 180;

  @override
  void initState() {
    super.initState();
    _contextItems = List<Seed>.from(widget.contextItems);
    _currentIndex = widget.initialIndex.clamp(0, _contextItems.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    if (widget.mode == SeedDetailMode.create) {
      final seeds = widget.repository.getAllSeeds();
      _latinSuggestions = _buildDistinctSortedSuggestions(
        seeds.map((seed) => seed.lateinischerName),
      );
      _familySuggestions = _buildDistinctSortedSuggestions(
        seeds.map((seed) => seed.familie),
      );
      _speciesSuggestions = _buildDistinctSortedSuggestions(
        seeds.map((seed) => seed.variety.taxonKey.species),
      );
    } else {
      _latinSuggestions = const <String>[];
      _familySuggestions = const <String>[];
      _speciesSuggestions = const <String>[];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canGoBack => _currentIndex > 0;
  bool get _canGoForward => _currentIndex < _contextItems.length - 1;

  Future<void> _goToIndex(int index) async {
    if (index < 0 || index >= _contextItems.length) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_pageEditingStates[_currentIndex] == true) {
      _dragDistance = 0;
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final movedLeft = _dragDistance < 0;
    final movedRight = _dragDistance > 0;
    final passedDistance = _dragDistance.abs() >= _swipeDistanceThreshold;
    final passedVelocity = velocity.abs() >= _swipeVelocityThreshold;

    if ((passedDistance || passedVelocity) && movedLeft && _canGoForward) {
      _goToIndex(_currentIndex + 1);
    } else if ((passedDistance || passedVelocity) && movedRight && _canGoBack) {
      _goToIndex(_currentIndex - 1);
    }

    _dragDistance = 0;
  }

  void _onSeedUpdated(int index, Seed updatedSeed) {
    setState(() {
      _contextItems[index] = updatedSeed;
    });
  }

  void _setPageEditingState(int index, bool isEditing) {
    setState(() {
      _pageEditingStates[index] = isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeedDetailScreenV2.appBackground,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _contextItems.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final seed = _contextItems[index];
              return _DetailPage(
                seed: seed,
                month: widget.month,
                repository: widget.repository,
                mode: widget.mode,
                latinSuggestions: _latinSuggestions,
                familySuggestions: _familySuggestions,
                speciesSuggestions: _speciesSuggestions,
                onSeedUpdated: (updated) => _onSeedUpdated(index, updated),
                onEditingChanged: (isEditing) =>
                    _setPageEditingState(index, isEditing),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailPage extends StatefulWidget {
  const _DetailPage({
    required this.seed,
    required this.month,
    required this.repository,
    required this.mode,
    required this.latinSuggestions,
    required this.familySuggestions,
    required this.speciesSuggestions,
    required this.onSeedUpdated,
    required this.onEditingChanged,
  });

  final Seed seed;
  final int month;
  final SeedRepository repository;
  final SeedDetailMode mode;
  final List<String> latinSuggestions;
  final List<String> familySuggestions;
  final List<String> speciesSuggestions;
  final ValueChanged<Seed> onSeedUpdated;
  final ValueChanged<bool> onEditingChanged;

  @override
  State<_DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  late _SeedDraft _draft;
  bool _freilandToggleTouched = false;
  bool _gruenduengungToggleTouched = false;
  bool _rebuildToggleTouched = false;

  static ({String species, String variety}) _buildSpeciesVarietyParts({
    required String? species,
    required String? varietyName,
  }) {
    final normalizedSpecies = (species ?? '').trim();
    final normalizedVariety = (varietyName ?? '').trim();

    if (normalizedSpecies.isEmpty && normalizedVariety.isEmpty) {
      return (species: '', variety: 'Unbenannte Sorte');
    }
    if (normalizedSpecies.isEmpty) {
      return (
        species: '',
        variety: normalizedVariety.isEmpty
            ? 'Unbenannte Sorte'
            : normalizedVariety,
      );
    }
    if (normalizedVariety.isEmpty) {
      return (species: normalizedSpecies, variety: 'Unbenannte Sorte');
    }

    return (species: normalizedSpecies, variety: normalizedVariety);
  }

  static String _buildBotanikLine({
    required String? lateinischerName,
    required String? familie,
  }) {
    final ln = (lateinischerName ?? '').trim();
    final fam = (familie ?? '').trim();
    if (ln.isEmpty && fam.isEmpty) return '';
    if (ln.isEmpty) return fam;
    if (fam.isEmpty) return ln;
    return '$ln  •  $fam';
  }

  @override
  void initState() {
    super.initState();
    if (widget.mode == SeedDetailMode.create) {
      _beginCreateMode();
    }
  }

  @override
  void didUpdateWidget(covariant _DetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.seed.id != widget.seed.id) {
      _freilandToggleTouched = false;
      _gruenduengungToggleTouched = false;
      _rebuildToggleTouched = false;
    }
  }

  void _beginCreateMode() {
    _draft = _SeedDraft.fromSeed(widget.seed);
    _draft.tubeNumber = _tubeNumberOptionsForCategory(
      _draft.category,
      current: _draft.tubeNumber,
    ).first;
    _freilandToggleTouched = true;
    _gruenduengungToggleTouched = true;
    _rebuildToggleTouched = true;
    _isEditing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onEditingChanged(true);
      }
    });
  }

  void _enterEditMode() {
    setState(() {
      _draft = _SeedDraft.fromSeed(widget.seed);
      _freilandToggleTouched = false;
      _gruenduengungToggleTouched = false;
      _rebuildToggleTouched = false;
      _isEditing = true;
    });
    widget.onEditingChanged(true);
  }

  void _cancelEdit() {
    if (widget.mode == SeedDetailMode.create) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isEditing = false;
      _isSaving = false;
      _freilandToggleTouched = false;
      _gruenduengungToggleTouched = false;
      _rebuildToggleTouched = false;
    });
    widget.onEditingChanged(false);
  }

  String _createVarietyIdPreview() {
    final species = _normalizeNullableText(_draft.species) ?? '';
    final varietyName = _normalizeNullableText(_draft.varietyName) ?? '';
    return _generateVarietyId(
      category: _draft.category,
      species: species,
      varietyName: varietyName,
    );
  }

  List<int> _tubeNumberOptionsForCategory(Category category, {int? current}) {
    final tubeColor = tubeColorForCategory(category);
    final usedNumbers = <int>{};
    for (final seed in widget.repository.getAllSeeds()) {
      final tubeCode = seed.container?.tubeCode;
      if (tubeCode == null) continue;
      if (tubeCode.color == tubeColor && tubeCode.number > 0) {
        usedNumbers.add(tubeCode.number);
      }
    }

    const maxSuggestions = 100;
    final options = <int>[];
    var number = 1;
    while (options.length < maxSuggestions) {
      if (!usedNumbers.contains(number) || number == current) {
        options.add(number);
      }
      number++;
    }

    if (current != null && current > 0 && !options.contains(current)) {
      options.add(current);
      options.sort();
    }
    return options;
  }

  List<int> _tubeNumberOptionsForDraft() {
    return _tubeNumberOptionsForCategory(
      _draft.category,
      current: _draft.tubeNumber,
    );
  }

  Future<void> _openActionsSheet() async {
    if (_isEditing || _isDeleting) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Bearbeiten'),
                onTap: () {
                  Navigator.of(context).pop();
                  _enterEditMode();
                },
              ),
              ListTile(
                title: const Text('Löschen'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _confirmDelete();
                },
              ),
              ListTile(
                title: const Text('Schließen'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eintrag löschen?'),
          content: const Text(
            'Dieser Vorgang ist irreversibel. Soll der Eintrag wirklich gelöscht werden?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.repository.deleteSeed(widget.seed.variety.varietyId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      if (_isSyncConflict(error)) {
        await _showSyncConflictDialog();
        return;
      }
      _showMessage('Löschen fehlgeschlagen. Bitte erneut versuchen.');
    }
  }

  bool _isMonthRangeValid(MonthRange range) {
    return range.start >= 1 &&
        range.start <= 12 &&
        range.end >= 1 &&
        range.end <= 12;
  }

  List<MonthRange> _toConcreteRanges(List<_EditableMonthRange> entries) {
    final ranges = <MonthRange>[];
    for (final entry in entries) {
      if (entry.start == null && entry.end == null) continue;
      if (entry.start != null && entry.end != null) {
        ranges.add(MonthRange(start: entry.start!, end: entry.end!));
      }
    }
    return ranges;
  }

  String? _validateEditableRanges(
    String label,
    List<_EditableMonthRange> entries,
  ) {
    for (final entry in entries) {
      final start = entry.start;
      final end = entry.end;
      if ((start == null) != (end == null)) {
        return '$label: Bitte Start und Ende setzen oder beide auf "-" stellen.';
      }
      if (start != null && end != null) {
        final range = MonthRange(start: start, end: end);
        if (!_isMonthRangeValid(range)) {
          return 'Monatsbereiche müssen zwischen 1 und 12 liegen.';
        }
      }
    }
    return null;
  }

  List<ActivityWindow> _buildWindowsForType(
    ActivityType type,
    List<ActivityWindow> existing,
    List<MonthRange> ranges,
    String varietyIdForNewIds,
  ) {
    return [
      for (var i = 0; i < ranges.length; i++)
        ActivityWindow(
          windowId: i < existing.length
              ? existing[i].windowId
              : '$varietyIdForNewIds-${type.name}-${i + 1}',
          type: type,
          range: ranges[i],
        ),
    ];
  }

  String? _validateDraft() {
    return _validateEditableRanges('Voranzucht', _draft.preCultureRanges) ??
        _validateEditableRanges('Direktsaat', _draft.directSowRanges) ??
        _validateEditableRanges('Nachbau', _draft.seedSavingRanges) ??
        _validateEditableRanges('Auspflanzen', _draft.auspflanzenRanges) ??
        _validateEditableRanges('Blüte', _draft.blueteRanges) ??
        _validateEditableRanges('Ernte', _draft.ernteRanges);
  }

  Seed _buildUpdatedSeed() {
    final original = widget.seed;
    final category = _draft.category;
    final species = _normalizeNullableText(_draft.species) ?? '';
    final varietyName = _normalizeNullableText(_draft.varietyName) ?? '';
    final isCreateMode = widget.mode == SeedDetailMode.create;
    final varietyId = isCreateMode
        ? _generateVarietyId(
            category: category,
            species: species,
            varietyName: varietyName,
          )
        : original.variety.varietyId;

    final existingPre = original.variety.activityWindows
        .where((window) => window.type == ActivityType.preCulture)
        .toList(growable: false);
    final existingDirect = original.variety.activityWindows
        .where((window) => window.type == ActivityType.directSow)
        .toList(growable: false);
    final existingSeedSaving = original.variety.activityWindows
        .where((window) => window.type == ActivityType.seedSaving)
        .toList(growable: false);

    final preWindows = _buildWindowsForType(
      ActivityType.preCulture,
      existingPre,
      _toConcreteRanges(_draft.preCultureRanges),
      varietyId,
    );
    final directWindows = _buildWindowsForType(
      ActivityType.directSow,
      existingDirect,
      _toConcreteRanges(_draft.directSowRanges),
      varietyId,
    );
    final seedSavingWindows = _buildWindowsForType(
      ActivityType.seedSaving,
      existingSeedSaving,
      _toConcreteRanges(_draft.seedSavingRanges),
      varietyId,
    );

    final queueByType = <ActivityType, List<ActivityWindow>>{
      ActivityType.preCulture: List<ActivityWindow>.from(preWindows),
      ActivityType.directSow: List<ActivityWindow>.from(directWindows),
      ActivityType.seedSaving: List<ActivityWindow>.from(seedSavingWindows),
    };

    final updatedActivityWindows = <ActivityWindow>[];
    for (final window in original.variety.activityWindows) {
      final queue = queueByType[window.type]!;
      if (queue.isEmpty) continue;
      updatedActivityWindows.add(queue.removeAt(0));
    }
    for (final type in const [
      ActivityType.preCulture,
      ActivityType.directSow,
      ActivityType.seedSaving,
    ]) {
      updatedActivityWindows.addAll(queueByType[type]!);
    }

    final resolvedFreiland =
        widget.mode == SeedDetailMode.create || _freilandToggleTouched
        ? (_draft.freilandEnabled ? 'ja' : null)
        : original.freiland;
    final resolvedGruenduengung =
        widget.mode == SeedDetailMode.create || _gruenduengungToggleTouched
        ? (_draft.gruenduengungEnabled ? 'ja' : null)
        : original.gruenduengung;
    final resolvedNachbau =
        widget.mode == SeedDetailMode.create || _rebuildToggleTouched
        ? (_draft.rebuildRequired ? 'ja' : 'nein')
        : original.nachbauNotwendig;
    final tubeColor = tubeColorForCategory(category);
    final tubeNumber = _draft.tubeNumber ?? 0;

    return SeedDetailModel(
      id: isCreateMode ? varietyId : original.id,
      variety: Variety(
        varietyId: varietyId,
        taxonKey: isCreateMode
            ? TaxonKey(
                category: category,
                species: species,
                varietyName: varietyName,
              )
            : original.variety.taxonKey,
        activityWindows: updatedActivityWindows,
      ),
      container: isCreateMode
          ? SeedContainer(
              containerId: 'C$varietyId',
              varietyRef: varietyId,
              tubeCode: TubeCode(color: tubeColor, number: tubeNumber),
            )
          : original.container,
      codeNumber: isCreateMode ? tubeNumber : original.codeNumber,
      codeColorValue: isCreateMode
          ? _colorValueForTubeColor(tubeColor)
          : original.codeColorValue,
      gruppe: isCreateMode ? _categoryLabel(category) : original.gruppe,
      art: isCreateMode ? species : original.art,
      sorte: isCreateMode ? varietyName : original.sorte,
      lateinischerName: _normalizeNullableText(_draft.lateinischerName),
      familie: _normalizeNullableText(_draft.familie),
      eigenschaft: _normalizeNullableText(_draft.eigenschaft),
      freiland: resolvedFreiland,
      gruenduengung: resolvedGruenduengung,
      nachbauNotwendig: resolvedNachbau,
      keimtempC: _normalizeNullableText(_draft.keimtempC),
      tiefeCm: _normalizeNullableText(_draft.tiefeCm),
      abstandReiheCm: _normalizeNullableText(_draft.abstandReiheCm),
      abstandPflanzeCm: _normalizeNullableText(_draft.abstandPflanzeCm),
      hoehePflanzeCm: _normalizeNullableText(_draft.hoehePflanzeCm),
      auspflanzenRanges: _toConcreteRanges(_draft.auspflanzenRanges),
      blueteRanges: _toConcreteRanges(_draft.blueteRanges),
      ernteRanges: _toConcreteRanges(_draft.ernteRanges),
      varietyNameFromSpecies: original.varietyNameFromSpecies,
    );
  }

  String? _validateCreateConstraints(Seed updated) {
    if (updated.variety.taxonKey.species.trim().isEmpty) {
      return 'Art ist ein Pflichtfeld.';
    }
    if (updated.variety.taxonKey.varietyName.trim().isEmpty) {
      return 'Sorte ist ein Pflichtfeld.';
    }
    final tubeNumber = updated.container?.tubeCode.number ?? 0;
    if (tubeNumber < 1) {
      return 'Röhrchen-Nr. muss größer als 0 sein.';
    }
    return null;
  }

  String? _validateLockedConstraints(Seed updated) {
    final original = widget.seed;

    if (updated.variety.varietyId != original.variety.varietyId) {
      return 'varietyId darf nicht geändert werden.';
    }

    if (updated.variety.taxonKey.category !=
            original.variety.taxonKey.category ||
        updated.variety.taxonKey.species != original.variety.taxonKey.species ||
        updated.variety.taxonKey.varietyName !=
            original.variety.taxonKey.varietyName) {
      return 'taxonKey darf nicht geändert werden.';
    }

    final originalContainer = original.container;
    final updatedContainer = updated.container;
    if (originalContainer != null) {
      if (updatedContainer == null) {
        return 'Container darf nicht entfernt werden.';
      }
      if (updatedContainer.containerId != originalContainer.containerId ||
          updatedContainer.varietyRef != originalContainer.varietyRef ||
          updatedContainer.tubeCode.color != originalContainer.tubeCode.color ||
          updatedContainer.tubeCode.number !=
              originalContainer.tubeCode.number) {
        return 'Container-Identität darf nicht geändert werden.';
      }
      if (updatedContainer.varietyRef != updated.variety.varietyId) {
        return 'container.varietyRef muss varietyId entsprechen.';
      }
    }

    return null;
  }

  Future<void> _save() async {
    final draftError = _validateDraft();
    if (draftError != null) {
      _showMessage(draftError);
      return;
    }

    final updated = _buildUpdatedSeed();
    if (widget.mode != SeedDetailMode.create) {
      final lockError = _validateLockedConstraints(updated);
      if (lockError != null) {
        _showMessage(lockError);
        return;
      }
    } else {
      final createError = _validateCreateConstraints(updated);
      if (createError != null) {
        _showMessage(createError);
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.mode == SeedDetailMode.create) {
        await widget.repository.createSeed(updated);
      } else {
        await widget.repository.updateSeed(updated);
        widget.onSeedUpdated(updated);
      }
      if (!mounted) return;
      if (widget.mode == SeedDetailMode.create) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      widget.onEditingChanged(false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      if (_isSyncConflict(error)) {
        await _showSyncConflictDialog();
        return;
      }
      _showMessage(_buildSaveErrorMessage(error));
    }
  }

  bool _isSyncConflict(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains(
      'arbeitsdatei wurde auf einem anderen gerät geändert',
    );
  }

  Future<void> _showSyncConflictDialog() async {
    final shouldReload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Synchronisationskonflikt'),
        content: const Text(
          'Die Arbeitsdatei wurde auf einem anderen Gerät geändert. Möchtest du jetzt neu laden? Nicht gespeicherte Änderungen in dieser Ansicht gehen dabei verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Neu laden'),
          ),
        ],
      ),
    );

    if (shouldReload != true || !mounted) {
      return;
    }
    await _reloadWorkingCopyFromDialog();
  }

  Future<void> _reloadWorkingCopyFromDialog() async {
    final repository = widget.repository;
    if (repository is! LocalSeedRepository) {
      _showMessage('Neu laden ist auf diesem Gerät nicht verfügbar.');
      return;
    }

    try {
      await repository.reloadFromActiveWorkingCopy();
      if (!mounted) return;

      if (widget.mode != SeedDetailMode.create) {
        final freshSeed = repository.getSeedById(widget.seed.id);
        widget.onSeedUpdated(freshSeed);
        setState(() {
          _draft = _SeedDraft.fromSeed(freshSeed);
          _isEditing = false;
          _isSaving = false;
          _isDeleting = false;
        });
        widget.onEditingChanged(false);
      } else {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _isDeleting = false;
        });
        widget.onEditingChanged(false);
      }

      _showMessage('Arbeitsdatei neu geladen.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Neu laden fehlgeschlagen: $error');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _buildSaveErrorMessage(Object error) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (normalized.contains('duplicate') &&
        (normalized.contains('tube') || normalized.contains('tubecode'))) {
      return 'Speichern fehlgeschlagen: Röhrchen-Nr. ist in dieser Farbgruppe bereits vergeben. $raw';
    }
    if (normalized.contains('already exists') ||
        (normalized.contains('duplicate') &&
            (normalized.contains('varietyid') ||
                normalized.contains('variety_id')))) {
      return 'Speichern fehlgeschlagen: Samen-ID existiert bereits. $raw';
    }
    if (normalized.contains(
      'arbeitsdatei wurde auf einem anderen gerät geändert',
    )) {
      return 'Speichern fehlgeschlagen: Synchronisationskonflikt. Bitte unter Einstellungen > Erweitert die Arbeitsdatei neu laden und erneut speichern.';
    }
    if (normalized.contains('working copy') ||
        normalized.contains('seeds_app_v1')) {
      return 'Speichern fehlgeschlagen: Schreibfehler in der Working-Copy. $raw';
    }
    if (error is FormatException) {
      return 'Speichern fehlgeschlagen: Ungültige Eingaben. $raw';
    }
    return 'Speichern fehlgeschlagen: $raw';
  }

  @override
  Widget build(BuildContext context) {
    final currentSeed = widget.mode == SeedDetailMode.create && _isEditing
        ? _buildUpdatedSeed()
        : widget.seed;
    final speciesVarietyParts = _buildSpeciesVarietyParts(
      species: currentSeed.art,
      varietyName: currentSeed.sorte,
    );
    final botanikLine = _buildBotanikLine(
      lateinischerName: currentSeed.lateinischerName,
      familie: currentSeed.familie,
    );

    return Column(
      children: [
        _DetailHeader(
          species: speciesVarietyParts.species,
          variety: speciesVarietyParts.variety,
          subtitle: botanikLine,
          codeNumber: currentSeed.codeNumber,
          codeColor: Color(currentSeed.codeColorValue),
          onBadgeLongPress: widget.mode == SeedDetailMode.view
              ? _openActionsSheet
              : null,
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: SeedDetailScreenV2.dividerColor,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _isEditing || widget.mode == SeedDetailMode.create
                  ? _buildEditBody()
                  : _buildReadBody(),
            ),
          ),
        ),
        if (_isEditing) ...[
          const Divider(
            height: 1,
            thickness: 1,
            color: SeedDetailScreenV2.dividerColor,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _cancelEdit,
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: Text(
                      widget.mode == SeedDetailMode.create
                          ? 'Anlegen'
                          : 'Speichern',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeasonCalendarSection(
          activityWindows: widget.seed.variety.activityWindows,
          auspflanzenRanges: widget.seed.auspflanzenRanges,
          blueteRanges: widget.seed.blueteRanges,
          ernteRanges: widget.seed.ernteRanges,
          month: widget.month,
        ),
        const SizedBox(height: 16),
        const Divider(
          height: 1,
          thickness: 1,
          color: SeedDetailScreenV2.dividerColor,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Eigenschaften'),
        _KeyValueRow('Eigenschaft', widget.seed.eigenschaft),
        _KeyValueRow('Freiland', widget.seed.freiland),
        _KeyValueRow('Gründüngung', widget.seed.gruenduengung),
        _KeyValueRow('Nachbau notwendig?', widget.seed.nachbauNotwendig),
        const SizedBox(height: 16),
        const Divider(
          height: 1,
          thickness: 1,
          color: SeedDetailScreenV2.dividerColor,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Keimung & Aussaat'),
        _KeyValueRow('Keimtemperatur [°C]', widget.seed.keimtempC),
        _KeyValueRow('Saattiefe [cm]', widget.seed.tiefeCm),
        const SizedBox(height: 16),
        const Divider(
          height: 1,
          thickness: 1,
          color: SeedDetailScreenV2.dividerColor,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Abstände & Wuchs'),
        _KeyValueRow('Abstand Reihe [cm]', widget.seed.abstandReiheCm),
        _KeyValueRow('Abstand Pflanze [cm]', widget.seed.abstandPflanzeCm),
        _KeyValueRow('Höhe Pflanze [cm]', widget.seed.hoehePflanzeCm),
      ],
    );
  }

  Widget _buildEditBody() {
    final hasSeedSavingWindows = widget.seed.variety.activityWindows.any(
      (window) => window.type == ActivityType.seedSaving,
    );
    final editErnteFromDisplayWindows =
        widget.seed.ernteRanges.isNotEmpty || !hasSeedSavingWindows;
    final ernteSource = editErnteFromDisplayWindows
        ? _draft.ernteRanges
        : _draft.seedSavingRanges;
    final tubeNumberOptions = _tubeNumberOptionsForDraft();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.mode == SeedDetailMode.create) ...[
          const _SectionTitle('Identifikation'),
          _ReadOnlyValueRow(
            label: 'Samen-ID',
            value: _createVarietyIdPreview(),
          ),
          _EditableDropdownRow<Category>(
            label: 'Kategorie',
            value: _draft.category,
            items: Category.values,
            itemLabel: _categoryLabel,
            onChanged: (value) {
              setState(() {
                _draft.category = value;
                _draft.tubeNumber = _tubeNumberOptionsForCategory(
                  value,
                  current: _draft.tubeNumber,
                ).first;
              });
            },
          ),
          _EditableAutocompleteRow(
            key: const ValueKey<String>('draft-species-input'),
            label: 'Art',
            value: _draft.species,
            suggestions: widget.speciesSuggestions,
            onChanged: (value) => setState(() => _draft.species = value),
          ),
          _EditableTextRow(
            key: const ValueKey<String>('draft-variety-input'),
            label: 'Sorte',
            value: _draft.varietyName,
            onChanged: (value) => setState(() => _draft.varietyName = value),
          ),
          _EditableNumberDropdownRow(
            key: const ValueKey<String>('draft-tube-number-input'),
            label: 'Röhrchen-Nr.',
            value: _draft.tubeNumber,
            options: tubeNumberOptions,
            onChanged: (value) => setState(() => _draft.tubeNumber = value),
          ),
          _EditableAutocompleteRow(
            key: const ValueKey<String>('draft-latin-name-input'),
            label: 'Lateinischer Name',
            value: _draft.lateinischerName,
            suggestions: widget.latinSuggestions,
            onChanged: (value) =>
                setState(() => _draft.lateinischerName = value),
          ),
          _EditableAutocompleteRow(
            key: const ValueKey<String>('draft-family-input'),
            label: 'Familie',
            value: _draft.familie,
            suggestions: widget.familySuggestions,
            onChanged: (value) => setState(() => _draft.familie = value),
          ),
          const SizedBox(height: 16),
          const Divider(
            height: 1,
            thickness: 1,
            color: SeedDetailScreenV2.dividerColor,
          ),
          const SizedBox(height: 16),
        ],
        _SeasonCalendarEditSection(
          month: widget.month,
          preCultureRanges: _draft.preCultureRanges,
          directSowRanges: _draft.directSowRanges,
          auspflanzenRanges: _draft.auspflanzenRanges,
          blueteRanges: _draft.blueteRanges,
          ernteRanges: ernteSource,
          onPreCultureRangeChanged: (index, range) {
            setState(() {
              _draft.preCultureRanges[index] = range;
            });
          },
          onDirectSowRangeChanged: (index, range) {
            setState(() {
              _draft.directSowRanges[index] = range;
            });
          },
          onAuspflanzenRangeChanged: (index, range) {
            setState(() {
              _draft.auspflanzenRanges[index] = range;
            });
          },
          onBlueteRangeChanged: (index, range) {
            setState(() {
              _draft.blueteRanges[index] = range;
            });
          },
          onErnteRangeChanged: (index, range) {
            setState(() {
              if (editErnteFromDisplayWindows) {
                _draft.ernteRanges[index] = range;
              } else {
                _draft.seedSavingRanges[index] = range;
              }
            });
          },
          onPreCultureAddRange: () {
            setState(() {
              _draft.preCultureRanges.add(_EditableMonthRange.empty());
            });
          },
          onDirectSowAddRange: () {
            setState(() {
              _draft.directSowRanges.add(_EditableMonthRange.empty());
            });
          },
          onAuspflanzenAddRange: () {
            setState(() {
              _draft.auspflanzenRanges.add(_EditableMonthRange.empty());
            });
          },
          onBlueteAddRange: () {
            setState(() {
              _draft.blueteRanges.add(_EditableMonthRange.empty());
            });
          },
          onErnteAddRange: () {
            setState(() {
              if (editErnteFromDisplayWindows) {
                _draft.ernteRanges.add(_EditableMonthRange.empty());
              } else {
                _draft.seedSavingRanges.add(_EditableMonthRange.empty());
              }
            });
          },
        ),
        const SizedBox(height: 16),
        const Divider(
          height: 1,
          thickness: 1,
          color: SeedDetailScreenV2.dividerColor,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Eigenschaften'),
        _EditableTextRow(
          label: 'Eigenschaft',
          value: _draft.eigenschaft,
          onChanged: (value) => setState(() => _draft.eigenschaft = value),
        ),
        _SwitchRow(
          label: 'Freiland',
          value: _draft.freilandEnabled,
          onChanged: (value) {
            setState(() {
              _draft.freilandEnabled = value;
              _freilandToggleTouched = true;
            });
          },
        ),
        _SwitchRow(
          label: 'Gründüngung',
          value: _draft.gruenduengungEnabled,
          onChanged: (value) {
            setState(() {
              _draft.gruenduengungEnabled = value;
              _gruenduengungToggleTouched = true;
            });
          },
        ),
        _SwitchRow(
          label: 'Nachbau notwendig?',
          value: _draft.rebuildRequired,
          onChanged: (value) {
            setState(() {
              _draft.rebuildRequired = value;
              _rebuildToggleTouched = true;
            });
          },
        ),
        const SizedBox(height: 16),
        const Divider(
          height: 1,
          thickness: 1,
          color: SeedDetailScreenV2.dividerColor,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Keimung & Aussaat'),
        _EditableTextRow(
          label: 'Keimtemperatur [°C]',
          value: _draft.keimtempC,
          onChanged: (value) => setState(() => _draft.keimtempC = value),
        ),
        _EditableTextRow(
          label: 'Saattiefe [cm]',
          value: _draft.tiefeCm,
          onChanged: (value) => setState(() => _draft.tiefeCm = value),
        ),
        const SizedBox(height: 16),
        const Divider(
          height: 1,
          thickness: 1,
          color: SeedDetailScreenV2.dividerColor,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Abstände & Wuchs'),
        _EditableTextRow(
          label: 'Abstand Reihe [cm]',
          value: _draft.abstandReiheCm,
          onChanged: (value) => setState(() => _draft.abstandReiheCm = value),
        ),
        _EditableTextRow(
          label: 'Abstand Pflanze [cm]',
          value: _draft.abstandPflanzeCm,
          onChanged: (value) => setState(() => _draft.abstandPflanzeCm = value),
        ),
        _EditableTextRow(
          label: 'Höhe Pflanze [cm]',
          value: _draft.hoehePflanzeCm,
          onChanged: (value) => setState(() => _draft.hoehePflanzeCm = value),
        ),
        if (widget.mode != SeedDetailMode.create) ...[
          const SizedBox(height: 16),
          const Divider(
            height: 1,
            thickness: 1,
            color: SeedDetailScreenV2.dividerColor,
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Identifikation'),
          _EditableAutocompleteRow(
            key: const ValueKey<String>('draft-latin-name-input'),
            label: 'Lateinischer Name',
            value: _draft.lateinischerName,
            suggestions: widget.latinSuggestions,
            onChanged: (value) =>
                setState(() => _draft.lateinischerName = value),
          ),
          _EditableAutocompleteRow(
            key: const ValueKey<String>('draft-family-input'),
            label: 'Familie',
            value: _draft.familie,
            suggestions: widget.familySuggestions,
            onChanged: (value) => setState(() => _draft.familie = value),
          ),
        ],
      ],
    );
  }
}

String _generateVarietyId({
  required Category category,
  required String species,
  required String varietyName,
}) {
  final normalizedSpecies = species.trim();
  final normalizedVariety = varietyName.trim();
  final speciesSlug = _slugifyVarietyIdPart(normalizedSpecies);
  final varietySlug = _slugifyVarietyIdPart(normalizedVariety);
  final canonicalInput =
      '${_categoryLabel(category)}|$normalizedSpecies|$normalizedVariety';
  final hash6 = _sha1Hex(canonicalInput).substring(0, 6);
  return '$speciesSlug-$varietySlug-$hash6';
}

String _slugifyVarietyIdPart(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');
  final slug = normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'unbekannt' : slug;
}

String _sha1Hex(String input) {
  final bytes = utf8.encode(input);
  final messageLengthBits = bytes.length * 8;
  final padded = <int>[...bytes, 0x80];
  while ((padded.length % 64) != 56) {
    padded.add(0);
  }
  for (var shift = 56; shift >= 0; shift -= 8) {
    padded.add((messageLengthBits >> shift) & 0xff);
  }

  var h0 = 0x67452301;
  var h1 = 0xEFCDAB89;
  var h2 = 0x98BADCFE;
  var h3 = 0x10325476;
  var h4 = 0xC3D2E1F0;

  for (var chunkStart = 0; chunkStart < padded.length; chunkStart += 64) {
    final words = List<int>.filled(80, 0);
    for (var i = 0; i < 16; i++) {
      final index = chunkStart + (i * 4);
      words[i] =
          (padded[index] << 24) |
          (padded[index + 1] << 16) |
          (padded[index + 2] << 8) |
          padded[index + 3];
    }
    for (var i = 16; i < 80; i++) {
      words[i] = _rotl32(
        words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16],
        1,
      );
    }

    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;

    for (var i = 0; i < 80; i++) {
      late final int f;
      late final int k;
      if (i < 20) {
        f = (b & c) | ((~b) & d);
        k = 0x5A827999;
      } else if (i < 40) {
        f = b ^ c ^ d;
        k = 0x6ED9EBA1;
      } else if (i < 60) {
        f = (b & c) | (b & d) | (c & d);
        k = 0x8F1BBCDC;
      } else {
        f = b ^ c ^ d;
        k = 0xCA62C1D6;
      }
      final temp = (_rotl32(a, 5) + f + e + k + words[i]) & 0xFFFFFFFF;
      e = d;
      d = c;
      c = _rotl32(b, 30);
      b = a;
      a = temp;
    }

    h0 = (h0 + a) & 0xFFFFFFFF;
    h1 = (h1 + b) & 0xFFFFFFFF;
    h2 = (h2 + c) & 0xFFFFFFFF;
    h3 = (h3 + d) & 0xFFFFFFFF;
    h4 = (h4 + e) & 0xFFFFFFFF;
  }

  String toHex32(int value) => value.toRadixString(16).padLeft(8, '0');
  return '${toHex32(h0)}${toHex32(h1)}${toHex32(h2)}${toHex32(h3)}${toHex32(h4)}';
}

int _rotl32(int value, int shift) {
  final v = value & 0xFFFFFFFF;
  return ((v << shift) | (v >> (32 - shift))) & 0xFFFFFFFF;
}

List<String> _buildDistinctSortedSuggestions(Iterable<String?> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) continue;
    final key = normalized.toLowerCase();
    if (seen.add(key)) {
      result.add(normalized);
    }
  }
  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
}

String _categoryLabel(Category category) {
  switch (category) {
    case Category.fruchtgemuese:
      return 'Fruchtgemüse';
    case Category.kuerbisartige:
      return 'Kürbisartige';
    case Category.kohlgewaechse:
      return 'Kohlgewächse';
    case Category.blattgemueseSalat:
      return 'Blattgemüse/Salat';
    case Category.leguminosen:
      return 'Leguminosen';
    case Category.sonstigesGemuese:
      return 'Sonstiges Gemüse';
    case Category.kraeuter:
      return 'Kräuter';
    case Category.blumen:
      return 'Blumen';
    case Category.unknown:
      return 'Unbekannt';
  }
}

int _colorValueForTubeColor(TubeColor color) {
  switch (color) {
    case TubeColor.red:
      return 0xFFE53935;
    case TubeColor.green:
      return 0xFF43A047;
    case TubeColor.blue:
      return 0xFF1E88E5;
    case TubeColor.yellow:
      return 0xFFFDD835;
    case TubeColor.white:
      return 0xFFFFFFFF;
  }
}

String? _normalizeNullableText(String? value) {
  if (value == null) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

bool? _boolFromYesNo(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase();
  if (normalized == 'ja') return true;
  if (normalized == 'nein') return false;
  return null;
}

class _EditableMonthRange {
  const _EditableMonthRange({required this.start, required this.end});

  final int? start;
  final int? end;

  static _EditableMonthRange empty() {
    return const _EditableMonthRange(start: null, end: null);
  }
}

class _SeedDraft {
  _SeedDraft({
    required this.category,
    required this.species,
    required this.varietyName,
    required this.tubeNumber,
    required this.preCultureRanges,
    required this.directSowRanges,
    required this.seedSavingRanges,
    required this.auspflanzenRanges,
    required this.blueteRanges,
    required this.ernteRanges,
    required this.eigenschaft,
    required this.freilandEnabled,
    required this.gruenduengungEnabled,
    required this.rebuildRequired,
    required this.keimtempC,
    required this.tiefeCm,
    required this.abstandReiheCm,
    required this.abstandPflanzeCm,
    required this.hoehePflanzeCm,
    required this.lateinischerName,
    required this.familie,
  });

  Category category;
  String? species;
  String? varietyName;
  int? tubeNumber;

  final List<_EditableMonthRange> preCultureRanges;
  final List<_EditableMonthRange> directSowRanges;
  final List<_EditableMonthRange> seedSavingRanges;
  final List<_EditableMonthRange> auspflanzenRanges;
  final List<_EditableMonthRange> blueteRanges;
  final List<_EditableMonthRange> ernteRanges;

  String? eigenschaft;
  bool freilandEnabled;
  bool gruenduengungEnabled;
  bool rebuildRequired;
  String? keimtempC;
  String? tiefeCm;
  String? abstandReiheCm;
  String? abstandPflanzeCm;
  String? hoehePflanzeCm;
  String? lateinischerName;
  String? familie;

  static List<_EditableMonthRange> _entriesFromRanges(List<MonthRange> ranges) {
    if (ranges.isEmpty) {
      return <_EditableMonthRange>[_EditableMonthRange.empty()];
    }
    return ranges
        .map((range) => _EditableMonthRange(start: range.start, end: range.end))
        .toList(growable: true);
  }

  factory _SeedDraft.fromSeed(Seed seed) {
    return _SeedDraft(
      category: seed.variety.taxonKey.category,
      species: seed.variety.taxonKey.species,
      varietyName: seed.variety.taxonKey.varietyName,
      tubeNumber: seed.container?.tubeCode.number,
      preCultureRanges: _entriesFromRanges(
        seed.variety.activityWindows
            .where((window) => window.type == ActivityType.preCulture)
            .map((window) => window.range)
            .toList(growable: false),
      ),
      directSowRanges: _entriesFromRanges(
        seed.variety.activityWindows
            .where((window) => window.type == ActivityType.directSow)
            .map((window) => window.range)
            .toList(growable: false),
      ),
      seedSavingRanges: _entriesFromRanges(
        seed.variety.activityWindows
            .where((window) => window.type == ActivityType.seedSaving)
            .map((window) => window.range)
            .toList(growable: false),
      ),
      auspflanzenRanges: _entriesFromRanges(seed.auspflanzenRanges),
      blueteRanges: _entriesFromRanges(seed.blueteRanges),
      ernteRanges: _entriesFromRanges(seed.ernteRanges),
      eigenschaft: seed.eigenschaft,
      freilandEnabled: (seed.freiland ?? '').trim().toLowerCase() == 'ja',
      gruenduengungEnabled:
          (seed.gruenduengung ?? '').trim().toLowerCase() == 'ja',
      rebuildRequired: _boolFromYesNo(seed.nachbauNotwendig) ?? false,
      keimtempC: seed.keimtempC,
      tiefeCm: seed.tiefeCm,
      abstandReiheCm: seed.abstandReiheCm,
      abstandPflanzeCm: seed.abstandPflanzeCm,
      hoehePflanzeCm: seed.hoehePflanzeCm,
      lateinischerName: seed.lateinischerName,
      familie: seed.familie,
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.species,
    required this.variety,
    required this.subtitle,
    required this.codeNumber,
    required this.codeColor,
    required this.onBadgeLongPress,
  });

  final String species;
  final String variety;
  final String subtitle;
  final int codeNumber;
  final Color codeColor;
  final VoidCallback? onBadgeLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Zurück',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        letterSpacing: -0.2,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      children: [
                        if (species.isNotEmpty) TextSpan(text: species),
                        if (species.isNotEmpty) const TextSpan(text: ' • '),
                        TextSpan(
                          text: variety,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.topRight,
            child: _CodeCircle(
              number: codeNumber,
              color: codeColor,
              onLongPress: onBadgeLongPress,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonCalendarSection extends StatelessWidget {
  const _SeasonCalendarSection({
    required this.activityWindows,
    required this.auspflanzenRanges,
    required this.blueteRanges,
    required this.ernteRanges,
    required this.month,
  });

  final List<ActivityWindow> activityWindows;
  final List<MonthRange> auspflanzenRanges;
  final List<MonthRange> blueteRanges;
  final List<MonthRange> ernteRanges;
  final int month;

  static const List<int> _seasonMonths = <int>[2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  Widget build(BuildContext context) {
    final rows = <_SeasonRowSpec>[
      _SeasonRowSpec('Voranzucht', _rangesByType(ActivityType.preCulture)),
      _SeasonRowSpec('Direktsaat', _rangesByType(ActivityType.directSow)),
      _SeasonRowSpec('Auspflanzen', auspflanzenRanges),
      _SeasonRowSpec('Blüte', blueteRanges),
      _SeasonRowSpec(
        'Ernte',
        ernteRanges.isNotEmpty
            ? ernteRanges
            : _rangesByType(ActivityType.seedSaving),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Jahresübersicht'),
        const SizedBox(height: 4),
        _SeasonAxis(months: _seasonMonths),
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++) ...[
          _SeasonRow(
            label: rows[i].label,
            months: _seasonMonths,
            ranges: rows[i].ranges,
            selectedMonth: month,
          ),
          if (i != rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<MonthRange> _rangesByType(ActivityType type) {
    return activityWindows
        .where((window) => window.type == type)
        .map((window) => window.range)
        .toList(growable: false);
  }
}

class _SeasonCalendarEditSection extends StatelessWidget {
  const _SeasonCalendarEditSection({
    required this.month,
    required this.preCultureRanges,
    required this.directSowRanges,
    required this.auspflanzenRanges,
    required this.blueteRanges,
    required this.ernteRanges,
    required this.onPreCultureRangeChanged,
    required this.onDirectSowRangeChanged,
    required this.onAuspflanzenRangeChanged,
    required this.onBlueteRangeChanged,
    required this.onErnteRangeChanged,
    required this.onPreCultureAddRange,
    required this.onDirectSowAddRange,
    required this.onAuspflanzenAddRange,
    required this.onBlueteAddRange,
    required this.onErnteAddRange,
  });

  final int month;
  final List<_EditableMonthRange> preCultureRanges;
  final List<_EditableMonthRange> directSowRanges;
  final List<_EditableMonthRange> auspflanzenRanges;
  final List<_EditableMonthRange> blueteRanges;
  final List<_EditableMonthRange> ernteRanges;
  final void Function(int index, _EditableMonthRange range)
  onPreCultureRangeChanged;
  final void Function(int index, _EditableMonthRange range)
  onDirectSowRangeChanged;
  final void Function(int index, _EditableMonthRange range)
  onAuspflanzenRangeChanged;
  final void Function(int index, _EditableMonthRange range)
  onBlueteRangeChanged;
  final void Function(int index, _EditableMonthRange range) onErnteRangeChanged;
  final VoidCallback onPreCultureAddRange;
  final VoidCallback onDirectSowAddRange;
  final VoidCallback onAuspflanzenAddRange;
  final VoidCallback onBlueteAddRange;
  final VoidCallback onErnteAddRange;

  static const List<int> _seasonMonths = <int>[2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Jahresübersicht'),
        const SizedBox(height: 4),
        const _SeasonAxis(months: _seasonMonths),
        const SizedBox(height: 8),
        _SeasonEditableRow(
          label: 'Voranzucht',
          months: _seasonMonths,
          ranges: preCultureRanges,
          selectedMonth: month,
          onRangeChanged: onPreCultureRangeChanged,
          onAddRange: onPreCultureAddRange,
        ),
        const SizedBox(height: 8),
        _SeasonEditableRow(
          label: 'Direktsaat',
          months: _seasonMonths,
          ranges: directSowRanges,
          selectedMonth: month,
          onRangeChanged: onDirectSowRangeChanged,
          onAddRange: onDirectSowAddRange,
        ),
        const SizedBox(height: 8),
        _SeasonEditableRow(
          label: 'Auspflanzen',
          months: _seasonMonths,
          ranges: auspflanzenRanges,
          selectedMonth: month,
          onRangeChanged: onAuspflanzenRangeChanged,
          onAddRange: onAuspflanzenAddRange,
        ),
        const SizedBox(height: 8),
        _SeasonEditableRow(
          label: 'Blüte',
          months: _seasonMonths,
          ranges: blueteRanges,
          selectedMonth: month,
          onRangeChanged: onBlueteRangeChanged,
          onAddRange: onBlueteAddRange,
        ),
        const SizedBox(height: 8),
        _SeasonEditableRow(
          label: 'Ernte',
          months: _seasonMonths,
          ranges: ernteRanges,
          selectedMonth: month,
          onRangeChanged: onErnteRangeChanged,
          onAddRange: onErnteAddRange,
        ),
      ],
    );
  }
}

class _SeasonEditableRow extends StatelessWidget {
  const _SeasonEditableRow({
    required this.label,
    required this.months,
    required this.ranges,
    required this.selectedMonth,
    required this.onRangeChanged,
    required this.onAddRange,
  });

  final String label;
  final List<int> months;
  final List<_EditableMonthRange> ranges;
  final int selectedMonth;
  final void Function(int index, _EditableMonthRange range) onRangeChanged;
  final VoidCallback onAddRange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeasonRow(
          label: label,
          months: months,
          ranges: _concreteRanges(ranges),
          selectedMonth: selectedMonth,
        ),
        const SizedBox(height: 6),
        _MonthRangeEditorList(
          ranges: ranges,
          onRangeChanged: onRangeChanged,
          onAddRange: onAddRange,
        ),
      ],
    );
  }

  List<MonthRange> _concreteRanges(List<_EditableMonthRange> entries) {
    return [
      for (final entry in entries)
        if (entry.start != null && entry.end != null)
          MonthRange(start: entry.start!, end: entry.end!),
    ];
  }
}

class _MonthRangeEditorList extends StatelessWidget {
  const _MonthRangeEditorList({
    required this.ranges,
    required this.onRangeChanged,
    required this.onAddRange,
  });

  final List<_EditableMonthRange> ranges;
  final void Function(int index, _EditableMonthRange range) onRangeChanged;
  final VoidCallback onAddRange;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < ranges.length; i++)
          Padding(
            padding: EdgeInsets.only(
              left: 124,
              bottom: i == ranges.length - 1 ? 0 : 4,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ),
                _MonthDropdown(
                  value: ranges[i].start,
                  onChanged: (value) {
                    onRangeChanged(
                      i,
                      _EditableMonthRange(start: value, end: ranges[i].end),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  'bis',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(width: 6),
                _MonthDropdown(
                  value: ranges[i].end,
                  onChanged: (value) {
                    onRangeChanged(
                      i,
                      _EditableMonthRange(start: ranges[i].start, end: value),
                    );
                  },
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onAddRange,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  tooltip: 'Zeile hinzufügen',
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int?>(
      value: value,
      isDense: true,
      items: const [
        DropdownMenuItem<int?>(value: null, child: Text('-')),
        DropdownMenuItem(value: 1, child: Text('1')),
        DropdownMenuItem(value: 2, child: Text('2')),
        DropdownMenuItem(value: 3, child: Text('3')),
        DropdownMenuItem(value: 4, child: Text('4')),
        DropdownMenuItem(value: 5, child: Text('5')),
        DropdownMenuItem(value: 6, child: Text('6')),
        DropdownMenuItem(value: 7, child: Text('7')),
        DropdownMenuItem(value: 8, child: Text('8')),
        DropdownMenuItem(value: 9, child: Text('9')),
        DropdownMenuItem(value: 10, child: Text('10')),
        DropdownMenuItem(value: 11, child: Text('11')),
        DropdownMenuItem(value: 12, child: Text('12')),
      ],
      onChanged: onChanged,
    );
  }
}

class _SeasonRowSpec {
  const _SeasonRowSpec(this.label, this.ranges);

  final String label;
  final List<MonthRange> ranges;
}

class _SeasonAxis extends StatelessWidget {
  const _SeasonAxis({required this.months});

  final List<int> months;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 112),
        Expanded(
          child: Row(
            children: months
                .map(
                  (month) => Expanded(
                    child: Center(
                      child: Text(
                        _monthLabel(month),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  String _monthLabel(int month) {
    const labels = <int, String>{
      2: 'Feb',
      3: 'Mär',
      4: 'Apr',
      5: 'Mai',
      6: 'Jun',
      7: 'Jul',
      8: 'Aug',
      9: 'Sep',
      10: 'Okt',
    };
    return labels[month] ?? '';
  }
}

class _SeasonRow extends StatelessWidget {
  const _SeasonRow({
    required this.label,
    required this.months,
    required this.ranges,
    required this.selectedMonth,
  });

  final String label;
  final List<int> months;
  final List<MonthRange> ranges;
  final int selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Row(
                children: months
                    .map(
                      (month) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: _isActiveInMonth(month)
                                  ? const Color(0xFFDEE8D9)
                                  : const Color(0xFFF0F0ED),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              if (months.contains(selectedMonth))
                Positioned.fill(
                  child: Row(
                    children: [
                      for (final month in months)
                        Expanded(
                          child: month == selectedMonth
                              ? Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    color: Colors.black26,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isActiveInMonth(int month) {
    for (final range in ranges) {
      if (containsMonth(range, month)) return true;
    }
    return false;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.trim().isEmpty)
        ? '—'
        : value!.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              display,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableTextRow extends StatelessWidget {
  const _EditableTextRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyValueRow extends StatelessWidget {
  const _ReadOnlyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableDropdownRow<T> extends StatelessWidget {
  const _EditableDropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<T>(
              initialValue: value,
              isDense: true,
              isExpanded: true,
              items: [
                for (final item in items)
                  DropdownMenuItem(value: item, child: Text(itemLabel(item))),
              ],
              onChanged: (next) {
                if (next != null) {
                  onChanged(next);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableNumberDropdownRow extends StatelessWidget {
  const _EditableNumberDropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<int> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: value != null && options.contains(value)
                  ? value
                  : options.first,
              isDense: true,
              isExpanded: true,
              items: [
                for (final option in options)
                  DropdownMenuItem(value: option, child: Text('$option')),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableAutocompleteRow extends StatefulWidget {
  const _EditableAutocompleteRow({
    super.key,
    required this.label,
    required this.value,
    required this.suggestions,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  @override
  State<_EditableAutocompleteRow> createState() =>
      _EditableAutocompleteRowState();
}

class _EditableAutocompleteRowState extends State<_EditableAutocompleteRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _EditableAutocompleteRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value ?? '';
    if (nextValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              widget.label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RawAutocomplete<String>(
              textEditingController: _controller,
              focusNode: _focusNode,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) return const Iterable<String>.empty();
                return widget.suggestions.where(
                  (candidate) => candidate.toLowerCase().contains(query),
                );
              },
              onSelected: (selection) => widget.onChanged(selection),
              fieldViewBuilder:
                  (context, textEditingController, focusNode, onSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      onChanged: widget.onChanged,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                      ),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          for (final option in options)
                            ListTile(
                              dense: true,
                              title: Text(option),
                              onTap: () => onSelected(option),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CodeCircle extends StatelessWidget {
  const _CodeCircle({
    required this.number,
    required this.color,
    this.onLongPress,
  });

  final int number;
  final Color color;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isVeryLight = color.computeLuminance() > 0.80;
    final textColor = isVeryLight ? Colors.black87 : Colors.white;
    final border = isVeryLight
        ? Border.all(color: Colors.black26, width: 1)
        : null;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: border,
        ),
        child: Text(
          number.toString(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
