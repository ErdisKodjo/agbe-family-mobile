/// Formatage — montants FCFA, dates françaises, libellés métier.
///
/// Implémentation volontairement autonome (aucune dépendance intl) :
/// la famille AGBE est francophone, l'app est 100 % FR.
library;

const List<String> _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

const List<String> _moisCourts = [
  'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
  'juil', 'août', 'sep', 'oct', 'nov', 'déc',
];

/// « 12 500 FCFA » — séparateur de milliers espace fine.
String fcfa(num montant) {
  final n = montant.round();
  final signe = n < 0 ? '−' : '';
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final posFromRight = s.length - i;
    buf.write(s[i]);
    if (posFromRight > 1 && (posFromRight - 1) % 3 == 0) buf.write(' ');
  }
  return '$signe${buf.toString()} FCFA';
}

/// « 12500 » (sans devise, pour les champs numériques).
String nombre(num montant) => montant.round().toString();

DateTime? parseDate(dynamic valeur) {
  if (valeur == null) return null;
  if (valeur is DateTime) return valeur;
  final s = valeur.toString();
  if (s.isEmpty) return null;
  final ms = int.tryParse(s);
  if (ms != null) {
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.tryParse(s)?.toLocal();
}

/// « 12 septembre 2026 »
String dateLong(dynamic valeur) {
  final d = parseDate(valeur);
  if (d == null) return '—';
  return '${d.day} ${_mois[d.month - 1]} ${d.year}';
}

/// « 12 sept. 2026 »
String dateCourt(dynamic valeur) {
  final d = parseDate(valeur);
  if (d == null) return '—';
  return '${d.day} ${_moisCourts[d.month - 1]}. ${d.year}';
}

/// « 12 sept. · 14:05 »
String dateHeure(dynamic valeur) {
  final d = parseDate(valeur);
  if (d == null) return '—';
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_moisCourts[d.month - 1]}. · $h:$m';
}

/// « il y a 3 h » / « il y a 2 j » / « à l'instant »
String ilYA(dynamic valeur) {
  final d = parseDate(valeur);
  if (d == null) return '—';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 30) return 'il y a ${diff.inDays} j';
  return dateCourt(d);
}

// ============================================================
// Libellés métier (alignés sur src/lib/constants.ts du web)
// ============================================================

const String roleSuperAdmin = 'SUPER_ADMIN';
const String roleHead = 'HEAD';
const String roleTreasurer = 'TREASURER';
const String roleMember = 'MEMBER';

bool estAdmin(String? role) =>
    role == roleSuperAdmin || role == roleHead || role == roleTreasurer;

String libelleRole(String? role) {
  switch (role) {
    case roleSuperAdmin:
      return 'Administrateur Général';
    case roleHead:
      return 'Tête de Liste';
    case roleTreasurer:
      return 'Trésorier';
    default:
      return 'Membre';
  }
}

String libelleMethode(String? methode) {
  switch (methode) {
    case 'MOBILE_MONEY':
      return 'Mobile Money';
    case 'CASH':
      return 'Espèces';
    case 'BANK':
      return 'Virement bancaire';
    default:
      return 'Autre';
  }
}

const Map<String, String> libellesStatutPaiement = {
  'PENDING': 'En attente',
  'VALIDATED': 'Validé',
  'REJECTED': 'Rejeté',
};

const Map<String, String> libellesStatutTache = {
  'TODO': 'À faire',
  'IN_PROGRESS': 'En cours',
  'DONE': 'Terminée',
};

const Map<String, String> libellesStatutProjet = {
  'PLANNED': 'Planifié',
  'IN_PROGRESS': 'En cours',
  'SUSPENDED': 'Suspendu',
  'DONE': 'Terminé',
};

const Map<String, String> libellesTypeCampagne = {
  'MONTHLY': 'Mensuelle',
  'OCCASIONAL': 'Appel à fonds',
};

String libelleMoisCourt(int mois) =>
    (mois >= 1 && mois <= 12) ? _moisCourts[mois - 1] : '—';
