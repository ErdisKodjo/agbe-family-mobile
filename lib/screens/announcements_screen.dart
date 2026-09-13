/// Annonces — fil d'informations de la famille (globales + registre).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/announcement.dart';
import '../widgets/shared.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  Future<List<Annonce>>? _future;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  void _recharger() {
    final api = context.read<ApiClient>();
    setState(() {
      _future = () async {
        final data = await api.get('/api/announcements');
        return ((data as Map)['announcements'] as List)
            .map(Annonce.fromJson)
            .toList(growable: false);
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Annonces')),
      body: RefreshIndicator(
        onRefresh: () async => _recharger(),
        child: FutureBuilder<List<Annonce>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return ListView(children: [const EtatChargement(hint: 'Chargement des annonces…')]);
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [EtatErreur(erreur: snap.error!, recharger: _recharger)],
              );
            }
            final annonces = snap.data!;
            if (annonces.isEmpty) {
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  const EtatVide(
                    icone: Icons.campaign_outlined,
                    message: 'Aucune annonce pour le moment.\nLes communications de la famille s\'afficheront ici.',
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: annonces.length,
              itemBuilder: (context, i) => _CarteAnnonce(annonce: annonces[i]),
            );
          },
        ),
      ),
    );
  }
}

class _CarteAnnonce extends StatelessWidget {
  const _CarteAnnonce({required this.annonce});

  final Annonce annonce;

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AgbeCouleurs.emeraude.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, size: 18, color: AgbeCouleurs.emeraude),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    annonce.titre,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              annonce.contenu,
              style: const TextStyle(fontSize: 13.5, height: 1.45, color: AgbeCouleurs.ardoise),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (annonce.globale)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AgbeCouleurs.or.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Toute la famille',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AgbeCouleurs.orFonce),
                    ),
                  )
                else if (annonce.nomRegistre != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(annonce.nomRegistre!, style: const TextStyle(fontSize: 10.5)),
                  ),
                Text(
                  '${annonce.auteur ?? 'Administration'} · ${fmt.ilYA(annonce.date)}',
                  style: const TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
