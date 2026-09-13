/// Statistiques des tableaux de bord — GET /api/stats (scope admin ou membre).
library;

import '../core/format.dart';
import 'campaign.dart';
import 'payment.dart';
import 'project.dart';

class ActiviteRecente {
  ActiviteRecente({required this.auteur, required this.action, required this.details, required this.date});

  final String? auteur;
  final String action; // LOGIN | CREATE | VALIDATE | UPDATE | DELETE | LOGOUT…
  final String details;
  final DateTime? date;

  factory ActiviteRecente.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    final membre = (m['member'] as Map?) ?? const {};
    return ActiviteRecente(
      auteur: membre.isEmpty ? null : '${membre['firstName']} ${membre['lastName']}',
      action: m['action']?.toString() ?? '',
      details: m['details']?.toString() ?? '',
      date: parseDate(m['createdAt']),
    );
  }
}

class StatistiquesAdmin {
  StatistiquesAdmin({
    required this.totalMembres,
    required this.membresActifs,
    required this.nombreRegistres,
    required this.projetsEnCours,
    required this.solde,
    required this.totalRecettes,
    required this.totalDepenses,
    required this.recettesDuMois,
    required this.paiementsEnAttente,
    required this.totalCollecte,
    required this.mois,
    required this.campagneMensuelle,
    required this.activiteRecente,
  });

  final int totalMembres;
  final int membresActifs;
  final int nombreRegistres;
  final int projetsEnCours;
  final num solde;
  final num totalRecettes;
  final num totalDepenses;
  final num recettesDuMois;
  final int paiementsEnAttente;
  final num totalCollecte;
  final List<FluxMensuel> mois;
  final CampagneMensuelleStat? campagneMensuelle;
  final List<ActiviteRecente> activiteRecente;

  factory StatistiquesAdmin.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    final k = (m['kpis'] as Map?) ?? const {};
    final monthlyStatus = m['monthlyStatus'] as Map?;
    return StatistiquesAdmin(
      totalMembres: num.tryParse(k['totalMembers']?.toString() ?? '0')?.toInt() ?? 0,
      membresActifs: num.tryParse(k['activeMembers']?.toString() ?? '0')?.toInt() ?? 0,
      nombreRegistres: num.tryParse(k['registriesCount']?.toString() ?? '0')?.toInt() ?? 0,
      projetsEnCours: num.tryParse(k['activeProjects']?.toString() ?? '0')?.toInt() ?? 0,
      solde: num.tryParse(k['balance']?.toString() ?? '0') ?? 0,
      totalRecettes: num.tryParse(k['totalIncome']?.toString() ?? '0') ?? 0,
      totalDepenses: num.tryParse(k['totalExpense']?.toString() ?? '0') ?? 0,
      recettesDuMois: num.tryParse(k['monthCollected']?.toString() ?? '0') ?? 0,
      paiementsEnAttente: num.tryParse(k['pendingPayments']?.toString() ?? '0')?.toInt() ?? 0,
      totalCollecte: num.tryParse(k['totalCollected']?.toString() ?? '0') ?? 0,
      mois: (m['months'] as List? ?? []).map(FluxMensuel.fromJson).toList(growable: false),
      campagneMensuelle: monthlyStatus == null
          ? null
          : CampagneMensuelleStat.fromJson(monthlyStatus),
      activiteRecente: (m['recentActivity'] as List? ?? [])
          .map(ActiviteRecente.fromJson)
          .toList(growable: false),
    );
  }
}

class FluxMensuel {
  FluxMensuel({required this.libelle, required this.recettes, required this.depenses});

  final String libelle;
  final num recettes;
  final num depenses;

  factory FluxMensuel.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    return FluxMensuel(
      libelle: m['label']?.toString() ?? '',
      recettes: num.tryParse(m['income']?.toString() ?? '0') ?? 0,
      depenses: num.tryParse(m['expense']?.toString() ?? '0') ?? 0,
    );
  }
}

