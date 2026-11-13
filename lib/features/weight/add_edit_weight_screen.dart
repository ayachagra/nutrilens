import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'weight_entry.dart';
import 'weight_provider.dart';

class AddEditWeightScreen extends StatefulWidget {
  final WeightEntry? entry; // null = création
  const AddEditWeightScreen({super.key, this.entry});

  @override
  State<AddEditWeightScreen> createState() => _AddEditWeightScreenState();
}

class _AddEditWeightScreenState extends State<AddEditWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _waist;
  late final TextEditingController _note;
  late DateTime _date;

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final last = context.read<WeightProvider>().latest;
    _weight = TextEditingController(
        text: (e?.weightKg ?? last?.weightKg ?? 70.0).toStringAsFixed(1));
    _waist = TextEditingController(text: e?.waistCm?.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _note.dispose();
    super.dispose();
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _bump(double step) {
    final current = _parse(_weight.text) ?? 70.0;
    final next = (current + step).clamp(20.0, 500.0);
    setState(() => _weight.text = next.toStringAsFixed(1));
    HapticFeedback.selectionClick();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final p = context.read<WeightProvider>();

    final entry = WeightEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      weightKg: _parse(_weight.text)!,
      waistCm: _waist.text.trim().isEmpty ? null : _parse(_waist.text),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      date: _date,
    );

    HapticFeedback.mediumImpact();
    _isEdit ? await p.update(entry) : await p.add(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.bold);

    final isToday = DateUtils.isSameDay(_date, DateTime.now());
    final isYesterday = DateUtils.isSameDay(
        _date, DateTime.now().subtract(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la pesée' : 'Nouvelle pesée'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Card centrale pour saisir le poids de manière ludique
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text('Saisissez votre poids', style: labelStyle),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _weight,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                          decoration: const InputDecoration(
                            suffixText: 'kg',
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            final n = _parse(v ?? '');
                            if (n == null) return 'Invalide';
                            if (n < 20 || n > 500) return '20-500 kg';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Boutons de réglage rapide (-1kg, -0.1kg, +0.1kg, +1kg)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StepButton(
                          label: '-1 kg', onTap: () => _bump(-1.0)),
                      _StepButton(
                          label: '-0.1 kg', onTap: () => _bump(-0.1)),
                      _StepButton(
                          label: '+0.1 kg', onTap: () => _bump(0.1)),
                      _StepButton(
                          label: '+1 kg', onTap: () => _bump(1.0)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Raccourcis de sélection de date
            Text('Date de la pesée', style: labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    selected: isToday,
                    label: const Center(child: Text('Aujourd\'hui')),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _date = DateTime.now());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    selected: isYesterday,
                    label: const Center(child: Text('Hier')),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _date =
                          DateTime.now().subtract(const Duration(days: 1)));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Choisir une date',
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                DateFormat('EEEE d MMMM yyyy', 'fr').format(_date),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),

            Text('Tour de taille (optionnel)', style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _waist,
              decoration: const InputDecoration(
                hintText: 'Ex. 82',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.straighten_rounded),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = _parse(v);
                if (n == null || n < 30 || n > 300) {
                  return 'Entre 30 et 300 cm';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            Text('Note personnelle (optionnel)', style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ex. Après la séance de sport, à jeun...',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEdit ? 'Enregistrer les modifications' : 'Ajouter la pesée'),
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
