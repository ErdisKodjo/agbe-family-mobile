/// Accueil — tableau de bord selon le rôle (admin KPIs / espace membre).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart' as fmt;
import '../core/session.dart';
import '../core/theme.dart';
import '../models/member.dart';
import '../models/project.dart';
import '../models/stats.dart';
import '../widgets/shared.dart';
import 'payments_validation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<Statistiques>? _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<Statistiques> _charger() async {
    final api = context.read<ApiClient>();
    final data = await api.get('/api/stats');
    return Statistiques.fromJson(data);
  }

  void _recharger() => setState(() => _future = _charger());

  @override
  Widget build(BuildContext context) {
    final moi = context.watch<SessionController>().moi!;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _recharger(),
        child: FutureBuilder<Statistiques>(
          key: ValueKey('stats-${moi.id}'),
          future: _future,
          builder: (context, snap) {
            return CustomScrollView(
              slivers: [
                _Entete(moi: moi),
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                  const SliverFillRemaining(child: EtatChargement(hint: 'Chargement de votre tableau de bord…'))
                else if (snap.hasError)
                  SliverFillRemaining(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [EtatErreur(erreur: snap.error!, recharger: _recharger)],
                    ),
                  )
                else if (snap.data!.admin != null)
                  _accueilAdmin(context, snap.data!.admin!)
                else
                  _accueilMembre(context, snap.data!.membre!),
                const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // ACCUEIL ADMIN
  // ==========================================================

  Widget _accueilAdmin(BuildContext context, StatistiquesAdmin stats) {
    return SliverList.list(
      children: [
        // --- Alerte paiements en attente ---
        if (stats.paiementsEnAttente > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Card(
              color: AgbeCouleurs.emeraudeProfond,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaymentsValidationScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.task_alt_rounded, color: AgbeCouleurs.or, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stats.paiementsEnAttente} paiement(s) à valider',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const Text(
                              'Vérifiez les preuves et encaissez',
                              style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AgbeCouleurs.or),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // --- KPIs ---
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.72,
            children: [
              CarteKpi(libelle: 'Membres', valeur: '${stats.totalMembres}', icone: Icons.groups_rounded, sousLibelle: '${stats.membresActifs} actifs'),
              CarteKpi(libelle: 'Solde trésorerie', valeur: fmt.fcfa(stats.solde), icone: Icons.account_balance_wallet_rounded, accent: const Color(0xFF3B6E8F)),
              CarteKpi(libelle: 'Recettes du mois', valeur: fmt.fcfa(stats.recettesDuMois), icone: Icons.trending_up_rounded, accent: const Color(0xFF0D5C46)),
              CarteKpi(libelle: 'Projets en cours', valeur: '${stats.projetsEnCours}', icone: Icons.engineering_rounded),
              CarteKpi(libelle: 'Total collecté', valeur: fmt.fcfa(stats.totalCollecte), icone: Icons.savings_rounded, accent: AgbeCouleurs.orFonce),
              CarteKpi(libelle: 'Registres', valeur: '${stats.nombreRegistres}', icone: Icons.hub_rounded),
            ],
          ),
        ),

        // --- Campagne mensuelle ---
        if (stats.campagneMensuelle != null) ..._carteCampagneMensuelle(stats.campagneMensuelle!),

        // --- Flux 6 mois ---
        const TitreSection('Flux de trésorerie — 6 derniers mois'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in stats.mois)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _BarresMois(flux: m),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30, bottom: 4),
          child: Row(
            children: [
              _legende(AgbeCouleurs.or, 'Recettes'),
              const SizedBox(width: 14),
              _legende(const Color(0xFFB3261E), 'Dépenses'),
            ],
          ),
        ),

        // --- Activité récente ---
        const TitreSection('Activité récente'),
        if (stats.activiteRecente.isEmpty)
          const EtatVide(icone: Icons.history_rounded, message: 'Aucune activité enregistrée pour le moment.')
        else
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Column(
              children: [
                for (var i = 0; i < stats.activiteRecente.length; i++)
                  _ligneActivite(stats.activiteRecente[i], i == 0),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _carteCampagneMensuelle(CampagneMensuelleStat c) {
    return [
      TitreSection(
        'Cotisation du mois',
        action: BadgeOr(child: Text('${c.payeurs}/${c.totalEngages} payés')),
      ),
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: BarreAvancement(avancement: c.avancement, hauteur: 10)),
                  const SizedBox(width: 10),
                  Text(
                    '${(c.avancement * 100).round()} %',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AgbeCouleurs.emeraude),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Collecté : ${fmt.fcfa(c.collecte)}', style: const TextStyle(fontSize: 12.5, color: AgbeCouleurs.ardoise)),
                  Text('Attendu : ${fmt.fcfa(c.attendu)}', style: const TextStyle(fontSize: 12.5, color: AgbeCouleurs.ardoise)),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _ligneActivite(ActiviteRecente a, bool premier) {
    return Container(
      decoration: BoxDecoration(
        border: premier ? null : const Border(top: BorderSide(color: Color(0xFFE3EBE7))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(_iconeAction(a.action), size: 20, color: AgbeCouleurs.emeraude),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${a.auteur ?? 'Système'} · ${fmt.ilYA(a.date)}',
                  style: const TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconeAction(String action) {
    switch (action) {
      case 'LOGIN':
        return Icons.login_rounded;
      case 'LOGOUT':
        return Icons.logout_rounded;
      case 'VALIDATE':
        return Icons.check_circle_outline;
      case 'REJECT':
        return Icons.cancel_outlined;
      case 'CREATE':
        return Icons.add_circle_outline;
      case 'DELETE':
        return Icons.delete_outline;
      default:
        return Icons.update_rounded;
    }
  }

  Widget _legende(Color couleur, String libelle) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(libelle, style: const TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise)),
      ],
    );
  }

  // ==========================================================
  // ACCUEIL MEMBRE
  // ==========================================================

  Widget _accueilMembre(BuildContext context, StatistiquesMembre stats) {
    return SliverList.list(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.72,
            children: [
              CarteKpi(libelle: 'Total cotisé', valeur: fmt.fcfa(stats.totalPaye), icone: Icons.volunteer_activism_rounded),
              CarteKpi(
                libelle: 'Reste à payer',
                valeur: fmt.fcfa(stats.resteAPayer),
                icone: Icons.schedule_rounded,
                accent: stats.resteAPayer > 0 ? const Color(0xFF9A6700) : const Color(0xFF0D5C46),
                sousLibelle: 'sur ${fmt.fcfa(stats.totalDu)} attendus',
              ),
              CarteKpi(
                libelle: 'Mes paiements en attente',
                valeur: '${stats.mesPaiementsEnAttente}',
                icone: Icons.hourglass_top_rounded,
                accent: const Color(0xFF9A6700),
              ),
              CarteKpi(
                libelle: 'Mes projets · tâches',
                valeur: '${stats.nombreProjets} · ${stats.tachesOuvertes}',
                icone: Icons.engineering_rounded,
              ),
            ],
          ),
        ),

        if (stats.mesCampagnes.isNotEmpty) ...[
          const TitreSection('Mes cotisations en cours'),
          for (final mc in stats.mesCampagnes)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mc.nom,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mc.reste <= 0)
                          const PuceStatut.paiement('VALIDATED')
                        else
                          BadgeOr(child: Text('reste ${fmt.fcfa(mc.reste)}')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BarreAvancement(avancement: mc.avancement),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payé ${fmt.fcfa(mc.montantPaye)} / ${fmt.fcfa(mc.montantDu)}',
                          style: const TextStyle(fontSize: 12.5, color: AgbeCouleurs.ardoise),
                        ),
                        if (mc.dateFin != null)
                          Text('jusqu\'au ${fmt.dateCourt(mc.dateFin)}', style: const TextStyle(fontSize: 12, color: AgbeCouleurs.ardoise)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],

        if (stats.mesTaches.isNotEmpty) ...[
          const TitreSection('Mes tâches'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Column(
              children: [
                for (var i = 0; i < stats.mesTaches.length && i < 6; i++)
                  _ligneTache(stats.mesTaches[i], i == 0),
              ],
            ),
          ),
        ],

        const TitreSection('Mes derniers paiements'),
        if (stats.paiementsRecents.isEmpty)
          const EtatVide(icone: Icons.receipt_long_rounded, message: 'Aucun paiement déclaré pour le moment.\nUtilisez le bouton « Déclarer un paiement ».')
        else
          for (final p in stats.paiementsRecents.take(6))
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: AgbeCouleurs.emeraude),
                title: Text(p.nomCampagne ?? 'Cotisation libre', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: Text('${fmt.fcfa(p.montant)} · ${fmt.dateHeure(p.datePaiement)}', style: const TextStyle(fontSize: 12.5)),
                trailing: PuceStatut.paiement(p.statut),
              ),
            ),
      ],
    );
  }

  Widget _ligneTache(TacheProjet t, bool premier) {
    return Container(
      decoration: BoxDecoration(
        border: premier ? null : const Border(top: BorderSide(color: Color(0xFFE3EBE7))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: t.faite ? const Color(0xFF3B6E8F) : const Color(0xFF9A6700)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(
                  '${t.projet ?? ''}${t.echeance != null ? ' · échéance ${fmt.dateCourt(t.echeance)}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// En-tête « forêt & or »
// ============================================================

class _Entete extends StatelessWidget {
  const _Entete({required this.moi});

  final Membre moi;

  @override
  Widget build(BuildContext context) {
    final heure = DateTime.now().hour;
    final salutation = heure < 12
        ? 'Bonjour'
        : heure < 18
            ? 'Bon après-midi'
            : 'Bonsoir';
    return SliverAppBar(
      pinned: false,
      floating: true,
      expandedHeight: 128,
      collapsedHeight: 66,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: degradeEmeraude),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$salutation, ${moi.prenom} 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.hub_outlined, size: 14, color: AgbeCouleurs.or),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${moi.nomRegistre.isEmpty ? "Famille AGBÉ" : moi.nomRegistre} · ${fmt.libelleRole(moi.role)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Mini bar-chart « recettes / dépenses » par mois
// ============================================================

class _BarresMois extends StatelessWidget {
  const _BarresMois({required this.flux});

  final FluxMensuel flux;

  @override
  Widget build(BuildContext context) {
    final maxVal = (flux.recettes + flux.depenses).toDouble();
    final hRec = maxVal <= 0 ? 0.0 : flux.recettes / maxVal;
    final hDep = maxVal <= 0 ? 0.0 : flux.depenses / maxVal;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 84,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (flux.recettes > 0)
                Container(
                  width: 11,
                  height: (84 * hRec).clamp(4.0, 84.0).toDouble(),
                  decoration: BoxDecoration(
                    color: AgbeCouleurs.or,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              if (flux.recettes > 0 && flux.depenses > 0) const SizedBox(width: 4),
              if (flux.depenses > 0)
                Container(
                  width: 11,
                  height: (84 * hDep).clamp(4.0, 84.0).toDouble(),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3261E),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              if (flux.recettes <= 0 && flux.depenses <= 0)
                Container(width: 11, height: 4, color: const Color(0xFFE3EBE7)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(flux.libelle, style: const TextStyle(fontSize: 10.5, color: AgbeCouleurs.ardoise)),
      ],
    );
  }
}
