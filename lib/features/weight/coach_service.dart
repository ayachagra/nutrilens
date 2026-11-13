import 'dart:convert';
import 'package:http/http.dart' as http;
import 'rag_knowledge_base.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? retrievedSources; // Fiches RAG extraites

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.retrievedSources,
  }) : timestamp = timestamp ?? DateTime.now();
}

class CoachService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

  static const _system = '''
Tu es un coach expert en nutrition, bien-être et suivi du poids dans l'application NutriLens.
Tu réponds de manière factuelle, bienveillante, rigoureuse et structurée.

RÈGLES STRICTES ANTI-HALLUCINATION :
1. Ancre tes réponses EXCLUSIVEMENT dans le contexte utilisateur fourni (pesées exactes, calories, objectifs) et les fiches de connaissances RAG transmises.
2. Ne fais JAMAIS d'inventions, ne cite JAMAIS de faux chiffres ou pesées imaginaires. Si le contexte indique "Poids actuel : 75.0 kg", utilise 75.0 kg et aucun autre chiffre.
3. Si l'utilisateur pose une question sans rapport avec ses données ou la nutrition/santé, réponds poliment que tu es spécialisé dans le suivi NutriLens.
4. Rédige ta réponse en français, de manière claire et bien structurée (utilise du gras **mot** et des puces pour la lisibilité).
5. Ne donne pas de diagnostic médical. En cas de doute ou de symptôme, recommande de consulter un professionnel de santé.
''';

  bool get hasCredentials => _apiKey.isNotEmpty;

  /// Pipeline RAG avec contrôle strict de la température pour éviter la moindre hallucination.
  Future<({String responseText, List<String> sources})> chat({
    required String contextSummary,
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    // 🔍 ÉTAPE 1 : RETRIEVAL (Extraction RAG)
    final retrievedDocs = RagKnowledgeBase.search(userMessage, topK: 2);
    final sources = retrievedDocs.map((d) => d.title).toList();

    if (!hasCredentials) {
      final localText = _localChat(contextSummary, retrievedDocs, userMessage);
      return (responseText: localText, sources: sources);
    }

    try {
      final contents = <Map<String, dynamic>>[];

      // Initialisation
      contents.add({
        'role': 'user',
        'parts': [
          {
            'text':
                'Initialisation du fil de discussion avec le coach NutriLens.'
          }
        ]
      });

      contents.add({
        'role': 'model',
        'parts': [
          {
            'text':
                'Bonjour ! Je suis votre coach NutriLens. Je suis prêt à analyser vos données et à répondre à vos questions.'
          }
        ]
      });

      // Historique de discussion
      for (final msg in history) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [
            {'text': msg.text}
          ]
        });
      }

      // 🧠 ÉTAPE 2 & 3 : AUGMENTATION ET GÉNÉRATION DÉTERMINISTE (Prompt enrichi)
      final userPromptWithRag = StringBuffer()
        ..writeln('=== CONTEXTE REEL DE L\'UTILISATEUR ===')
        ..writeln(contextSummary);

      if (retrievedDocs.isNotEmpty) {
        userPromptWithRag
            .writeln('\n=== FICHES DE REFERENCE DE LA BASE RAG NUTRILENS ===');
        for (final doc in retrievedDocs) {
          userPromptWithRag.writeln('• [${doc.title}] : ${doc.content}');
        }
      }

      userPromptWithRag.writeln('\n=== QUESTION DE L\'UTILISATEUR ===');
      userPromptWithRag.writeln(userMessage);
      userPromptWithRag.writeln(
          '\nConsigne stricte : Répondez précisément à cette question en vous basant UNIQUEMENT sur les faits du contexte et des fiches RAG ci-dessus.');

      contents.add({
        'role': 'user',
        'parts': [
          {'text': userPromptWithRag.toString()}
        ]
      });

      final res = await http
          .post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent'),
            headers: {
              'content-type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': _system}
                ]
              },
              'contents': contents,
              'generationConfig': {
                'temperature': 0.2, // Température basse = Factuel, sans hallucination
                'topP': 0.8,
                'maxOutputTokens': 900,
              },
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (res.statusCode != 200) {
        final fallbackText =
            '${_localChat(contextSummary, retrievedDocs, userMessage)}\n\n'
            '*(Service IA temporairement indisponible, réponse générée en mode local)*';
        return (responseText: fallbackText, sources: sources);
      }

      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final parts = (data['candidates'] as List).first['content']['parts']
          as List;
      final text = parts
          .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join('\n')
          .trim();

      final responseText = text.isEmpty
          ? _localChat(contextSummary, retrievedDocs, userMessage)
          : text;

      return (responseText: responseText, sources: sources);
    } catch (_) {
      final fallbackText =
          '${_localChat(contextSummary, retrievedDocs, userMessage)}\n\n'
          '*(Pas de connexion au service IA : réponse générée en mode local)*';
      return (responseText: fallbackText, sources: sources);
    }
  }

  /// Mode local déterministe pour le mode hors-ligne ou sans clé d'API.
  String _localChat(String contextSummary, List<RagDocument> ragDocs,
      String userMessage) {
    final query = userMessage.toLowerCase();

    // Utilisation directe des fiches RAG extraites
    if (ragDocs.isNotEmpty) {
      final doc = ragDocs.first;
      return '''💡 **${doc.title}** (${doc.category})

${doc.content}

*Conseil NutriLens :* N'hésitez pas à poser une autre question sur votre pesée ou votre alimentation !''';
    }

    if (query.contains('plan') ||
        query.contains('action') ||
        query.contains('semaine')) {
      return '''🎯 **Plan d'action recommandé (7 jours)**

1. **Hydratation & Protéines :**
   - Visez **1.5 à 2L d'eau** par jour.
   - Intégrez une source de **protéines** (œufs, poulet, poisson, légumineuses) à chaque repas.

2. **Activité physique :**
   - Atteignez au moins **7 000 pas/jour** ou 30 minutes de marche active.

3. **Pesée & Régularité :**
   - Pesez-vous 2 à 3 fois par semaine le matin à jeun.

4. **Sommeil :**
   - Visez **7 à 8h de sommeil** par nuit pour optimiser la récupération et la faim.''';
    }

    if (query.contains('manger') ||
        query.contains('repas') ||
        query.contains('soir') ||
        query.contains('recette')) {
      return '''🥗 **Conseil d'assiette équilibrée :**

• **1/2 de légumes** (cuits ou crus) pour les fibres.
• **1/4 de protéines** (volaille, poisson, œufs, tofu) pour la masse musculaire.
• **1/4 de glucides complexes** (riz complet, patate douce, quinoa).
• **1 cuillère à soupe de bon gras** (huile d'olive, graines, avocat).''';
    }

    return '''Merci pour votre message !

Pour obtenir des conseils précis :
- Posez une question sur le sport, les repas ou le sommeil.
- Demandez *"Donne-moi un plan d'action sur 7 jours"*
- Demandez *"Que consommer après le sport ?"*''';
  }
}
