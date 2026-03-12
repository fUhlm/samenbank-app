import 'package:flutter/material.dart';
import 'all_seeds_screen.dart';
import 'settings_screen.dart';
import 'seed_detail_screen_v2.dart';
import 'src/controllers/month_overview_controller.dart';
import 'src/data/working_copy_v1_initializer.dart';
import 'src/data/working_copy_uri_preferences.dart';
import 'src/models/activity_in_month.dart';
import 'src/models/relevance_result.dart';
import 'src/platform/android_working_copy_saf.dart';
import 'src/repositories/local_seed_repository.dart';
import 'src/repositories/seed_repository.dart';
import 'src/repositories/seed_repository_factory.dart';
import 'src/types/enums.dart';
import 'src/ui/variety_list_helpers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final uriPreferences = WorkingCopyUriPreferences();
  final storedUri = await uriPreferences.loadUri();
  final repository = await SeedRepositoryFactory(
    externalWorkingCopyDataSource: AndroidSafExternalWorkingCopyDataSource(),
    externalWorkingCopyUri: storedUri,
  ).build();
  String? startupWarning;
  if (repository is LocalSeedRepository) {
    startupWarning = repository.consumeInitWarning();
    if (startupWarning != null) {
      await uriPreferences.clearUri();
    }
  }
  final controller = MonthOverviewController(repository: repository);
  runApp(
    SamenbankApp(
      repository: repository,
      controller: controller,
      uriPreferences: uriPreferences,
      saf: AndroidWorkingCopySaf(),
      startupWarning: startupWarning,
    ),
  );
}

class SamenbankApp extends StatelessWidget {
  const SamenbankApp({
    super.key,
    required this.repository,
    required this.controller,
    required this.uriPreferences,
    required this.saf,
    this.startupWarning,
  });

  final SeedRepository repository;
  final MonthOverviewController controller;
  final WorkingCopyUriPreferences uriPreferences;
  final AndroidWorkingCopySaf saf;
  final String? startupWarning;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MonthHomeScreen(
        controller: controller,
        repository: repository,
        uriPreferences: uriPreferences,
        saf: saf,
        startupWarning: startupWarning,
      ),
    );
  }
}

// ============================================================================
// Monatsansicht
// ============================================================================

class MonthHomeScreen extends StatefulWidget {
  const MonthHomeScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.uriPreferences,
    required this.saf,
    this.startupWarning,
  });

  final MonthOverviewController controller;
  final SeedRepository repository;
  final WorkingCopyUriPreferences uriPreferences;
  final AndroidWorkingCopySaf saf;
  final String? startupWarning;

  static const Color appBackground = Color(0xFFF6F6F4);
  static const Color dividerColor = Color(0xFFE6E6E2);

  static const Color statusActive = Color(0xFFE7F0FA);
  static const Color statusPassive = Color(0xFFEDEDED);
  static const Color statusWarning = Color(0xFFFFF6E3);

  @override
  State<MonthHomeScreen> createState() => _MonthHomeScreenState();
}

