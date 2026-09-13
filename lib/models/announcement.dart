/// Annonces de la famille — /api/announcements.
library;

import '../core/format.dart';

class Annonce {
  Annonce({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.globale,
    required this.date,
    required this.auteur,
    required this.roleAuteur,
    required this.nomRegistre,
  });

  final String id;
  final String titre;
  final String contenu;
  final bool globale;
  final DateTime? date;
  final String? auteur;
  final String? roleAuteur;
  final String? nomRegistre;

  factory Annonce.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    final auteur = (m['author'] as Map?) ?? const {};
    return Annonce(
      id: m['id']?.toString() ?? '',
      titre: m['title']?.toString() ?? '',
      contenu: m['content']?.toString() ?? '',
      globale: m['isGlobal'] == true,
      date: parseDate(m['createdAt']),
      auteur: auteur.isEmpty
          ? null
          : '${auteur['firstName']} ${auteur['lastName']}',
      roleAuteur: auteur['role']?.toString(),
      nomRegistre: m['registry'] == null ? null : m['registry']['name']?.toString(),
    );
  }
}
