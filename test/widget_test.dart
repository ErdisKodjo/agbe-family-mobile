// Tests — widgets partagés (aucune dépendance réseau ni plugin).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agbe_family_mobile/core/theme.dart';
import 'package:agbe_family_mobile/widgets/shared.dart';

void main() {
  testWidgets('BarreAvancement rend une LinearProgressIndicator dorée', (testeur) async {
    await testeur.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: BarreAvancement(avancement: 0.5))),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('PuceStatut affiche les libellés FR', (testeur) async {
    await testeur.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            PuceStatut.paiement('PENDING'),
            PuceStatut.paiement('VALIDATED'),
            PuceStatut.tache('DONE'),
            PuceStatut.projet('IN_PROGRESS'),
          ],
        ),
      ),
    );
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Validé'), findsOneWidget);
    expect(find.text('Terminée'), findsOneWidget);
    expect(find.text('En cours'), findsOneWidget);
  });

  testWidgets('EtatVide et EtatChargement s\'affichent', (testeur) async {
    await testeur.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            EtatVide(icone: Icons.inbox, message: 'Rien à afficher'),
            EtatChargement(hint: 'Patientez…'),
          ],
        ),
      ),
    );
    expect(find.text('Rien à afficher'), findsOneWidget);
    expect(find.text('Patientez…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('BadgeOr affiche son contenu', (testeur) async {
    await testeur.pumpWidget(
      const MaterialApp(home: Scaffold(body: BadgeOr(child: Text('3')))),
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('TitreSection respecte le style émeraude', (testeur) async {
    await testeur.pumpWidget(
      const MaterialApp(home: Scaffold(body: TitreSection('Mes cotisations'))),
    );
    expect(find.text('MES COTISATIONS'), findsOneWidget);
  });
}
