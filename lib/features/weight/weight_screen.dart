import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_edit_weight_screen.dart';
import 'goal.dart';
import 'goal_screen.dart';
import 'health_sync_button.dart';
import 'weight_entry.dart';
import 'weight_provider.dart';

class _Row {
  final WeightEntry entry;
  final double? delta;
  const _Row(this.entry, this.delta);
}

List<Object> _buildItems(List<WeightEntry> entries) {
  final items = <Object>[];
  String? lastMonth;
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final month = DateFormat('MMMM yyyy', 'fr').format(e.date);
    if (month != lastMonth) {
      items.add(month);
      lastMonth = month;
    }
    final prev = i + 1 < entries.length ? entries[i + 1] : null;
    items.add(_Row(e, prev == null ? null : e.weightKg - prev.weightKg));
  }
  return items;
}

class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WeightProvider>();
    final items = _buildItems(p.entries);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pesée', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditWeightScreen()),
          );
        },
      ),
      body: p.loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                const SliverAppBar.large(
                  title: Text('Mon poids'),
                  actions: [HealthSyncButton()],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _HeroCard(provider: p),
                  ),
                ),
                if (p.entries.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _QuickStatsRow(provider: p),
                    ),
                  ),
                if (p.entries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            item[0].toUpperCase() + item.substring(1),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _WeightTile(
                          row: item as _Row,
                          goalType: p.goal?.type,
                        ),
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final WeightProvider provider;
  const _HeroCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final g = provider.goal;
    final cur = provider.latest?.weightKg;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.secondary, 0.6)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onPrimary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.scale_rounded,
                              size: 16,
                              color: scheme.onPrimary.withValues(alpha: 0.8)),
                          const SizedBox(width: 6),
                          Text(
                            'Poids actuel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cur == null ? '—' : '${cur.toStringAsFixed(1)} kg',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),
                ),
                if (g != null) _ProgressRing(value: provider.progress ?? 0),
              ],
            ),
            const SizedBox(height: 20),
            if (g == null)
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoalScreen()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Définir un objectif'),
                  ],
                ),
              )
            else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _Stat(
                      label: 'Départ',
                      value: '${g.startWeightKg.toStringAsFixed(1)} kg',
                    ),
                    _Stat(
                      label: 'Évolution',
                      value: cur == null
                          ? '—'
                          : _signed(cur - g.startWeightKg, ' kg'),
                    ),
                    _Stat(
                      label: 'Cible',
                      value: '${g.targetWeightKg.toStringAsFixed(1)} kg',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.flag_rounded,
                      size: 16, color: scheme.onPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${g.type.label} · ${_daysLeft(g.targetDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: scheme.onPrimary),
                    tooltip: 'Modifier l\'objectif',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoalScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _daysLeft(DateTime d) {
    final days = d.difference(DateTime.now()).inDays;
    if (days < 0) return 'date dépassée';
    if (days == 0) return 'aujourd\'hui';
    return '$days jours restants';
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;
  const _ProgressRing({required this.value});

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: onPrimary.withValues(alpha: 0.2),
              color: onPrimary,
            ),
            Center(
              child: Text(
                '${(v * 100).round()}%',
                style: TextStyle(
                  color: onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: onPrimary.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final WeightProvider provider;
  const _QuickStatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.entries;
    if (entries.isEmpty) return const SizedBox.shrink();

    // Calculs rapides
    final minWeight = entries
        .map((e) => e.weightKg)
        .reduce((a, b) => a < b ? a : b);

    final last7 = entries.take(7).map((e) => e.weightKg).toList();
    final avg7 = last7.reduce((a, b) => a + b) / last7.length;

    final goal = provider.goal;
    final latest = provider.latest?.weightKg;
    final remaining = (goal != null && latest != null)
        ? (latest - goal.targetWeightKg).abs()
        : null;

    return Row(
      children: [
        _MiniStatCard(
          icon: Icons.trending_down_rounded,
          label: 'Min (total)',
          value: '${minWeight.toStringAsFixed(1)} kg',
        ),
        const SizedBox(width: 8),
        _MiniStatCard(
          icon: Icons.analytics_outlined,
          label: 'Moy. (7j)',
          value: '${avg7.toStringAsFixed(1)} kg',
        ),
        if (remaining != null) ...[
          const SizedBox(width: 8),
          _MiniStatCard(
            icon: Icons.flag_rounded,
            label: 'Restant',
            value: '${remaining.toStringAsFixed(1)} kg',
          ),
        ],
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _signed(double v, String unit) {
  final s = v.toStringAsFixed(1);
  return v > 0 ? '+$s$unit' : '$s$unit';
}

class _WeightTile extends StatelessWidget {
  final _Row row;
  final GoalType? goalType;

  const _WeightTile({required this.row, this.goalType});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.read<WeightProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final e = row.entry;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Dismissible(
        key: ValueKey(e.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: scheme.errorContainer,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(Icons.delete_outline_rounded,
              color: scheme.onErrorContainer),
        ),
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          p.delete(e.id);
          messenger.clearSnackBars();
          messenger.showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Pesée supprimée'),
            action: SnackBarAction(
                label: 'Annuler', onPressed: () => p.add(e)),
          ));
        },
        child: Material(
          color: scheme.surfaceContainerLow,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditWeightScreen(entry: e)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(e.date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'fr').format(e.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.weightKg.toStringAsFixed(1)} kg',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_subtitle(e).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              _subtitle(e),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (row.delta != null)
                    _DeltaChip(delta: row.delta!, goalType: goalType),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _subtitle(WeightEntry e) => [
        if (e.waistCm != null) 'Taille ${e.waistCm!.toStringAsFixed(0)} cm',
        if (e.note != null && e.note!.isNotEmpty) e.note!,
      ].join(' · ');
}

class _DeltaChip extends StatelessWidget {
  final double delta;
  final GoalType? goalType;

  const _DeltaChip({required this.delta, this.goalType});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stable = delta.abs() < 0.05;

    // Déterminer si la variation va dans le sens de l'objectif
    final isPositiveProgress = (goalType == GoalType.lose && delta < 0) ||
        (goalType == GoalType.gain && delta > 0);

    Color chipBg = scheme.surfaceContainerHighest;
    Color chipFg = scheme.onSurfaceVariant;

    if (!stable) {
      if (isPositiveProgress) {
        chipBg = const Color(0xFFDCFCE7); // Soft Emerald light
        chipFg = const Color(0xFF15803D);
      } else {
        chipBg = const Color(0xFFFEF3C7); // Soft Amber light
        chipFg = const Color(0xFFB45309);
      }
    }

    final icon = stable
        ? Icons.remove
        : (delta > 0 ? Icons.arrow_upward : Icons.arrow_downward);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipFg),
          const SizedBox(width: 4),
          Text(
            stable ? 'stable' : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: chipFg,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.scale_rounded,
                size: 56, color: scheme.primary),
          ),
          const SizedBox(height: 20),
          Text('Aucune pesée pour l\'instant',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première pesée pour commencer à suivre votre évolution.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
