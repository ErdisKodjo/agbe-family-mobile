/// Connexion — hero « forêt & or » + formulaire téléphone / mot de passe.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/session.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _telephone = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _masque = true;

  @override
  void dispose() {
    _telephone.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formulaire.currentState!.validate()) return;
    final session = context.read<SessionController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await session.connecter(_telephone.text, _motDePasse.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFF8B2E25)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: degradeEmeraude),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formulaire,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- Emblème ----
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AgbeCouleurs.or, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x55000000), blurRadius: 30, offset: Offset(0, 12)),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo-round.png',
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          motto,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AgbeCouleurs.or,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // ---- Carte formulaire ----
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 34, offset: Offset(0, 16)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Connexion à votre espace',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AgbeCouleurs.emeraudeProfond),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Espace membre de la famille AGBETOSSOU',
                              style: TextStyle(fontSize: 13, color: AgbeCouleurs.ardoise),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _telephone,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                hintText: '+228 90 00 00 00',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return 'Votre numéro de téléphone est requis';
                                if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(t.replaceAll(RegExp(r'[\s().-]'), ''))) {
                                  return 'Numéro invalide (ex. : +22890101010)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _motDePasse,
                              obscureText: _masque,
                              enableSuggestions: false,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _seConnecter(),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _masque = !_masque),
                                ),
                              ),
                              validator: (v) =>
                                  (v ?? '').isEmpty ? 'Votre mot de passe est requis' : null,
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: session.occupe ? null : _seConnecter,
                              child: session.occupe
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                    )
                                  : const Text('Se connecter'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'Plateforme de Gestion Familiale — données protégées',
                          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
