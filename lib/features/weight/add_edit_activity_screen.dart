import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../weight/weight_provider.dart';
import 'activity_log.dart';
import 'activity_provider.dart';
import 'activity_suggester.dart';
import 'activity_type.dart';

class AddEditActivityScreen extends StatefulWidget {
  final ActivityLog? log; // modification
  final Suggestion? preset; // pré-remplissage depuis une proposition
  const AddEditActivityScreen({super.key, this.log, this.preset});

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minutes;
  late final TextEditingController _note;
  late ActivityType _type;
  late Intensity _intensity;

  bool get _isEdit => widget.log != null;

  @override
  void initState() {
    super.initState();
    final l = widget.log;
    final s = widget.preset;
    _type = l?.type ?? s?.type ?? ActivityType.walking;
    _intensity = l?.intensity ?? s?.intensity ?? Intensity.moderate;
    _minutes = TextEditingController(
        text: (l?.durationMin ?? s?.minutes ?? 30).toString());
    _note = TextEditingController(text: l?.note ?? '');
  }

  @override
  void dispose() {
    _minutes.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _min => int.tryParse(_minutes.text.trim());

  double get _weight =>
      context.read<WeightProvider>().latest?.weightKg ?? 70.0;

  double get _kcal => estimateKcal(
    type: _type,
    intensity: _intensity,
    minutes: _min ?? 0,
    weightKg: _weight,
  );

  void _bump(int step) {
    final next = ((_min ?? 30) + step).clamp(5, 600);
    setState(() => _minutes.text = next.toString());
    HapticFeedback.selectionClick();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final p = context.read<ActivityProvider>();
    final day = p.selectedDay;
    final now = DateTime.now();

    final log = ActivityLog(
      id: widget.log?.id ?? const Uuid().v4(),
      type: _type,
      intensity: _intensity,
      durationMin: _min!,
      kcal: _kcal,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      date: widget.log?.date ??
          DateTime(day.year, day.month, day.day, now.hour, now.minute),
    );

    _isEdit ? await p.update(log) : await p.add(log);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.titleSmall;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Modifier l\'activité' : 'Nouvelle activité')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Type d\'activité', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ActivityType.values)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 18),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Intensité', style: label),
            const SizedBox(height: 8),
            SegmentedButton<Intensity>(
              segments: [
                for (final i in Intensity.values)
                  ButtonSegment(value: i, label: Text(i.label)),
              ],
              selected: {_intensity},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  setState(() => _intensity = s.first),
            ),
            const SizedBox(height: 24),
            Text('Durée', style: label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                suffixText: 'min',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null) return 'Nombre invalide';
                if (n < 1 || n > 600) return 'Entre 1 et 600 minutes';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _bump(-5)),
                const SizedBox(width: 24),
                IconButton.filledTonal(
                    icon: const Icon(Icons.add), onPressed: () => _bump(5)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: scheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '≈ ${_kcal.round()} kcal brûlées '
                          '(base : ${_weight.toStringAsFixed(1)} kg)',
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Note (optionnel)', style: label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ex. séance au parc, bonnes sensations...',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(_isEdit ? 'Enregistrer' : 'Ajouter'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}