/// Projets familiaux, phases et tâches — /api/projects, /api/stats.
library;

import '../core/format.dart';

class TacheProjet {
  TacheProjet({
    required this.id,
    required this.titre,
    required this.statut,
    required this.assigne,
    required this.phase,
    required this.projet,
    required this.echeance,
    required this.description,
  });

  final String id;
  final String titre;
  final String statut; // TODO | IN_PROGRESS | DONE
  final String? assigne;
  final String? phase;
  final String? projet;
  final DateTime? echeance;
  final String? description;

  bool get faite => statut == 'DONE';

  factory TacheProjet.fromJson(dynamic json, {String? nomProjet}) {
    final m = (json as Map?) ?? const {};
    return TacheProjet(
      id: m['id']?.toString() ?? '',
      titre: m['title']?.toString() ?? '',
      statut: m['status']?.toString() ?? 'TODO',
      assigne: m['assignee'] == null
          ? null
          : '${m['assignee']['firstName']} ${m['assignee']['lastName']}',
      phase: m['phase'] == null ? null : m['phase']['name']?.toString(),
      projet: nomProjet ?? (m['project'] == null ? null : m['project']['name']?.toString()),
      echeance: parseDate(m['dueDate']),
      description: m['description']?.toString(),
    );
  }
}

class Projet {
  Projet({
    required this.id,
    required this.nom,
    required this.description,
    required this.statut,
    required this.avancement,
    required this.maContribution,
    required this.taches,
    required this.nomRegistre,
    required this.budget,
    required this.dateFin,
  });

  final String id;
  final String nom;
  final String? description;
  final String statut; // PLANNED | IN_PROGRESS | SUSPENDED | DONE
  final int avancement; // % (moyenne des phases)
  final num maContribution;
  final List<TacheProjet> taches;
  final String? nomRegistre;
  final num budget;
  final DateTime? dateFin;

  factory Projet.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    final phases = m['phases'] as List? ?? const [];
    final avancement = phases.isNotEmpty
        ? (phases.fold<num>(0, (s, ph) => s + (num.tryParse((ph as Map)['progress']?.toString() ?? '0') ?? 0)) / phases.length).round()
        : 0;
    return Projet(
      id: m['id']?.toString() ?? '',
      nom: m['name']?.toString() ?? '',
      description: m['description']?.toString(),
      statut: m['status']?.toString() ?? 'PLANNED',
      avancement: avancement,
      maContribution: _maContribution(m),
      taches: (m['tasks'] as List? ?? [])
          .map((t) => TacheProjet.fromJson(t, nomProjet: m['name']?.toString()))
          .toList(growable: false),
      nomRegistre: m['registry'] == null ? null : m['registry']['name']?.toString(),
      budget: num.tryParse(m['budget']?.toString() ?? '0') ?? 0,
      dateFin: parseDate(m['endDate']),
    );
  }

  static num _maContribution(Map m) {
    // /api/projects inclut les contributions complètes ; /api/stats « member »
    // renvoie myContribution (numérique) — on gère les deux formes.
    if (m['myContribution'] != null) {
      return num.tryParse(m['myContribution'].toString()) ?? 0;
    }
    final contributions = m['contributions'] as List? ?? const [];
    return contributions.fold<num>(
      0,
      (s, c) => s + (num.tryParse((c as Map)['amount']?.toString() ?? '0') ?? 0),
    );
  }
}
