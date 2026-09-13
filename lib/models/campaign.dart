/// Campagne de cotisation + situation du membre — /api/campaigns & /api/stats.
library;

import '../core/format.dart';
import 'member.dart';

class Engagement {
  Engagement({required this.membre, required this.montantDu, required this.montantPaye});

  final MembreRef membre;
  final num montantDu;
  final num montantPaye;

  num get reste => montantDu - montantPaye > 0 ? montantDu - montantPaye : 0;

  factory Engagement.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    return Engagement(
      membre: MembreRef.fromJson(m['member']),
      montantDu: num.tryParse(m['amountDue']?.toString() ?? '0') ?? 0,
      montantPaye: num.tryParse(m['amountPaid']?.toString() ?? '0') ?? 0,
    );
  }
}

class Campagne {
  Campagne({
    required this.id,
    required this.nom,
    required this.type,
    required this.statut,
    required this.montant,
    required this.montantCible,
    required this.attendu,
    required this.collecte,
    required this.contributeurs,
    required this.retardataires,
    required this.paiementsEnAttente,
    required this.dateFin,
    required this.jourEcheance,
    required this.description,
    required this.beneficiaire,
    required this.engagements,
  });

  final String id;
  final String nom;
  final String type; // MONTHLY | OCCASIONAL
  final String statut; // ACTIVE | CLOSED
  final num montant; // participation par membre
  final num montantCible; // objectif (appel à fonds)
  final num attendu; // somme des engagements
  final num collecte; // somme des paiements VALIDÉS
  final int contributeurs;
  final int retardataires;
  final int paiementsEnAttente;
  final DateTime? dateFin;
  final int? jourEcheance;
  final String? description;
  final String? beneficiaire;
  final List<Engagement> engagements;

  double get avancement =>
      attendu > 0 ? (collecte / attendu).clamp(0.0, 1.0) : 0.0;

  factory Campagne.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    return Campagne(
      id: m['id']?.toString() ?? '',
      nom: m['name']?.toString() ?? '',
      type: m['type']?.toString() ?? 'MONTHLY',
      statut: m['status']?.toString() ?? 'ACTIVE',
      montant: num.tryParse(m['amount']?.toString() ?? '0') ?? 0,
      montantCible: num.tryParse(m['targetAmount']?.toString() ?? '0') ?? 0,
      attendu: num.tryParse(m['expected']?.toString() ?? '0') ?? 0,
      collecte: num.tryParse(m['collected']?.toString() ?? '0') ?? 0,
      contributeurs: num.tryParse(m['contributorsCount']?.toString() ?? '0')?.toInt() ?? 0,
      retardataires: num.tryParse(m['lateCount']?.toString() ?? '0')?.toInt() ?? 0,
      paiementsEnAttente:
          num.tryParse(m['pendingPayments']?.toString() ?? '0')?.toInt() ?? 0,
      dateFin: parseDate(m['endDate']),
      jourEcheance: num.tryParse(m['dueDay']?.toString() ?? '')?.toInt(),
      description: m['description']?.toString(),
      beneficiaire: m['beneficiary'] == null
          ? null
          : MembreRef.fromJson(m['beneficiary']).nomComplet,
      engagements: (m['pledges'] as List? ?? [])
          .map(Engagement.fromJson)
          .toList(growable: false),
    );
  }
}

/// Ma situation sur une campagne active (définition /api/stats « member »).
class MaCampagne {
  MaCampagne({
    required this.campagneId,
    required this.nom,
    required this.type,
    required this.montantDu,
    required this.montantPaye,
    required this.reste,
    required this.dateFin,
    required this.jourEcheance,
  });

  final String campagneId;
  final String nom;
  final String type;
  final num montantDu;
  final num montantPaye;
  final num reste;
  final DateTime? dateFin;
  final int? jourEcheance;

  double get avancement =>
      montantDu > 0 ? (montantPaye / montantDu).clamp(0.0, 1.0) : 0.0;

  factory MaCampagne.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    final c = (m['campaign'] as Map?) ?? const {};
    return MaCampagne(
      campagneId: c['id']?.toString() ?? '',
      nom: c['name']?.toString() ?? '',
      type: c['type']?.toString() ?? 'MONTHLY',
      montantDu: num.tryParse(m['amountDue']?.toString() ?? '0') ?? 0,
      montantPaye: num.tryParse(m['amountPaid']?.toString() ?? '0') ?? 0,
      reste: num.tryParse(m['rest']?.toString() ?? '0') ?? 0,
      dateFin: parseDate(c['endDate']),
      jourEcheance: num.tryParse(c['dueDay']?.toString() ?? '')?.toInt(),
    );
  }
}
