import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'profile_provider.dart';
import 'user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _height;
  late Sex _sex;
  late ActivityLevel _activity;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().profile;
    _age = TextEditingController(text: p?.age.toString() ?? '');
    _height = TextEditingController(text: p?.heightCm.toString() ?? '');
    _sex = p?.sex ?? Sex.female;
    _activity = p?.activity ?? ActivityLevel.light;
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    await context.read<ProfileProvider>().save(UserProfile(
      sex: _sex,
      age: int.parse(_age.text.trim()),
      heightCm: double.parse(_height.text.trim().replaceAll(',', '.')),
      activity: _activity,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Sexe (pour le calcul du métabolisme)', style: labelStyle),
            const SizedBox(height: 8),
            SegmentedButton<Sex>(
              segments: [
                for (final s in Sex.values)
                  ButtonSegment(
                    value: s,
                    label: Text(s.label),
                    icon: Icon(s == Sex.female
                        ? Icons.female_rounded
                        : Icons.male_rounded),
                  ),
              ],
              selected: {_sex},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                setState(() => _sex = s.first);
              },
            ),
            const SizedBox(height: 24),
            Text('Âge', style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex. 25',
                suffixText: 'ans',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null) return 'Nombre invalide';
                if (n < 18) return 'Calcul réservé aux adultes (18 ans et +)';
                if (n > 100) return 'Âge invalide';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Taille', style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _height,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Ex. 175',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.height_rounded),
              ),
              validator: (v) {
                final n =
                    double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null) return 'Nombre invalide';
                if (n < 120 || n > 230) return 'Entre 120 et 230 cm';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Niveau d\'activité', style: labelStyle),
            const SizedBox(height: 8),
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activity,
              isExpanded: true,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.directions_run_rounded)),
              items: [
                for (final a in ActivityLevel.values)
                  DropdownMenuItem(
                    value: a,
                    child: Text(a.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _activity = v);
              },
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Enregistrer mon profil'),
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
