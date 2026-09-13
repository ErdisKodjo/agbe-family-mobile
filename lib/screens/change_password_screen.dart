/// Changement de mot de passe — obligatoire à la première connexion.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _masque = true;

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _changer() async {
    if (!_formulaire.currentState!.validate()) return;
    final session = context.read<SessionController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await session.changerMotDePasse(_actuel.text, _nouveau.text);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour — bienvenue !')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFF8B2E25)),
      );
    }
  }

  InputDecoration _decoration(String libelle) => InputDecoration(
        labelText: libelle,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _masque = !_masque),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final moi = session.moi;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Sécurisez votre compte'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formulaire,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF3F0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.shield_outlined, size: 40, color: AgbeCouleurs.emeraude),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenue ${moi?.prenom ?? ''} !',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pour votre première connexion, choisissez un mot de passe personnel '
                          '(8 caractères minimum). Il remplace le mot de passe provisoire.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: AgbeCouleurs.ardoise),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _actuel,
                    obscureText: _masque,
                    decoration: _decoration('Mot de passe provisoire'),
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Le mot de passe actuel est requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nouveau,
                    obscureText: _masque,
                    decoration: _decoration('Nouveau mot de passe'),
                    validator: (v) {
                      final n = v ?? '';
                      if (n.length < 8) return '8 caractères minimum';
                      if (n == _actuel.text) return 'Doit être différent de l\'ancien';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmation,
                    obscureText: _masque,
                    decoration: _decoration('Confirmez le nouveau'),
                    validator: (v) =>
                        v != _nouveau.text ? 'Les deux mots de passe ne correspondent pas' : null,
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: session.occupe ? null : _changer,
                    child: session.occupe
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Text('Enregistrer et continuer'),
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
