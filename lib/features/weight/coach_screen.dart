import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'coach_service.dart';
import 'goal.dart';
import 'health_service.dart';
import 'milestone_planner.dart';
import 'nutrition_calculation.dart';
import 'profile_provider.dart';
import 'weight_provider.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _service = CoachService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initGreeting();
  }

  void _initGreeting() {
    _messages.add(
      ChatMessage(
        isUser: false,
        text: '''Bonjour ! Je suis votre coach NutriLens 🤖

Je suis là pour répondre à toutes vos questions sur votre poids, votre nutrition, ou vous proposer des plans d'action personnalisés.

Comment puis-je vous aider aujourd'hui ?''',
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _buildSummary() async {
    final wp = context.read<WeightProvider>();
    final profile = context.read<ProfileProvider>().profile;
    final goal = wp.goal;

    final b = StringBuffer();

    if (goal != null) {
      b.writeln('Objectif : ${goal.type.label}, de '
          '${goal.startWeightKg.toStringAsFixed(1)} kg à '
          '${goal.targetWeightKg.toStringAsFixed(1)} kg avant le '
          '${goal.targetDate.toIso8601String().substring(0, 10)}.');
    } else {
      b.writeln('Objectif : Pas encore d\'objectif défini.');
    }

    if (wp.latest != null) {
      b.writeln('Poids actuel : ${wp.latest!.weightKg.toStringAsFixed(1)} kg.');
    } else {
      b.writeln('Poids actuel : Aucune pesée enregistrée.');
    }

    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final recent = wp.entries.where((e) => e.date.isAfter(cutoff)).toList();
    if (recent.isNotEmpty) {
      b.writeln('Pesées des 14 derniers jours :');
      for (final e in recent) {
        b.writeln('- ${e.date.toIso8601String().substring(0, 10)} : '
            '${e.weightKg.toStringAsFixed(1)} kg');
      }
    }

    if (goal != null) {
      final plan = MilestonePlanner.build(goal, wp.entries);
      if (plan != null) {
        b.writeln('Statut du plan : ${plan.status.name}, écart de '
            '${plan.deviationKg.toStringAsFixed(1)} kg par rapport au poids '
            'attendu (${plan.expectedNowKg.toStringAsFixed(1)} kg). '
            'Rythme prévu : ${plan.weeklyRateKg.toStringAsFixed(2)} kg/semaine.');
      }
    }

    if (profile != null && wp.latest != null && goal != null) {
      final t = NutritionCalculator.compute(
        profile: profile,
        weightKg: wp.latest!.weightKg,
        goalType: goal.type,
        targetWeightKg: goal.targetWeightKg,
        targetDate: goal.targetDate,
      );
      b.writeln('Objectif calorique : ${t.kcal.round()} kcal/jour '
          '(protéines ${t.proteinG.round()} g, glucides ${t.carbsG.round()} g, '
          'lipides ${t.fatG.round()} g).');
    }

    try {
      final steps = await HealthService().stepsToday();
      if (steps != null) b.writeln('Pas aujourd\'hui : $steps.');
    } catch (_) {}

    return b.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _loading) return;

    if (presetText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final summary = await _buildSummary();
      // On passe l'historique privé du message d'accueil pour la requête API
      final history = _messages.skip(1).take(_messages.length - 2).toList();

      final result = await _service.chat(
        contextSummary: summary,
        history: history,
        userMessage: text,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              isUser: false,
              text: result.responseText,
              retrievedSources:
                  result.sources.isEmpty ? null : result.sources,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              isUser: false,
              text: 'Désolé, une erreur est survenue : ${e.toString()}',
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _initGreeting();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 22),
            SizedBox(width: 8),
            Text('Coach NutriLens'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Réinitialiser la discussion',
            icon: const Icon(Icons.refresh),
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner d'avertissement bienveillant
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conseils donnés par l\'IA à titre indicatif, ne remplaçant pas un avis médical.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),

          // Liste des messages du chatbot
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _loading) {
                  return const _LoadingBubble();
                }
                final msg = _messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // Suggestions d'actions rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _ActionChip(
                  label: '🎯 Plan d\'action 7j',
                  onTap: () =>
                      _sendMessage('Donne-moi un plan d\'action sur 7 jours adapté à mon objectif.'),
                ),
                _ActionChip(
                  label: '📊 Analyser mes progrès',
                  onTap: () =>
                      _sendMessage('Analyse mes pesées et mon statut actuel.'),
                ),
                _ActionChip(
                  label: '🥗 Idée de repas',
                  onTap: () => _sendMessage(
                      'Propose-moi des idées de repas sains et faciles pour aujourd\'hui.'),
                ),
                _ActionChip(
                  label: '💡 Gérer un écart',
                  onTap: () => _sendMessage(
                      'J\'ai fait un gros repas ou un écart, comment réagir sans stress ?'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Barre d'envoi de message
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Posez une question à votre coach...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    onPressed: _loading ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.auto_awesome,
                  size: 16, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? scheme.primary
                    : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormattedText(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? scheme.onPrimary
                          : scheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser
                            ? scheme.onPrimary.withValues(alpha: 0.7)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.auto_awesome,
                size: 16, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Le coach réfléchit...',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _FormattedText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _FormattedText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: _buildLine(line),
        );
      }).toList(),
    );
  }

  Widget _buildLine(String line) {
    final spans = <TextSpan>[];
    final parts = line.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i % 2 == 1
              ? style.copyWith(fontWeight: FontWeight.bold)
              : style,
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
