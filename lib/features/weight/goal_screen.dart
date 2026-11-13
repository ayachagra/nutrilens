import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'goal.dart';
import 'weight_provider.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _start;
  late final TextEditingController _target;
  late GoalType _type;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    final p = context.read<WeightProvider>();
    final g = p.goal;
    _start = TextEditingController(
        text: (g?.startWeightKg ?? p.latest?.weightKg)?.toString() ?? '');
    _target = TextEditingController(text: g?.targetWeightKg.toString() ?? '');
    _type = g?.type ?? GoalType.lose;
    _targetDate =
        g?.targetDate ?? DateTime.now().add(const Duration(days: 90));

    _start.addListener(() => setState(() {}));
    _target.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _start.dispose();
    _target.dispose();
    super.dispose();
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  String? _validateWeight(String? v) {
    final n = _parse(v ?? '');
    if (n == null) return 'Nombre invalide';
    if (n < 20 || n > 500) return 'Entre 20 et 500 kg';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _parse(_start.text)!;
    final target =
        _type == GoalType.maintain ? start : _parse(_target.text)!;

    if ((_type == GoalType.lose && target >= start) ||
        (_type == GoalType.gain && target <= start)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
              'Le poids cible ne correspond pas au type d\'objectif.')));
      return;
    }

    HapticFeedback.mediumImpact();
    await context.read<WeightProvider>().saveGoal(Goal(
      type: _type,
      startWeightKg: start,
      targetWeightKg: target,
      targetDate: _targetDate,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.bold);

    final startVal = _parse(_start.text);
    final targetVal = _parse(_target.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon objectif de poids'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Type d\'objectif', style: labelStyle),
            const SizedBox(height: 8),
            SegmentedButton<GoalType>(
              segments: [
                for (final t in GoalType.values)
                  ButtonSegment(
                    value: t,
                    label: Text(t.label),
                    icon: Icon(_goalIcon(t)),
                  ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                setState(() => _type = s.first);
              },
            ),
            const SizedBox(height: 24),
            Text('Poids de départ', style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _start,
              decoration: const InputDecoration(
                hintText: 'Ex. 78',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.play_arrow_rounded),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validateWeight,
            ),
            if (_type != GoalType.maintain) ...[
              const SizedBox(height: 24),
              Text('Poids cible', style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _target,
                decoration: const InputDecoration(
                  hintText: 'Ex. 72',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateWeight,
              ),
            ],
            const SizedBox(height: 24),
            Text('Date cible', style: labelStyle),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 1825)),
                );
                if (d != null) setState(() => _targetDate = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_month_rounded),
                  suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                ),
                child:
                    Text(DateFormat('d MMMM yyyy', 'fr').format(_targetDate)),
              ),
            ),
            const SizedBox(height: 24),

            // Aperçu dynamique du rythme de progression
            if (startVal != null &&
                (targetVal != null || _type == GoalType.maintain))
              _GoalPreviewCard(
                type: _type,
                start: startVal,
                target: _type == GoalType.maintain ? startVal : targetVal!,
                targetDate: _targetDate,
              ),

            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Enregistrer l\'objectif'),
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _goalIcon(GoalType t) {
    switch (t) {
      case GoalType.lose:
        return Icons.trending_down_rounded;
      case GoalType.maintain:
        return Icons.drag_handle_rounded;
      case GoalType.gain:
        return Icons.trending_up_rounded;
    }
  }
}

class _GoalPreviewCard extends StatelessWidget {
  final GoalType type;
  final double start;
  final double target;
  final DateTime targetDate;

  const _GoalPreviewCard({
    required this.type,
    required this.start,
    required this.target,
    required this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = targetDate.difference(DateTime.now()).inDays;
    final weeks = (days / 7).clamp(1.0, 520.0);
    final diff = (target - start).abs();
    final weeklyRate = diff / weeks;

    final isFast = weeklyRate > 1.0 && type != GoalType.maintain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFast
            ? scheme.errorContainer.withValues(alpha: 0.6)
            : scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFast
              ? scheme.error.withValues(alpha: 0.3)
              : scheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFast ? Icons.speed_rounded : Icons.auto_graph_rounded,
            color: isFast ? scheme.onErrorContainer : scheme.primary,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == GoalType.maintain
                      ? 'Maintien de votre poids actuel'
                      : 'Rythme prévu : ${weeklyRate.toStringAsFixed(2)} kg / semaine',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isFast ? scheme.onErrorContainer : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFast
                      ? 'Un rythme > 1 kg/semaine peut être difficile à maintenir. Pensez à rallonger la durée.'
                      : 'Objectif réaliste et progressif sur $days jours ($weeks semaines).',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFast
                        ? scheme.onErrorContainer.withValues(alpha: 0.8)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
