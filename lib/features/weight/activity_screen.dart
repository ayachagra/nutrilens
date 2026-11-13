import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'weight_provider.dart';
import 'activity_log.dart';
import 'activity_provider.dart';
import 'activity_suggester.dart';
import 'activity_type.dart';
import 'add_edit_activity_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ActivityProvider>();
    final wp = context.watch<WeightProvider>();
    final weight = wp.latest?.weightKg ?? 70.0;

    final suggestions = p.isToday
        ? ActivitySuggester.suggest(
      goal: wp.goal?.type,
      weekEqMinutes: p.weekEquivalentMinutes,
      todayMinutes: p.dayMinutes,
      doneThisWeek: p.typesThisWeek,
      doneToday: p.typesToday,
      strengthSessions: p.strengthSessions,
    )
        : <Suggestion>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Activité')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Activité'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditActivityScreen()),
        ),
      ),
      body: p.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          _DayPicker(day: p.selectedDay),
          _SummaryCard(provider: p),
          if (p.isToday && p.dayMinutes >= 90) ...[
            const SizedBox(height: 12),
            const _InfoBox(
              'Belle journée active ! Pensez à vous reposer et à bien '
                  'vous hydrater : la récupération fait partie du progrès.',
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              child: Text('Propositions pour aujourd\'hui',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final s in suggestions)
              _SuggestionTile(s: s, weightKg: weight),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
            child: Text('Activités du jour',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (p.dayItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aucune activité enregistrée')),
            )
          else
            for (final a in p.dayItems) _ActivityTile(log: a),
          const SizedBox(height: 16),
          const _InfoBox(
            'Estimations indicatives. En cas de maladie, de douleur ou '
                'de reprise après une longue pause, demandez l\'avis d\'un '
                'professionnel de santé.',
          ),
        ],
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  final DateTime day;
  const _DayPicker({required this.day});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ActivityProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () =>
              p.changeDay(DateTime(day.year, day.month, day.day - 1)),
        ),
        TextButton(
          child: Text(DateFormat('EEEE d MMMM', 'fr').format(day)),
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) p.changeDay(d);
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () =>
              p.changeDay(DateTime(day.year, day.month, day.day + 1)),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ActivityProvider provider;
  const _SummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = (provider.weekEquivalentMinutes /
        ActivityProvider.weeklyTarget)
        .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onPrimary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Big('${provider.dayMinutes}', 'min aujourd\'hui'),
                _Big('${provider.dayKcal.round()}', 'kcal brûlées'),
              ],
            ),
            const SizedBox(height: 16),
            Text('Semaine : ${provider.weekMinutes} min '
                '(objectif ${ActivityProvider.weeklyTarget} min)'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: scheme.onPrimary.withValues(alpha: 0.25),
              color: scheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  final String value;
  final String label;
  const _Big(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onPrimary;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: c, fontWeight: FontWeight.bold)),
          Text(label),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final Suggestion s;
  final double weightKg;
  const _SuggestionTile({required this.s, required this.weightKg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kcal = estimateKcal(
      type: s.type,
      intensity: s.intensity,
      minutes: s.minutes,
      weightKg: weightKg,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(s.type.icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.type.label} · ${s.minutes} min · '
                          '${s.intensity.label}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text('≈ ${kcal.round()} kcal',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      s.reason,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style:
                FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEditActivityScreen(preset: s)),
                ),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityLog log;
  const _ActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.read<ActivityProvider>();
    final messenger = ScaffoldMessenger.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Dismissible(
          key: ValueKey(log.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: scheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child:
            Icon(Icons.delete_outline, color: scheme.onErrorContainer),
          ),
          onDismissed: (_) {
            p.delete(log.id);
            messenger.clearSnackBars();
            messenger.showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              content: const Text('Activité supprimée'),
              action: SnackBarAction(
                  label: 'Annuler', onPressed: () => p.add(log)),
            ));
          },
          child: Material(
            color: scheme.surfaceContainerLow,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(log.type.icon, color: scheme.onPrimaryContainer),
              ),
              title: Text(log.type.label),
              subtitle: Text([
                '${log.durationMin} min',
                log.intensity.label,
                if (log.note != null) log.note!,
              ].join(' · ')),
              trailing: Text('${log.kcal.round()} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddEditActivityScreen(log: log)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
              child:
              Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}