/// Validation des paiements (admin) — preuves, encaissement, rejet.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/payment.dart';
import '../widgets/shared.dart';

class PaymentsValidationScreen extends StatefulWidget {
  const PaymentsValidationScreen({super.key});

  @override
  State<PaymentsValidationScreen> createState() => _PaymentsValidationScreenState();
}

class _PaymentsValidationScreenState extends State<PaymentsValidationScreen> {
  Future<List<Paiement>>? _future;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  void _recharger() {
    final api = context.read<ApiClient>();
    setState(() {
      _future = () async {
        final data = await api.get('/api/payments', query: {'status': 'PENDING'});
        return ((data as Map)['payments'] as List)
            .map(Paiement.fromJson)
            .toList(growable: false);
      }();
    });
  }

  Future<void> _traiter(Paiement paiement, String action) async {
    final verbe = action == 'VALIDATED' ? 'valider' : 'rejeter';
    final api = context.read<ApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${verbe[0].toUpperCase()}${verbe.substring(1)} ce paiement ?'),
        content: Text(
          '${paiement.membre.nomComplet} · ${fmt.fcfa(paiement.montant)}\n'
          '${paiement.nomCampagne ?? 'Cotisation libre'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: action == 'REJECTED'
                ? FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E))
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(verbe[0].toUpperCase() + verbe.substring(1)),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      // VALIDATED → la trésorerie du registre est créditée automatiquement.
      await api.patch('/api/payments/${paiement.id}', body: {'action': action});
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            action == 'VALIDATED'
                ? 'Paiement validé — recette portée en caisse.'
                : 'Paiement rejeté.',
          ),
        ),
      );
      _recharger();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFF8B2E25)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements à valider')),
      body: RefreshIndicator(
        onRefresh: () async => _recharger(),
        child: FutureBuilder<List<Paiement>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return ListView(children: [const EtatChargement(hint: 'Chargement des déclarations…')]);
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
                children: const [
                  EtatVide(
                    icone: Icons.task_alt_rounded,
                    message: 'Aucune déclaration en attente.\nTout est à jour, bravo !',
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              itemCount: paiements.length,
              itemBuilder: (context, i) => _CarteValidation(
                paiement: paiements[i],
                onValider: () => _traiter(paiements[i], 'VALIDATED'),
                onRejeter: () => _traiter(paiements[i], 'REJECTED'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CarteValidation extends StatelessWidget {
  const _CarteValidation({
    required this.paiement,
    required this.onValider,
    required this.onRejeter,
  });

  final Paiement paiement;
  final VoidCallback onValider;
  final VoidCallback onRejeter;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AgbeCouleurs.emeraude.withValues(alpha: 0.12),
                  child: Text(
                    _initiales(paiement.membre.nomComplet),
                    style: const TextStyle(color: AgbeCouleurs.emeraude, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paiement.membre.nomComplet,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${paiement.membre.telephone} · déclaré ${fmt.ilYA(paiement.datePaiement)}',
                        style: const TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmt.fcfa(paiement.montant),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AgbeCouleurs.emeraude),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.campaign_outlined, size: 14, color: AgbeCouleurs.emeraude),
                  label: Text(paiement.nomCampagne ?? 'Cotisation libre', style: const TextStyle(fontSize: 11)),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AgbeCouleurs.emeraude),
                  label: Text(fmt.libelleMethode(paiement.methode), style: const TextStyle(fontSize: 11)),
                ),
                if (paiement.reference != null && paiement.reference!.isNotEmpty)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.tag_rounded, size: 14, color: AgbeCouleurs.orFonce),
                    label: Text(paiement.reference!, style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            if (paiement.note != null && paiement.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '« ${paiement.note} »',
                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AgbeCouleurs.ardoise),
              ),
            ],
            const SizedBox(height: 12),

            // ---- Preuve ----
            if (paiement.urlPreuve != null)
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => VisionneusePreuve(url: api.urlAbsolue(paiement.urlPreuve!)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      api.urlAbsolue(paiement.urlPreuve!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFEDF3F0),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, size: 30, color: AgbeCouleurs.ardoise),
                            SizedBox(height: 4),
                            Text('Preuve illisible — touchez pour réessayer', style: TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, size: 18, color: Color(0xFF9A6700)),
                    SizedBox(width: 8),
                    Text('Aucune preuve jointe', style: TextStyle(fontSize: 12.5, color: Color(0xFF9A6700), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // ---- Actions ----
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRejeter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB3261E),
                      side: const BorderSide(color: Color(0xFFB3261E)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Rejeter'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onValider,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Valider & encaisser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initiales(String nomComplet) {
    final parties = nomComplet.split(' ');
    if (parties.length < 2) return nomComplet.substring(0, 1).toUpperCase();
    return (parties[0][0] + parties[1][0]).toUpperCase();
  }
}
