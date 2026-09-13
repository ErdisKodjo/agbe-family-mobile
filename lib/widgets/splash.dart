/// Écran d'accueil (splash) — emblème AGBETOSSOU sur cuir émeraude.
library;

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';

class SplashAgbe extends StatelessWidget {
  const SplashAgbe({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: degradeEmeraude),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AgbeCouleurs.or, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 30, offset: Offset(0, 12)),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo-round.png',
                      width: 132,
                      height: 132,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  motto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AgbeCouleurs.or,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: AgbeCouleurs.or,
                    strokeWidth: 2.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