class _MonthHomeScreenState extends State<MonthHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _startupWarningShown = false;
  bool _initialSetupChecked = false;
  bool _initialSetupDialogOpen = false;
  double _dragDistance = 0;

  static const double _swipeDistanceThreshold = 38;
  static const double _swipeVelocityThreshold = 180;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final warning = widget.startupWarning;
    if (!_startupWarningShown && warning != null && warning.isNotEmpty) {
      _startupWarningShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(warning)));
      });
    }
    _maybeRunInitialSetup();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTopAfterSetState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  void _goToPreviousMonth() {
    setState(widget.controller.previousMonth);
    _scrollToTopAfterSetState();
  }

  void _goToNextMonth() {
    setState(widget.controller.nextMonth);
    _scrollToTopAfterSetState();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final movedLeft = _dragDistance < 0;
    final movedRight = _dragDistance > 0;
    final passedDistance = _dragDistance.abs() >= _swipeDistanceThreshold;
    final passedVelocity = velocity.abs() >= _swipeVelocityThreshold;

    if ((passedDistance || passedVelocity) && movedLeft) {
      _goToNextMonth();
    } else if ((passedDistance || passedVelocity) && movedRight) {
      _goToPreviousMonth();
    }

    _dragDistance = 0;
  }

  Future<void> _openAllSeeds() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllSeedsScreen(
          repository: widget.repository,
          month: widget.controller.selectedMonth,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          repository: widget.repository,
          uriPreferences: widget.uriPreferences,
          saf: widget.saf,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _maybeRunInitialSetup() async {
    if (_initialSetupChecked) {
      return;
    }
    _initialSetupChecked = true;

    final done = await widget.uriPreferences.isInitialSetupDone();
    if (!mounted || done) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showInitialSetupDialog();
    });
  }

  Future<void> _showInitialSetupDialog() async {
    if (_initialSetupDialogOpen) {
      return;
    }
    _initialSetupDialogOpen = true;

    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arbeitsdatei festlegen'),
        content: const Text(
          'Beim ersten Start: Gibt es bereits eine Arbeitsdatei oder soll eine neue im gewünschten Ordner angelegt werden (z. B. Nextcloud)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('later'),
            child: const Text('Später'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop('existing'),
            child: const Text('Datei existiert'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('create'),
            child: const Text('Neue Datei anlegen'),
          ),
        ],
      ),
    );

    if (selected == 'existing') {
      await _chooseExistingWorkingCopyFromMain();
    } else if (selected == 'create') {
      await _createAndUseWorkingCopyFromMain();
    }

    await widget.uriPreferences.markInitialSetupDone();
    _initialSetupDialogOpen = false;
  }

  Future<void> _chooseExistingWorkingCopyFromMain() async {
    if (widget.repository is! LocalSeedRepository) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arbeitsdatei-Auswahl ist nicht verfügbar.'),
        ),
      );
      return;
    }

    final repository = widget.repository as LocalSeedRepository;

    try {
      final uri = await widget.saf.pickJsonDocument();
      if (uri == null) {
        return;
      }

      await repository.setExternalWorkingCopyUri(uri);
      await widget.uriPreferences.saveUri(uri);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Arbeitsdatei gesetzt')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arbeitsdatei ungültig oder nicht lesbar: $error'),
        ),
      );
    }
  }

  Future<void> _createAndUseWorkingCopyFromMain() async {
    if (widget.repository is! LocalSeedRepository) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arbeitsdatei-Auswahl ist nicht verfügbar.'),
        ),
      );
      return;
    }

    final repository = widget.repository as LocalSeedRepository;

    try {
      final initialPayload = await widget.repository.exportWorkingCopyJson();
      final uri = await widget.saf.createJsonDocument(
        fileName: appFormatV1FileName,
      );
      if (uri == null) {
        return;
      }

      await widget.saf.writeUri(uri, initialPayload);
      await repository.setExternalWorkingCopyUri(uri);
      await widget.uriPreferences.saveUri(uri);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neue Arbeitsdatei erstellt und gesetzt')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anlegen der Arbeitsdatei fehlgeschlagen: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewItems = widget.controller.buildOverview();

    // rein visuelle Gruppierung
    final newItems = <dynamic>[];
    final ongoingItems = <dynamic>[];
    final endingItems = <dynamic>[];

    for (final item in overviewItems) {
      switch (item.relevance.phase) {
        case RelevancePhase.newPhase:
          newItems.add(item);
          break;
        case RelevancePhase.ongoing:
          ongoingItems.add(item);
          break;
        case RelevancePhase.ending:
          endingItems.add(item);
          break;
        case RelevancePhase.none:
          break;
      }
    }

    final entries = <_MonthListEntry>[];

    void addSection(String title, List<dynamic> items) {
      if (items.isEmpty) return;
      entries.add(_MonthListEntry.header(title));
      for (final it in items) {
        entries.add(_MonthListEntry.item(it));
      }
    }

    addSection('Startet diesen Monat', newItems);
    addSection('Läuft diesen Monat', ongoingItems);
    addSection('Endet diesen Monat', endingItems);

    final contextSeeds = <Seed>[
      ...newItems.map((item) => item.seed as Seed),
      ...ongoingItems.map((item) => item.seed as Seed),
      ...endingItems.map((item) => item.seed as Seed),
    ];

    return Scaffold(
      backgroundColor: MonthHomeScreen.appBackground,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          _monthLabel(widget.controller.selectedMonth),
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: _openSettings,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 25),
                            iconSize: 18,
                            splashRadius: 18,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.settings_outlined),
                            tooltip: 'Einstellungen',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: _openAllSeeds,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 25),
                            iconSize: 18,
                            splashRadius: 18,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.list),
                            tooltip: 'Alle Sorten',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    SizedBox(
                      height: 26,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _goToPreviousMonth,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 22,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: _goToNextMonth,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 22,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: entries.isEmpty
                    ? buildEmptyState(context)
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];

                          Widget child;
                          if (entry.isHeader) {
                            child = Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Text(
                                entry.headerTitle!,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            );
                          } else {
                            final item = entry.item;
                            child = InkWell(
                              onTap: () async {
                                final initialIndex = contextSeeds.indexWhere(
                                  (seed) => seed.id == item.seed.id,
                                );
                                if (initialIndex < 0) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SeedDetailScreenV2(
                                      repository: widget.repository,
                                      contextItems: contextSeeds,
                                      initialIndex: initialIndex,
                                      month: widget.controller.selectedMonth,
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                setState(() {});
                              },
                              child: _SeedListRow(
                                seed: item.seed,
                                relevance: item.relevance,
                              ),
                            );
                          }

                          return Column(
                            children: [
                              child,
                              if (index != entries.length - 1)
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: MonthHomeScreen.dividerColor,
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Listeneintrag
// ============================================================================

class _SeedListRow extends StatelessWidget {
  final Seed seed;
  final RelevanceResult relevance;

  const _SeedListRow({required this.seed, required this.relevance});

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundForPhase(relevance.phase);

    final showPre = _isActive(relevance.activities[ActivityType.preCulture]);
    final showDirect = _isActive(relevance.activities[ActivityType.directSow]);
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
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _CodeCircle(
            label: codeLabel(seed.codeNumber),
            color: Color(seed.codeColorValue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identitätszeile
                Text.rich(
                  TextSpan(children: titleParts),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _ActionBadges(showPreGrow: showPre, showDirectSow: showDirect),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(ActivityInMonth? a) =>
      a != null && (a.starts || a.continues || a.ends);

  Color _backgroundForPhase(RelevancePhase phase) {
    switch (phase) {
      case RelevancePhase.newPhase:
        return MonthHomeScreen.statusActive;
      case RelevancePhase.ongoing:
        return MonthHomeScreen.statusPassive;
      case RelevancePhase.ending:
        return MonthHomeScreen.statusWarning;
      case RelevancePhase.none:
        return MonthHomeScreen.statusPassive;
    }
  }
}

// ============================================================================
// UI-Hilfswidgets
// ============================================================================

class _MonthListEntry {
  final String? headerTitle;
  final dynamic item;

  const _MonthListEntry._({this.headerTitle, this.item});

  factory _MonthListEntry.header(String title) =>
      _MonthListEntry._(headerTitle: title);

  factory _MonthListEntry.item(dynamic item) => _MonthListEntry._(item: item);

  bool get isHeader => headerTitle != null;
}

class _ActionBadges extends StatelessWidget {
  final bool showPreGrow;
  final bool showDirectSow;

  const _ActionBadges({required this.showPreGrow, required this.showDirectSow});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    if (showPreGrow) {
      widgets.add(const _ActionBadge(label: 'Voranzucht'));
    }
    if (showDirectSow) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(width: 8));
      widgets.add(const _ActionBadge(label: 'Direktsaat'));
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Row(children: widgets);
  }
}

class _ActionBadge extends StatelessWidget {
  final String label;

  const _ActionBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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

String _monthLabel(int month) {
  const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return (month >= 1 && month <= 12) ? months[month - 1] : '';
}
