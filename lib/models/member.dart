/// Membre AGBE Family — miroir des réponses /api/auth/*.
library;

class Membre {
  Membre({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.telephone,
    required this.role,
    required this.registreId,
    required this.nomRegistre,
    required this.doitChangerMdp,
    this.ville,
  });

  final String id;
  final String prenom;
  final String nom;
  final String telephone;
  final String role; // SUPER_ADMIN | HEAD | TREASURER | MEMBER
  final String registreId;
  final String nomRegistre;
  final bool doitChangerMdp;
  final String? ville;

  String get nomComplet => '$prenom $nom';

  factory Membre.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    return Membre(
      id: m['id']?.toString() ?? '',
      prenom: m['firstName']?.toString() ?? '',
      nom: m['lastName']?.toString() ?? '',
      telephone: m['phone']?.toString() ?? '',
      role: m['role']?.toString() ?? 'MEMBER',
      registreId: m['registryId']?.toString() ?? '',
      nomRegistre: m['registryName']?.toString() ?? '',
      doitChangerMdp: m['mustChangePassword'] == true,
      ville: m['city']?.toString(),
    );
  }
}

/// Référence compacte d'un membre (listes de preuves, engagements…).
class MembreRef {
  MembreRef(this.id, this.prenom, this.nom, {this.telephone});

  final String id;
  final String prenom;
  final String nom;
  final String? telephone;

  String get nomComplet => '$prenom $nom';

  factory MembreRef.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    return MembreRef(
      m['id']?.toString() ?? '',
      m['firstName']?.toString() ?? '',
      m['lastName']?.toString() ?? '',
      telephone: m['phone']?.toString(),
    );
  }
}
