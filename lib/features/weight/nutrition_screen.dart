import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goal_screen.dart';
import 'nutrition_calculation.dart';
import 'plan_screen.dart';
import 'profile_provider.dart';
import 'weight_provider.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final wp = context.watch<WeightProvider>();
    final weight = wp.latest?.weightKg;
    final goal = wp.goal;

    NutritionTargets? t;
    if (profile != null && weight != null && goal != null) {
      t = NutritionCalculator.compute(
        profile: profile,
        weightKg: weight,
        goalType: goal.type,
        targetWeightKg: goal.targetWeightKg,
        targetDate: goal.targetDate,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectifs nutrition'),
        actions: [
          IconButton(
            tooltip: 'Modifier mon profil',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile == null)
            _TodoCard(
              icon: Icons.person_outline_rounded,
              title: 'Profil incomplet',
              subtitle: 'Renseignez votre sexe, âge, taille et activité.',
              actionLabel: 'Configurer mon profil',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          if (weight == null)
            const _TodoCard(
              icon: Icons.scale_outlined,
              title: 'Aucune pesée',
              subtitle: 'Ajoutez au moins une pesée dans l\'onglet Poids.',
            ),
          if (goal == null)
            _TodoCard(
              icon: Icons.flag_outlined,
              title: 'Objectif non défini',
              subtitle: 'Définissez votre poids cible pour ajuster les calories.',
              actionLabel: 'Définir un objectif',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GoalScreen())),
            ),
          if (t != null) ...[
            _KcalHeroCard(t: t),
            const SizedBox(height: 16),
            Text(
              'Répartition des macronutriments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _MacroRatioBar(t: t),
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroCard(
                  label: 'Protéines',
                  grams: t.proteinG,
                  color: const Color(0xFFEF4444), // Coral Red
                  icon: Icons.fitness_center_rounded,
                  kcal: t.proteinG * 4,
                ),
                const SizedBox(width: 8),
                _MacroCard(
                  label: 'Glucides',
                  grams: t.carbsG,
                  color: const Color(0xFFF59E0B), // Amber
                  icon: Icons.grain_rounded,
                  kcal: t.carbsG * 4,
                ),
                const SizedBox(width: 8),
                _MacroCard(
                  label: 'Lipides',
                  grams: t.fatG,
                  color: const Color(0xFF3B82F6), // Blue
                  icon: Icons.water_drop_rounded,
                  kcal: t.fatG * 9,
                ),
              ],
            ),
            if (t.warning != null) ...[
              const SizedBox(height: 16),
              _Notice(text: t.warning!, icon: Icons.warning_amber_rounded),
            ],
            const SizedBox(height: 16),
            const _Notice(
              icon: Icons.health_and_safety_outlined,
              text: 'Valeurs indicatives (±10 à 15 %). Elles ne remplacent pas '
                  'un avis médical et ne conviennent pas en cas de grossesse, '
                  'd\'allaitement ou de pathologie.',
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _KcalHeroCard extends StatelessWidget {
  final NutritionTargets t;
  const _KcalHeroCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.secondary, 0.7)!,
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
                Icon(Icons.local_fire_department_rounded,
                    size: 20, color: scheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  'Cible journalière recommandée',
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${t.kcal.round()} kcal',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _KcalSubInfo(
                      label: 'Métabolisme de base',
                      value: '${t.bmr.round()} kcal',
                      hint: 'BMR',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: scheme.onPrimary.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _KcalSubInfo(
                      label: 'Dépense totale',
                      value: '${t.tdee.round()} kcal',
                      hint: 'TDEE',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KcalSubInfo extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _KcalSubInfo({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: onPrimary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MacroRatioBar extends StatelessWidget {
  final NutritionTargets t;
  const _MacroRatioBar({required this.t});

  @override
  Widget build(BuildContext context) {
    final totalKcal = (t.proteinG * 4) + (t.carbsG * 4) + (t.fatG * 9);
    final protPct = totalKcal > 0 ? (t.proteinG * 4) / totalKcal : 0.33;
    final carbPct = totalKcal > 0 ? (t.carbsG * 4) / totalKcal : 0.33;
    final fatPct = totalKcal > 0 ? (t.fatG * 9) / totalKcal : 0.34;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
              flex: (protPct * 100).round(),
              child: Container(color: const Color(0xFFEF4444)),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: (carbPct * 100).round(),
              child: Container(color: const Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: (fatPct * 100).round(),
              child: Container(color: const Color(0xFF3B82F6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double grams;
  final double kcal;
  final Color color;
  final IconData icon;

  const _MacroCard({
    required this.label,
    required this.grams,
    required this.kcal,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '${grams.round()} g',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '~${kcal.round()} kcal',
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Notice({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _TodoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onTap,
                      child: Text(
                        actionLabel!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