class CampagneMensuelleStat {
  CampagneMensuelleStat({
    required this.nom,
    required this.montant,
    required this.attendu,
    required this.collecte,
    required this.payeurs,
    required this.totalEngages,
  });

  final String nom;
  final num montant;
  final num attendu;
  final num collecte;
  final int payeurs;
  final int totalEngages;

  double get avancement =>
      attendu > 0 ? (collecte / attendu).clamp(0.0, 1.0) : 0.0;

  factory CampagneMensuelleStat.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    return CampagneMensuelleStat(
      nom: m['name']?.toString() ?? '',
      montant: num.tryParse(m['amount']?.toString() ?? '0') ?? 0,
      attendu: num.tryParse(m['expected']?.toString() ?? '0') ?? 0,
      collecte: num.tryParse(m['collected']?.toString() ?? '0') ?? 0,
      payeurs: num.tryParse(m['paidCount']?.toString() ?? '0')?.toInt() ?? 0,
      totalEngages: num.tryParse(m['totalMembers']?.toString() ?? '0')?.toInt() ?? 0,
    );
  }
}

class StatistiquesMembre {
  StatistiquesMembre({
    required this.totalPaye,
    required this.totalDu,
    required this.resteAPayer,
    required this.mesPaiementsEnAttente,
    required this.nombreProjets,
    required this.tachesOuvertes,
    required this.mesContributionsProjets,
    required this.mesCampagnes,
    required this.mesTaches,
    required this.mesProjets,
    required this.paiementsRecents,
  });

  final num totalPaye;
  final num totalDu;
  final num resteAPayer;
  final int mesPaiementsEnAttente;
  final int nombreProjets;
  final int tachesOuvertes;
  final num mesContributionsProjets;
  final List<MaCampagne> mesCampagnes;
  final List<TacheProjet> mesTaches;
  final List<Projet> mesProjets;
  final List<Paiement> paiementsRecents;

  factory StatistiquesMembre.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    final k = (m['kpis'] as Map?) ?? const {};
    return StatistiquesMembre(
      totalPaye: num.tryParse(k['totalPaid']?.toString() ?? '0') ?? 0,
      totalDu: num.tryParse(k['totalDue']?.toString() ?? '0') ?? 0,
      resteAPayer: num.tryParse(k['restToPay']?.toString() ?? '0') ?? 0,
      mesPaiementsEnAttente: num.tryParse(k['pendingMine']?.toString() ?? '0')?.toInt() ?? 0,
      nombreProjets: num.tryParse(k['myProjectsCount']?.toString() ?? '0')?.toInt() ?? 0,
      tachesOuvertes: num.tryParse(k['myOpenTasks']?.toString() ?? '0')?.toInt() ?? 0,
      mesContributionsProjets:
          num.tryParse(k['myProjectContributions']?.toString() ?? '0') ?? 0,
      mesCampagnes: (m['myCampaigns'] as List? ?? [])
          .map(MaCampagne.fromJson)
          .toList(growable: false),
      mesTaches: (m['myTasks'] as List? ?? [])
          .map(TacheProjet.fromJson)
          .toList(growable: false),
      mesProjets: (m['myProjects'] as List? ?? [])
          .map(Projet.fromJson)
          .toList(growable: false),
      paiementsRecents: (m['recentPayments'] as List? ?? [])
          .map(Paiement.fromJson)
          .toList(growable: false),
    );
  }
}

/// Dispatch scope admin/membre.
class Statistiques {
  Statistiques._(this.admin, this.membre);

  final StatistiquesAdmin? admin;
  final StatistiquesMembre? membre;

  factory Statistiques.fromJson(dynamic json) {
    final m = (json as Map?) ?? const {};
    if (m['scope'] == 'admin') {
      return Statistiques._(StatistiquesAdmin.fromJson(m), null);
    }
    return Statistiques._(null, StatistiquesMembre.fromJson(m));
  }
}
