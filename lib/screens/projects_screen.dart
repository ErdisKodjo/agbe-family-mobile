/// Projets — fiches projets, avancement, mes tâches (statut modifiable).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart' as fmt;
import '../core/session.dart';
import '../core/theme.dart';
import '../models/project.dart';
import '../widgets/shared.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  Future<List<Projet>>? _future;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  void _recharger() {
    final api = context.read<ApiClient>();
    final estAdmin = context.read<SessionController>().estAdmin;
    setState(() {
      // Membres : uniquement leurs projets ; admins : toute la famille.
      _future = () async {
        final query = estAdmin ? null : {'mine': '1'};
        final data = await api.get('/api/projects', query: query);
        return ((data as Map)['projects'] as List)
            .map(Projet.fromJson)
            .toList(growable: false);
      }();
    });
  }

  Future<void> _basculerTache(BuildContext context, TacheProjet t) async {
    final nouveau = t.faite
        ? 'TODO'
        : t.statut == 'IN_PROGRESS'
            ? 'DONE'
            : 'IN_PROGRESS';
    final api = context.read<ApiClient>();
    try {
      await api.patch('/api/tasks/${t.id}', body: {'status': nouveau});
      _recharger();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFF8B2E25)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projets familiaux')),
      body: RefreshIndicator(
        onRefresh: () async => _recharger(),
        child: FutureBuilder<List<Projet>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return ListView(children: [const EtatChargement(hint: 'Chargement des projets…')]);
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [EtatErreur(erreur: snap.error!, recharger: _recharger)],
              );
            }
            final projets = snap.data!;
            if (projets.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EtatVide(
                    icone: Icons.engineering_outlined,
                    message: 'Aucun projet ne vous concerne pour l\'instant.\nLes projets de la famille apparaîtront ici.',
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: projets.length,
              itemBuilder: (context, i) => _CarteProjet(
                projet: projets[i],
                onBascule: (t) => _basculerTache(context, t),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CarteProjet extends StatelessWidget {
  const _CarteProjet({required this.projet, required this.onBascule});

  final Projet projet;
  final void Function(TacheProjet) onBascule;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    projet.nom,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                ),
                PuceStatut.projet(projet.statut),
              ],
            ),
            if (projet.description != null && projet.description!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                projet.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AgbeCouleurs.ardoise),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: BarreAvancement(avancement: projet.avancement / 100, hauteur: 9)),
                const SizedBox(width: 10),
                Text('${projet.avancement} %', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AgbeCouleurs.emeraude)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (projet.budget > 0) ...[
                  const Icon(Icons.savings_outlined, size: 15, color: AgbeCouleurs.orFonce),
                  const SizedBox(width: 4),
                  Text('Budget ${fmt.fcfa(projet.budget)}', style: const TextStyle(fontSize: 12, color: AgbeCouleurs.ardoise)),
                  const SizedBox(width: 12),
                ],
                if (projet.maContribution > 0) ...[
                  const Icon(Icons.volunteer_activism_outlined, size: 15, color: AgbeCouleurs.emeraude),
                  const SizedBox(width: 4),
                  Text('Ma contribution ${fmt.fcfa(projet.maContribution)}', style: const TextStyle(fontSize: 12, color: AgbeCouleurs.ardoise)),
                ],
              ],
            ),
            if (projet.taches.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'TÂCHES (${projet.taches.where((t) => t.faite).length}/${projet.taches.length})',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: AgbeCouleurs.emeraudeProfond),
              ),
              const SizedBox(height: 4),
              for (final t in projet.taches)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onBascule(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                    child: Row(
                      children: [
                        _caseTache(t),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.titre,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  decoration: t.faite ? TextDecoration.lineThrough : null,
                                  color: t.faite ? AgbeCouleurs.ardoise : Colors.black87,
                                ),
                              ),
                              if (t.phase != null || t.echeance != null)
                                Text(
                                  [
                                    if (t.phase != null) t.phase!,
                                    if (t.echeance != null) 'échéance ${fmt.dateCourt(t.echeance)}',
                                  ].join(' · '),
                                  style: const TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise),
                                ),
                            ],
                          ),
                        ),
                        PuceStatut.tache(t.statut),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _caseTache(TacheProjet t) {
    final couleur = t.faite
        ? const Color(0xFF3B6E8F)
        : t.statut == 'IN_PROGRESS'
            ? AgbeCouleurs.or
            : const Color(0xFFE3EBE7);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.18),
        border: Border.all(color: couleur, width: 1.6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: t.faite
          ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF3B6E8F))
          : t.statut == 'IN_PROGRESS'
              ? const Icon(Icons.play_arrow_rounded, size: 16, color: AgbeCouleurs.orFonce)
              : null,
    );
  }
}
