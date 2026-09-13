/// Bibliothèque de widgets partagés — cartes KPI, statuts, sections.
library;

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';

// ============================================================
// Cartes KPI
// ============================================================

class CarteKpi extends StatelessWidget {
  const CarteKpi({
    super.key,
    required this.libelle,
    required this.valeur,
    required this.icone,
    this.accent,
    this.sousLibelle,
    this.onTap,
  });

  final String libelle;
  final String valeur;
  final IconData icone;
  final Color? accent;
  final String? sousLibelle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final couleur = accent ?? AgbeCouleurs.emeraude;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icone, size: 18, color: couleur),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      libelle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AgbeCouleurs.ardoise),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valeur,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: couleur,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (sousLibelle != null) ...[
                const SizedBox(height: 3),
                Text(
                  sousLibelle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AgbeCouleurs.ardoise),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Puce de statut (paiement, tâche, projet, campagne)
// ============================================================

enum _Style { paiement, tache, projet }

class PuceStatut extends StatelessWidget {
  const PuceStatut.paiement(this.statut, {super.key}) : _style = _Style.paiement;
  const PuceStatut.tache(this.statut, {super.key}) : _style = _Style.tache;
  const PuceStatut.projet(this.statut, {super.key}) : _style = _Style.projet;

  final String statut;
  final _Style _style;

  @override
  Widget build(BuildContext context) {
    final (libelle, couleur) = switch (_style) {
      _Style.paiement => switch (statut) {
          'PENDING' => ('En attente', const Color(0xFF9A6700)),
          'VALIDATED' => ('Validé', const Color(0xFF0D5C46)),
          'REJECTED' => ('Rejeté', const Color(0xFFB3261E)),
          _ => (statut, AgbeCouleurs.ardoise),
        },
      _Style.tache => switch (statut) {
          'TODO' => ('À faire', const Color(0xFF9A6700)),
          'IN_PROGRESS' => ('En cours', const Color(0xFF0D5C46)),
          'DONE' => ('Terminée', const Color(0xFF3B6E8F)),
          _ => (statut, AgbeCouleurs.ardoise),
        },
      _Style.projet => switch (statut) {
          'PLANNED' => ('Planifié', const Color(0xFF9A6700)),
          'IN_PROGRESS' => ('En cours', const Color(0xFF0D5C46)),
          'SUSPENDED' => ('Suspendu', const Color(0xFFB3261E)),
          'DONE' => ('Terminé', const Color(0xFF3B6E8F)),
          _ => (statut, AgbeCouleurs.ardoise),
        },
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        libelle,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: couleur),
      ),
    );
  }
}

// ============================================================
// Titre de section
// ============================================================

class TitreSection extends StatelessWidget {
  const TitreSection(this.libelle, {super.key, this.action});

  final String libelle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AgbeCouleurs.or,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              libelle.toUpperCase(),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AgbeCouleurs.emeraudeProfond,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

// ============================================================
// États : chargement / erreur / vide
// ============================================================

class EtatChargement extends StatelessWidget {
  const EtatChargement({super.key, this.hint});

  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.4),
            if (hint case final h?) ...[
              const SizedBox(height: 14),
              Text(h, style: const TextStyle(fontSize: 13, color: AgbeCouleurs.ardoise)),
            ],
          ],
        ),
      ),
    );
  }
}

class EtatErreur extends StatelessWidget {
  const EtatErreur({super.key, required this.erreur, required this.recharger});

  final Object erreur;
  final VoidCallback recharger;

  @override
  Widget build(BuildContext context) {
    final message = erreur is ApiException ? erreur.toString() : 'Une erreur inattendue est survenue.';
    final expiree = erreur is ApiException && (erreur as ApiException).estAuthExpiree;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44, color: AgbeCouleurs.ardoise),
            const SizedBox(height: 12),
            Text(
              expiree ? 'Session expirée — reconnectez-vous.' : message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AgbeCouleurs.ardoise),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: expiree ? null : recharger,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class EtatVide extends StatelessWidget {
  const EtatVide({super.key, required this.icone, required this.message});

  final IconData icone;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 46, color: AgbeCouleurs.emeraude.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AgbeCouleurs.ardoise),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Barre d'avancement dorée
// ============================================================

class BarreAvancement extends StatelessWidget {
  const BarreAvancement({super.key, required this.avancement, this.hauteur = 8});

  final double avancement;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: hauteur,
        child: LinearProgressIndicator(
          value: avancement,
          minHeight: hauteur,
          backgroundColor: const Color(0xFFE3EBE7),
          valueColor: const AlwaysStoppedAnimation<Color>(AgbeCouleurs.or),
        ),
      ),
    );
  }
}

// ============================================================
// Visionneuse de preuve (plein écran)
// ============================================================

class VisionneusePreuve extends StatelessWidget {
  const VisionneusePreuve({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 4,
            child: Center(child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 60, color: Colors.white54))),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
