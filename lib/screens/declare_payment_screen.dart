/// Déclaration de paiement — montant, méthode, référence + preuve photo.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart' as fmt;
import '../core/session.dart';
import '../core/theme.dart';
import '../models/campaign.dart';
import '../models/member.dart';

class DeclarePaymentScreen extends StatefulWidget {
  const DeclarePaymentScreen({super.key, this.campagne});

  final Campagne? campagne;

  @override
  State<DeclarePaymentScreen> createState() => _DeclarePaymentScreenState();
}

class _DeclarePaymentScreenState extends State<DeclarePaymentScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _montant = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();

  List<Campagne> _campagnes = [];
  Campagne? _campagne;
  String _methode = 'MOBILE_MONEY';
  File? _preuve;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _campagne = widget.campagne;
    if (_campagne != null) _campagnes = [_campagne!];
    _chargerCampagnes();
  }

  Future<void> _chargerCampagnes() async {
    if (widget.campagne != null) return;
    try {
      final api = context.read<ApiClient>();
      final data = await api.get('/api/campaigns', query: {'status': 'ACTIVE'});
      if (!mounted) return;
      setState(() {
        _campagnes = ((data as Map)['campaigns'] as List)
            .map(Campagne.fromJson)
            .toList(growable: false);
      });
    } on ApiException {
      // La déclaration sans campagne (cotisation libre) reste possible.
    }
  }

  num? _resteDu() {
    final moi = context.read<SessionController>().moi;
    final c = _campagne;
    if (moi == null || c == null) return null;
    final MembreRef moiRef = MembreRef(moi.id, moi.prenom, moi.nom);
    for (final e in c.engagements) {
      if (e.membre.id == moiRef.id && e.reste > 0) return e.reste;
    }
    return null;
  }

  Future<void> _choisirImage(ImageSource source) async {
    try {
      final fichier = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85, // JPEG compressé — reste < 8 Mo côté serveur
        maxWidth: 1600,
      );
      if (fichier == null) return;
      setState(() => _preuve = File(fichier.path));
    } catch (_) {
      setState(() => _erreur = 'Impossible d\'accéder à la photo.');
    }
  }

  Future<void> _envoyer() async {
    if (!_formulaire.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final api = context.read<ApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1) Preuve (facultative) → /api/upload
      String? preuveUrl;
      if (_preuve != null) {
        preuveUrl = await api.televerserPreuve(_preuve!.path);
      }

      // 2) Déclaration → /api/payments (statut PENDING, validation par un admin)
      await api.post('/api/payments', body: {
        'amount': num.tryParse(_montant.text.replaceAll(RegExp(r'[\s]'), '')) ?? 0,
        'campaignId': _campagne?.id,
        'method': _methode,
        'reference': _reference.text.trim().isEmpty ? null : _reference.text.trim(),
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'proofUrl': preuveUrl,
      });

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Paiement déclaré ! Un administrateur va le valider.'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  void dispose() {
    _montant.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reste = _resteDu();
    return Scaffold(
      appBar: AppBar(title: const Text('Déclarer un paiement')),
      body: SafeArea(
        child: Form(
          key: _formulaire,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF3F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AgbeCouleurs.emeraude, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Votre déclaration sera vérifiée par un administrateur avant d\'être portée en caisse.',
                        style: TextStyle(fontSize: 12.5, color: AgbeCouleurs.ardoise),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Campagne ----
              DropdownButtonFormField<Campagne>(
                initialValue: _campagne,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cotisation concernée',
                  prefixIcon: Icon(Icons.campaign_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Cotisation libre (sans campagne)')),
                  ..._campagnes.map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.nom, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (c) => setState(() {
                  _campagne = c;
                  final reste2 = c == null ? null : _montantSuggere(c);
                  if (reste2 != null && _montant.text.isEmpty) {
                    _montant.text = fmt.nombre(reste2);
                  }
                }),
              ),
              const SizedBox(height: 14),

              // ---- Montant ----
              TextFormField(
                controller: _montant,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant versé (FCFA)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: 'FCFA',
                  helperText: reste != null ? 'Reste dû suggéré : ${fmt.fcfa(reste)}' : null,
                ),
                validator: (v) {
                  final n = num.tryParse((v ?? '').replaceAll(RegExp(r'[\s]'), ''));
                  if (n == null || n <= 0) return 'Indiquez un montant valide';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ---- Méthode ----
              const Text('Moyen de paiement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AgbeCouleurs.ardoise)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in const ['MOBILE_MONEY', 'CASH', 'BANK', 'OTHER'])
                    ChoiceChip(
                      label: Text(fmt.libelleMethode(m)),
                      selected: _methode == m,
                      onSelected: (_) => setState(() => _methode = m),
                      selectedColor: AgbeCouleurs.emeraude.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _methode == m ? AgbeCouleurs.emeraude : AgbeCouleurs.ardoise,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Référence ----
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Référence / numéro de transaction (facultatif)',
                  prefixIcon: Icon(Icons.tag_rounded),
                  hintText: 'ex. : MP 240913.1432.A12345',
                ),
              ),
              const SizedBox(height: 14),

              // ---- Preuve photo ----
              Text.rich(
                TextSpan(
                  text: 'Preuve de paiement ',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AgbeCouleurs.ardoise),
                  children: const [
                    TextSpan(
                      text: '(recommandée — photo du reçu ou capture du Mobile Money)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_preuve == null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _choisirImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Caméra'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _choisirImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galerie'),
                      ),
                    ),
                  ],
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_preuve!, height: 190, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _preuve = null),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // ---- Note ----
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (facultative)',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                ),
              ),

              if (_erreur != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9E8E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_erreur!, style: const TextStyle(color: Color(0xFF8B2E25), fontSize: 13)),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _envoi ? null : _envoyer,
                child: _envoi
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Envoyer ma déclaration'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  num? _montantSuggere(Campagne c) {
    final moi = context.read<SessionController>().moi;
    if (moi == null) return null;
    for (final e in c.engagements) {
      if (e.membre.id == moi.id && e.reste > 0) return e.reste;
    }
    return c.montant > 0 ? c.montant : null;
  }
}
