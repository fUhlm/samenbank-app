import 'package:flutter/material.dart';
import 'src/models/activity_in_month.dart';
import 'src/models/activity_window.dart';
import 'src/models/month_range.dart';
import 'src/models/relevance_result.dart';
import 'src/repositories/seed_repository.dart';
import 'src/services/relevance_service.dart';
import 'src/types/enums.dart';

// ============================================================================
// Seed Detail Screen (read-only)
// Änderungen gemäß B:
// - Nachbarschaft entfernt
// - Botanik (lat. Name + Familie) als kleine kursive Zeile unter Sortenname
//
// AP3 Fixes:
// 1) Aussaat-Block IMMER sichtbar (auch wenn keine Domain-Aktivität vorhanden)
// 2) Voranzucht-Block IMMER sichtbar (auch wenn keine Domain-Aktivität vorhanden)
// 3) Kalender-Darstellung im gleichen Layout-Stil wie bestehende Details (_KeyValueRow)
// ============================================================================

class SeedDetailScreen extends StatelessWidget {
  const SeedDetailScreen({
    super.key,
    required this.repository,
    required this.seedId,
    required this.month,
  });

  final SeedRepository repository;
  final String seedId;
  final int month;

  static const Color appBackground = Color(0xFFF6F6F4);
  static const Color dividerColor = Color(0xFFE6E6E2);

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
  Widget build(BuildContext context) {
    final seed = repository.getSeedById(seedId);
    final botanikLine = _buildBotanikLine(
      lateinischerName: seed.lateinischerName,
      familie: seed.familie,
    );
    final relevance = const RelevanceService().evaluateVarietyForMonth(
      variety: seed.variety,
      month: month,
      tubeCode: seed.container?.tubeCode,
    );

    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              title: seed.sorte,
              subtitle: botanikLine,
              codeNumber: seed.codeNumber,
              codeColor: Color(seed.codeColorValue),
            ),
            const Divider(height: 1, thickness: 1, color: dividerColor),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Identifikation'),
                      _IdentityRow(
                        codeNumber: seed.codeNumber,
                        codeColor: Color(seed.codeColorValue),
                        subtitle: '${seed.gruppe} · ${seed.art}',
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                      const SizedBox(height: 16),

                      _CalendarSection(
                        relevance: relevance,
                        activityWindows: seed.variety.activityWindows,
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                      const SizedBox(height: 16),

                      _SectionTitle('Eigenschaften'),
                      _KeyValueRow('Eigenschaft', seed.eigenschaft),
                      _KeyValueRow('Freiland', seed.freiland),
                      _KeyValueRow('Gründüngung', seed.gruenduengung),
                      _KeyValueRow('Nachbau notwendig?', seed.nachbauNotwendig),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                      const SizedBox(height: 16),

                      _SectionTitle('Keimung & Aussaat'),
                      _KeyValueRow('Keimtemperatur [°C]', seed.keimtempC),
                      _KeyValueRow('Saattiefe [cm]', seed.tiefeCm),
                      const SizedBox(height: 12),
                      const _SubtleHint(
                        'Hinweis: Werte kommen aus deiner Excel. Später füllen wir das 1:1 aus der DB.',
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                      const SizedBox(height: 16),

                      _SectionTitle('Abstände & Wuchs'),
                      _KeyValueRow('Abstand Reihe [cm]', seed.abstandReiheCm),
                      _KeyValueRow(
                        'Abstand Pflanze [cm]',
                        seed.abstandPflanzeCm,
                      ),
                      _KeyValueRow('Höhe Pflanze [cm]', seed.hoehePflanzeCm),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.subtitle,
    required this.codeNumber,
    required this.codeColor,
  });

  final String title;
  final String subtitle;
  final int codeNumber;
  final Color codeColor;

  @override
  Widget build(BuildContext context) {
    const headerSideWidth = 56.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: headerSideWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Zurück',
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
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
          ),
          SizedBox(
            width: headerSideWidth,
            child: Align(
              alignment: Alignment.topRight,
              child: _CodeCircle(number: codeNumber, color: codeColor),
            ),
          ),
        ],
      ),
    );
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

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.relevance,
    required this.activityWindows,
  });

  final RelevanceResult relevance;
  final List<ActivityWindow> activityWindows;

  @override
  Widget build(BuildContext context) {
    final preCulture = relevance.activities[ActivityType.preCulture];
    final directSow = relevance.activities[ActivityType.directSow];
    final seedSaving = relevance.activities[ActivityType.seedSaving];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Kalender'),

        // FIX 1: Aussaat immer anzeigen
        _CalendarActivityBlock(
          title: 'Aussaat',
          activity: directSow,
          ranges: _rangesFor(ActivityType.directSow),
        ),

        const SizedBox(height: 12),

        // FIX 2: Voranzucht immer anzeigen
        _CalendarActivityBlock(
          title: 'Voranzucht',
          activity: preCulture,
          ranges: _rangesFor(ActivityType.preCulture),
        ),

        // Nachbau bleibt wie bisher optional (keine neuen Anforderungen dafür)
        if (seedSaving != null &&
            _rangesFor(ActivityType.seedSaving).isNotEmpty) ...[
          const SizedBox(height: 12),
          _CalendarActivityBlock(
            title: 'Nachbau',
            activity: seedSaving,
            ranges: _rangesFor(ActivityType.seedSaving),
          ),
        ],
      ],
    );
  }

  List<MonthRange> _rangesFor(ActivityType type) {
    return activityWindows
        .where((window) => window.type == type)
        .map((window) => window.range)
        .toList(growable: false);
  }
}

// FIX 3: Kalender-Inhalte im gleichen Layout wie bestehende Details (_KeyValueRow)
class _CalendarActivityBlock extends StatelessWidget {
  const _CalendarActivityBlock({
    required this.title,
    required this.activity,
    required this.ranges,
  });

  final String title;
  final ActivityInMonth? activity;
  final List<MonthRange> ranges;

  @override
  Widget build(BuildContext context) {
    final status = _statusText(activity);
    final rangeText = _rangeText(ranges);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        _KeyValueRow('Status', status),
        _KeyValueRow('Fenster', rangeText),
      ],
    );
  }

  String _statusText(ActivityInMonth? activity) {
    if (activity == null) return '—';
    final flags = <String>[];
    if (activity.starts) flags.add('startet');
    if (activity.continues) flags.add('läuft');
    if (activity.ends) flags.add('endet');
    if (flags.isEmpty) return 'nicht aktiv';
    return flags.join(' · ');
  }

  String _rangeText(List<MonthRange> ranges) {
    if (ranges.isEmpty) return '—';
    return ranges.map(_formatRange).join(', ');
  }

  String _formatRange(MonthRange range) {
    return '${_monthLabel(range.start)}–${_monthLabel(range.end)}';
  }

  String _monthLabel(int month) {
    const labels = <String>[
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    if (month < 1 || month > labels.length) return '';
    return labels[month - 1];
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.codeNumber,
    required this.codeColor,
    required this.subtitle,
  });

  final int codeNumber;
  final Color codeColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CodeCircle(number: codeNumber, color: codeColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
        ),
      ],
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

class _SubtleHint extends StatelessWidget {
  const _SubtleHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.black54, height: 1.3),
    );
  }
}

class _CodeCircle extends StatelessWidget {
  const _CodeCircle({required this.number, required this.color});
  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isVeryLight = color.computeLuminance() > 0.80;
    final textColor = isVeryLight ? Colors.black87 : Colors.white;
    final border = isVeryLight
        ? Border.all(color: Colors.black26, width: 1)
        : null;

    return Container(
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
    );
  }
}
