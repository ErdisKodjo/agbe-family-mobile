/// AGBE Family (PGF) — application mobile Flutter.
///
/// Client mobile de la Plateforme de Gestion Familiale AGBETOSSOU,
/// connecté à l'API de production hébergée sur Railway.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'screens/app_shell.dart';
import 'screens/change_password_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => SessionController(api)..demarrer()),
      ],
      child: const AgbeFamilyApp(),
    ),
  );
}

class AgbeFamilyApp extends StatelessWidget {
  const AgbeFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: agbeThemeClair(),
      home: const _Routeur(),
    );
  }
}

class _Routeur extends StatelessWidget {
  const _Routeur();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    switch (session.etat) {
      case EtatSession.demarrage:
        return const SplashAgbe();
      case EtatSession.deconnecte:
        return const LoginScreen();
      case EtatSession.connecte:
        final moi = session.moi!;
        if (moi.doitChangerMdp) return const ChangePasswordScreen();
        return const AppShell();
    }
  }
}
