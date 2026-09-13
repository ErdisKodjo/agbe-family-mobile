/// Cotisations — campagnes actives, mes paiements, déclaration de paiement.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart' as fmt;
import '../core/session.dart';
import '../core/theme.dart';
import '../models/campaign.dart';
import '../models/payment.dart';
import '../widgets/shared.dart';
import 'declare_payment_screen.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _onglets = TabController(length: 2, vsync: this);
  Future<List<Campagne>>? _campagnesFuture;
  Future<List<Paiement>>? _paiementsFuture;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  void _recharger() {
    final api = context.read<ApiClient>();
    setState(() {
      _campagnesFuture = () async {
        final data = await api.get('/api/campaigns', query: {'status': 'ACTIVE'});
        return ((data as Map)['campaigns'] as List)
            .map(Campagne.fromJson)
            .toList(growable: false);
      }();
      _paiementsFuture = () async {
        final data = await api.get('/api/payments', query: {'mine': '1'});
        return ((data as Map)['payments'] as List)
            .map(Paiement.fromJson)
            .toList(growable: false);
      }();
    });
  }

  Future<void> _ouvrirDeclaration() async {
    final fait = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeclarePaymentScreen()),
    );
    if (fait == true) _recharger();
  }

  @override
  Widget build(BuildContext context) {
    final estAdmin = context.watch<SessionController>().estAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotisations'),
        bottom: TabBar(
          controller: _onglets,
          indicatorColor: AgbeCouleurs.or,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xB3FFFFFF),
          tabs: const [
            Tab(text: 'Campagnes en cours'),
            Tab(text: 'Mes paiements'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AgbeCouleurs.emeraude,
        foregroundColor: Colors.white,
        onPressed: _ouvrirDeclaration,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Déclarer'),
      ),
      body: TabBarView(
        controller: _onglets,
        children: [
          _ongletCampagnes(),
          _ongletMesPaiements(estAdmin),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Onglet campagnes
  // ----------------------------------------------------------

  Widget _ongletCampagnes() {
    return RefreshIndicator(
      onRefresh: () async => _recharger(),
      child: FutureBuilder<List<Campagne>>(
        future: _campagnesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return ListView(children: [const EtatChargement(hint: 'Chargement des campagnes…')]);
          }
          if (snap.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [EtatErreur(erreur: snap.error!, recharger: _recharger)],
            );
          }
          final campagnes = snap.data!;
          if (campagnes.isEmpty) {
            return ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                const EtatVide(
                  icone: Icons.campaign_outlined,
                  message: 'Aucune campagne active pour le moment.\nVotre tête de liste lancera les prochaines cotisations.',
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: campagnes.length,
            itemBuilder: (context, i) => _CarteCampagne(
              campagne: campagnes[i],
              onRefresh: _recharger,
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // Onglet mes paiements
  // ----------------------------------------------------------

  Widget _ongletMesPaiements(bool estAdmin) {
    return RefreshIndicator(
      onRefresh: () async => _recharger(),
      child: FutureBuilder<List<Paiement>>(
        future: _paiementsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return ListView(children: [const EtatChargement(hint: 'Chargement de vos paiements…')]);
          }
          if (snap.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [EtatErreur(erreur: snap.error!, recharger: _recharger)],
            );
          }
          final paiements = snap.data!;
          if (paiements.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EtatVide(
                  icone: Icons.receipt_long_rounded,
                  message: estAdmin
                      ? "Aucun paiement visible — les membres n'ont encore rien déclaré."
                      : "Vous n'avez encore déclaré aucun paiement.\nTouchez « Déclarer » pour envoyer votre preuve.",
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: paiements.length,
            itemBuilder: (context, i) => _LignePaiement(paiement: paiements[i]),
          );
        },
      ),
    );
  }
}

// ============================================================
// Carte campagne (avancement collecte + mes engagements)
// ============================================================

class _CarteCampagne extends StatelessWidget {
  const _CarteCampagne({required this.campagne, required this.onRefresh});

  final Campagne campagne;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final estMensuelle = campagne.type == 'MONTHLY';
    final cible = campagne.montantCible > 0 ? campagne.montantCible : campagne.attendu;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _details(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    estMensuelle ? Icons.event_repeat_rounded : Icons.volunteer_activism_rounded,
                    size: 20,
                    color: AgbeCouleurs.emeraude,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      campagne.nom,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      estMensuelle
                          ? (campagne.jourEcheance != null ? 'le ${campagne.jourEcheance} du mois' : 'Mensuelle')
                          : fmt.libellesTypeCampagne[campagne.type] ?? 'Occasionnelle',
                    ),
                  ),
                ],
              ),
              if (campagne.beneficiaire != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Pour ${campagne.beneficiaire}', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AgbeCouleurs.ardoise)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: BarreAvancement(avancement: campagne.avancement)),
                  const SizedBox(width: 10),
                  Text('${(campagne.avancement * 100).round()} %', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AgbeCouleurs.emeraude)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Collecté ${fmt.fcfa(campagne.collecte)}',
                    style: const TextStyle(fontSize: 12.5, color: AgbeCouleurs.ardoise),
                  ),
                  const Spacer(),
                  if (cible > 0)
                    Text(
                      'Objectif ${fmt.fcfa(cible)}',
                      style: const TextStyle(fontSize: 12.5, color: AgbeCouleurs.ardoise),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: AgbeCouleurs.emeraude),
                  const SizedBox(width: 4),
                  Text('${campagne.contributeurs} cotisant(s)', style: const TextStyle(fontSize: 12, color: AgbeCouleurs.ardoise)),
                  const SizedBox(width: 12),
                  if (campagne.paiementsEnAttente > 0) ...[
                    const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFF9A6700)),
                    const SizedBox(width: 4),
                    Text('${campagne.paiementsEnAttente} en attente', style: const TextStyle(fontSize: 12, color: Color(0xFF9A6700))),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _details(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          children: [
            Text(campagne.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (campagne.description != null && campagne.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(campagne.description!, style: const TextStyle(fontSize: 13.5, color: AgbeCouleurs.ardoise)),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                _cellule('Collecté', fmt.fcfa(campagne.collecte)),
                const SizedBox(width: 10),
                _cellule('Attendu', fmt.fcfa(campagne.attendu)),
                const SizedBox(width: 10),
                _cellule('Cotisants', '${campagne.contributeurs}'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('PARTICIPATION PAR MEMBRE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AgbeCouleurs.emeraudeProfond)),
            const SizedBox(height: 8),
            if (campagne.engagements.isEmpty)
              const Text('Aucun engagement enregistré.')
            else
              ...campagne.engagements.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.membre.nomComplet, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      if (e.reste > 0)
                        Text('reste ${fmt.fcfa(e.reste)}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF9A6700)))
                      else
                        const Icon(Icons.check_rounded, size: 17, color: AgbeCouleurs.emeraude),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context)
                    ..pop()
                    ..push(
                      MaterialPageRoute(builder: (_) => DeclarePaymentScreen(campagne: campagne)),
                    );
                },
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Déclarer mon paiement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cellule(String libelle, String valeur) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF3F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(valeur, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AgbeCouleurs.emeraude)),
              const SizedBox(height: 2),
              Text(libelle, style: const TextStyle(fontSize: 11, color: AgbeCouleurs.ardoise)),
            ],
          ),
        ),
      );
}

// ============================================================
// Ligne paiement (avec preuve consultable)
// ============================================================

class _LignePaiement extends StatelessWidget {
  const _LignePaiement({required this.paiement});

  final Paiement paiement;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return Card(
      child: ListTile(
        onTap: paiement.urlPreuve == null
            ? null
            : () => showDialog(
                context: context,
                builder: (_) => VisionneusePreuve(url: api.urlAbsolue(paiement.urlPreuve!)),
              ),
        leading: Icon(
          paiement.urlPreuve != null ? Icons.image_outlined : Icons.receipt_long_rounded,
          color: AgbeCouleurs.emeraude,
        ),
        title: Text(
          paiement.nomCampagne ?? 'Cotisation libre',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fmt.fcfa(paiement.montant)} · ${fmt.libelleMethode(paiement.methode)}', style: const TextStyle(fontSize: 12.5)),
            Text(
              paiement.valide
                  ? 'Validé le ${fmt.dateCourt(paiement.dateValidation)}'
                  : paiement.rejete
                      ? 'Rejeté${paiement.validateur != null ? ' par ${paiement.validateur}' : ''}'
                      : 'Déclaré ${fmt.ilYA(paiement.datePaiement)} · en attente de validation',
              style: TextStyle(
                fontSize: 11.5,
                color: paiement.valide ? AgbeCouleurs.emeraude : paiement.rejete ? const Color(0xFFB3261E) : const Color(0xFF9A6700),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PuceStatut.paiement(paiement.statut),
      ),
    );
  }
}
