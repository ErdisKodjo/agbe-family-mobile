/// Paiement (déclaration de cotisation) — /api/payments.
library;

import '../core/format.dart';
import 'member.dart';

class Paiement {
  Paiement({
    required this.id,
    required this.montant,
    required this.methode,
    required this.statut,
    required this.datePaiement,
    required this.membre,
    required this.nomCampagne,
    required this.reference,
    required this.note,
    required this.urlPreuve,
    required this.dateValidation,
    required this.validateur,
  });

  final String id;
  final num montant;
  final String methode; // MOBILE_MONEY | CASH | BANK | OTHER
  final String statut; // PENDING | VALIDATED | REJECTED
  final DateTime? datePaiement;
  final MembreRef membre;
  final String? nomCampagne;
  final String? reference;
  final String? note;
  final String? urlPreuve;
  final DateTime? dateValidation;
  final String? validateur;

  bool get enAttente => statut == 'PENDING';
  bool get valide => statut == 'VALIDATED';
  bool get rejete => statut == 'REJECTED';

  factory Paiement.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    return Paiement(
      id: m['id']?.toString() ?? '',
      montant: num.tryParse(m['amount']?.toString() ?? '0') ?? 0,
      methode: m['method']?.toString() ?? 'MOBILE_MONEY',
      statut: m['status']?.toString() ?? 'PENDING',
      datePaiement: parseDate(m['paidAt']),
      membre: MembreRef.fromJson(m['member']),
      nomCampagne: m['campaign'] == null ? null : m['campaign']['name']?.toString(),
      reference: m['reference']?.toString(),
      note: m['note']?.toString(),
      urlPreuve: m['proofUrl']?.toString(),
      dateValidation: parseDate(m['validatedAt']),
      validateur: m['validatedBy'] == null
          ? null
          : MembreRef.fromJson(m['validatedBy']).nomComplet,
    );
  }
}
