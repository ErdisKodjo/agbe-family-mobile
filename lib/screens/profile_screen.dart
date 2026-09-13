/// Profil — identité, registre, changement de mot de passe, déconnexion.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/format.dart' as fmt;
import '../core/session.dart';
import '../core/theme.dart';
import '../models/member.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.moi});

  final Membre moi;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _changerMotDePasse() async {
    final session = context.read<SessionController>();
    final messenger = ScaffoldMessenger.of(context);
    final motDePasse = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogueMotDePasse(),
    );
    if (motDePasse == null) return;
    final parties = motDePasse.split('|');
    if (parties.length != 2) return;
    try {
      await session.changerMotDePasse(parties[0], parties[1]);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFF8B2E25)),
      );
    }
  }

  Future<void> _deconnecter() async {
    final session = context.read<SessionController>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez ressaisir votre téléphone et mot de passe à la prochaine connexion.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (confirme == true) session.deconnecter();
  }

  @override
  Widget build(BuildContext context) {
    final moi = widget.moi;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 14),
        children: [
          // ---- Identité ----
          Center(
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AgbeCouleurs.or, width: 2.5),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/logo-round.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  moi.nomComplet,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AgbeCouleurs.emeraudeProfond),
                ),
                const SizedBox(height: 3),
                Chip(
                  avatar: Icon(
                    moi.role == 'SUPER_ADMIN' ? Icons.admin_panel_settings_rounded : Icons.verified_user_rounded,
                    size: 16,
                    color: AgbeCouleurs.orFonce,
                  ),
                  label: Text(fmt.libelleRole(moi.role)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---- Informations ----
          const Titre('Informations'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Column(
              children: [
                _ligne(Icons.phone_rounded, 'Téléphone', moi.telephone),
                if (moi.ville != null && moi.ville!.isNotEmpty)
                  _ligne(Icons.location_on_outlined, 'Ville', moi.ville!),
                _ligne(Icons.hub_outlined, 'Registre', moi.nomRegistre.isEmpty ? 'Famille AGBÉ' : moi.nomRegistre),
              ],
            ),
          ),

          // ---- Actions ----
          const Titre('Sécurité & session'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password_rounded, color: AgbeCouleurs.emeraude),
                  title: const Text('Changer mon mot de passe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Session valable 7 jours', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _changerMotDePasse,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFB3261E)),
                  title: const Text('Se déconnecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFB3261E))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB3261E)),
                  onTap: _deconnecter,
                ),
              ],
            ),
          ),

          // ---- À propos ----
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                const Text(
                  '$appName · version 1.0.0',
                  style: TextStyle(fontSize: 11.5, color: AgbeCouleurs.ardoise),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connectée à : ${apiBaseUrl.replaceFirst('https://', '')}',
                  style: const TextStyle(fontSize: 10.5, color: AgbeCouleurs.ardoise),
                ),
                const SizedBox(height: 4),
                const Text(
                  motto,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AgbeCouleurs.orFonce),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligne(IconData icone, String libelle, String valeur) => Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE3EBE7))),
        ),
        child: ListTile(
          leading: Icon(icone, size: 20, color: AgbeCouleurs.emeraude),
          title: Text(libelle, style: const TextStyle(fontSize: 12, color: AgbeCouleurs.ardoise)),
          subtitle: Text(valeur, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      );
}

class Titre extends StatelessWidget {
  const Titre(this.libelle, {super.key});

  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
      child: Text(
        libelle.toUpperCase(),
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AgbeCouleurs.emeraudeProfond),
      ),
    );
  }
}

// ============================================================
// Dialogue « changer mot de passe » (deux champs)
// ============================================================

class _DialogueMotDePasse extends StatefulWidget {
  const _DialogueMotDePasse();

  @override
  State<_DialogueMotDePasse> createState() => _DialogueMotDePasseState();
}

class _DialogueMotDePasseState extends State<_DialogueMotDePasse> {
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  final _cle = GlobalKey<FormState>();

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer mon mot de passe'),
      content: Form(
        key: _cle,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _actuel,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
                validator: (v) => (v ?? '').isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nouveau,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nouveau (8 car. min.)'),
                validator: (v) {
                  if ((v ?? '').length < 8) return '8 caractères minimum';
                  if (v == _actuel.text) return 'Doit être différent';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmation,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmez'),
                validator: (v) => v != _nouveau.text ? 'Ne correspond pas' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () {
            if (_cle.currentState!.validate()) {
              Navigator.pop(context, '${_actuel.text}|${_nouveau.text}');
            }
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
