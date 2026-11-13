class RagDocument {
  final String id;
  final String title;
  final String category;
  final List<String> keywords;
  final String content;

  const RagDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.keywords,
    required this.content,
  });
}

/// Base de connaissances RAG officielle NutriLens.
class RagKnowledgeBase {
  static const List<RagDocument> _documents = [
    RagDocument(
      id: 'doc_post_workout',
      title: 'Nutrition et Récupération Post-Entraînement',
      category: 'Nutrition & Sport',
      keywords: ['sport', 'séance', 'repas', 'après', 'récupération', 'protéines', 'manger', 'entraînement', 'post'],
      content:
          'Après un entraînement, le corps a besoin de 20 à 30g de protéines pour réparer les fibres musculaires et de glucides complexes pour recharger les stocks de glycogène dans les 2 heures. Exemples recommandés : blanc de poulet avec riz basmati, omelette aux légumes et pain complet, ou skyr avec de l\'avoine et des fruits.',
    ),
    RagDocument(
      id: 'doc_weight_plateau',
      title: 'Stagnation du Poids et Effet Plateau',
      category: 'Suivi du Poids',
      keywords: ['bloqué', 'stagnation', 'plateau', 'bouge plus', 'ralentissement', 'poids fixe', 'pas de perte', 'progrès'],
      content:
          'Une stagnation de 1 à 3 semaines est physiologique et courante. Elle s\'explique par la rétention d\'eau compensatoire, l\'inflammation musculaire temporaire après le sport ou le stress (cortisol élevé). Si le déficit calorique est respecté, la perte de gras continue malgré un poids stable sur la balance. Ne réduisez pas vos calories brutalement.',
    ),
    RagDocument(
      id: 'doc_water_retention',
      title: 'Fluctuations du Poids et Rétention d\'Eau',
      category: 'Physiologie',
      keywords: ['eau', 'rétention', 'fluctuation', 'gonflé', 'sel', 'sodium', 'pesée', 'matin', 'hausse'],
      content:
          'Le poids fluctue naturellement de 0.5 kg à 2 kg d\'un jour à l\'autre. Un repas riche en sodium, des glucides consommés la veille, un manque de sommeil ou des courbatures créent une rétention d\'eau temporaire sans aucun gain de graisse. Il faut se fier à la moyenne hebdomadaire.',
    ),
    RagDocument(
      id: 'doc_meal_ideas',
      title: 'Idées de Repas Équilibrés et Rassasiants',
      category: 'Nutrition',
      keywords: ['idées', 'repas', 'soir', 'déjeuner', 'manger', 'recette', 'menu', 'assiette', 'sain'],
      content:
          'Une assiette optimale pour la gestion du poids se compose de : 1/2 de légumes (fibres et micronutriments), 1/4 de protéines (volaille, poisson, œufs, tofu) pour préserver la masse musculaire, 1/4 de glucides complexes (riz complet, quinoa, patate douce) et 1 cuillère à soupe de bons lipides (huile d\'olive, avocat).',
    ),
    RagDocument(
      id: 'doc_protein_importance',
      title: 'Rôle et Sources de Protéines',
      category: 'Macronutriments',
      keywords: ['protéines', 'sources', 'muscles', 'satiété', 'oeufs', 'poulet', 'tofu', 'légumineuses', 'apport'],
      content:
          'Les protéines possèdent l\'effet thermique le plus élevé (20-30% des calories consommées sont brûlées pour les digérer) et favorisent la satiété. Visez 1.4g à 1.8g par kg de poids. Excellentes sources : poitrine de dinde/poulet, poisson blanc, saumon, œufs,fromage blanc/skyr, lentilles et pois chiches.',
    ),
    RagDocument(
      id: 'doc_sleep_and_cravings',
      title: 'Sommeil, Hormones et Gestion des Fringales',
      category: 'Habitudes & Sommeil',
      keywords: ['sommeil', 'fringales', 'faim', 'nuit', 'fatigue', 'sucre', 'envie', 'soir', 'grignotage'],
      content:
          'Dormir moins de 7 heures augmente la ghréline (hormone stimulant l\'appétit) et diminue la leptine (hormone de satiété). Cela provoque des envies irrésistibles de sucre et d\'aliments ultra-transformés. Un sommeil de 7h à 8h est un pilier fondamental du contrôle du poids.',
    ),
    RagDocument(
      id: 'doc_overeating_recovery',
      title: 'Gestion d\'un Écart ou Repas Copieux',
      category: 'Comportement',
      keywords: ['écart', 'craqué', 'restaurant', 'excès', 'fast-food', 'culpabilité', 'fête', 'gros repas'],
      content:
          'Un seul repas copieux ne détruit pas vos progrès et ne stocke pas de graisse immédiate (l\'augmentation sur la balance est due au sodium et aux réserves de glycogène gorgées d\'eau). Ne sautez pas le repas suivant et ne compenser pas par un jeûne extrême. Reprenez simplement vos repas normaux et équilibrés.',
    ),
    RagDocument(
      id: 'doc_weekly_action_plan',
      title: 'Plan d\'Action Hebdomadaire Régulier',
      category: 'Plan d\'Action',
      keywords: ['plan', 'action', 'semaine', 'routine', 'programme', 'organisation', 'conseils', '7 jours'],
      content:
          'Pour réussir votre plan sur 7 jours : 1) Hydratez-vous avec 1.5L à 2L d\'eau/jour, 2) Atteignez 7 000 à 10 000 pas quotidiens ou 30 min de marche active, 3) Intégrez 20-30g de protéines à chaque repas, 4) Effectuez 2 à 3 pesées par semaine le matin à jeun pour suivre la moyenne.',
    ),
  ];

  /// Recherche dynamique dans la base RAG basée sur la fréquence et pertinence des termes.
  static List<RagDocument> search(String query, {int topK = 2}) {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sàâéèêëîïôùûç]'), ' ');

    final queryWords = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3)
        .toList();

    if (queryWords.isEmpty) return [];

    final scoredDocs = _documents.map((doc) {
      double score = 0;

      for (final word in queryWords) {
        // Mots-clés pertinents (poids très élevé)
        for (final kw in doc.keywords) {
          if (kw == word) {
            score += 5.0;
          } else if (kw.contains(word) || word.contains(kw)) {
            score += 2.5;
          }
        }

        // Match dans le titre
        if (doc.title.toLowerCase().contains(word)) {
          score += 4.0;
        }

        // Match dans le contenu
        if (doc.content.toLowerCase().contains(word)) {
          score += 1.5;
        }
      }

      return MapEntry(doc, score);
    }).toList();

    scoredDocs.sort((a, b) => b.value.compareTo(a.value));

    return scoredDocs
        .where((entry) => entry.value > 1.5)
        .map((entry) => entry.key)
        .take(topK)
        .toList();
  }
}
