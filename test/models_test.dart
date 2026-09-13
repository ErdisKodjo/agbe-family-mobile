// Tests — analyse des réponses JSON de l'API (formes exactes du serveur).
import 'package:flutter_test/flutter_test.dart';
import 'package:agbe_family_mobile/core/format.dart' as fmt;
import 'package:agbe_family_mobile/models/campaign.dart';
import 'package:agbe_family_mobile/models/member.dart';
import 'package:agbe_family_mobile/models/payment.dart';
import 'package:agbe_family_mobile/models/stats.dart';

void main() {
  group('Membre (login / me)', () {
    test('champs complets', () {
      final m = Membre.fromJson({
        'id': 'cmabc',
        'firstName': 'Fiotefe',
        'lastName': 'Kodjo',
        'phone': '+22891978838',
        'city': null,
        'role': 'SUPER_ADMIN',
        'registryId': 'r1',
        'registryName': 'Famille AGBÉ — Registre Racine',
        'mustChangePassword': false,
      });
      expect(m.nomComplet, 'Fiotefe Kodjo');
      expect(fmt.estAdmin(m.role), isTrue);
      expect(m.doitChangerMdp, isFalse);
    });
    test('JSON vide ne casse pas', () {
      final m = Membre.fromJson(null);
      expect(m.role, 'MEMBER');
    });
  });

  group('Paiement', () {
    test('forme /api/payments (avec preuve et campagne)', () {
      final p = Paiement.fromJson({
        'id': 'pay1',
        'amount': 5000,
        'method': 'MOBILE_MONEY',
        'status': 'PENDING',
        'paidAt': 1789194090695,
        'reference': 'MP123',
        'note': 'Mois de septembre',
        'proofUrl': '/api/files/123-abc.jpg',
        'validatedAt': null,
        'validatedBy': null,
        'member': {'id': 'm1', 'firstName': 'Awa', 'lastName': 'Kodjo', 'phone': '+22890000000'},
        'campaign': {'id': 'c1', 'name': 'Cotisation mensuelle', 'type': 'MONTHLY'},
      });
      expect(p.enAttente, isTrue);
      expect(p.nomCampagne, 'Cotisation mensuelle');
      expect(p.urlPreuve, '/api/files/123-abc.jpg');
      expect(p.membre.nomComplet, 'Awa Kodjo');
    });
  });

  group('Campagne', () {
    test('avancement et engagements', () {
      final c = Campagne.fromJson({
        'id': 'c1',
        'name': 'Août 2026',
        'type': 'MONTHLY',
        'status': 'ACTIVE',
        'amount': 5000,
        'targetAmount': 0,
        'expected': 10000,
        'collected': 5000,
        'contributorsCount': 1,
        'lateCount': 1,
        'pendingPayments': 1,
        'dueDay': 5,
        'endDate': null,
        'description': null,
        'beneficiary': null,
        'pledges': [
          {
            'memberId': 'm1',
            'member': {'id': 'm1', 'firstName': 'Awa', 'lastName': 'Kodjo'},
            'amountDue': 5000,
            'amountPaid': 5000,
          },
          {
            'memberId': 'm2',
            'member': {'id': 'm2', 'firstName': 'Koffi', 'lastName': 'Agbé'},
            'amountDue': 5000,
            'amountPaid': 0,
          },
        ],
      });
      expect(c.avancement, 0.5);
      expect(c.engagements.length, 2);
      expect(c.engagements[0].reste, 0);
      expect(c.engagements[1].reste, 5000);
      expect(c.retardataires, 1);
    });
  });

  group('Statistiques', () {
    test('scope membre', () {
      final s = Statistiques.fromJson({
        'scope': 'member',
        'kpis': {
          'totalPaid': 15000,
          'totalDue': 20000,
          'restToPay': 5000,
          'pendingMine': 1,
          'myProjectsCount': 2,
          'myOpenTasks': 3,
          'myProjectContributions': 0,
        },
        'myCampaigns': [
          {
            'campaign': {'id': 'c1', 'name': 'Septembre 2026', 'type': 'MONTHLY', 'dueDay': 5, 'endDate': null},
            'amountDue': 5000,
            'amountPaid': 2000,
            'rest': 3000,
          }
        ],
        'myTasks': [],
        'myProjects': [],
        'recentPayments': [],
      });
      expect(s.membre, isNotNull);
      expect(s.admin, isNull);
      expect(s.membre!.resteAPayer, 5000);
      expect(s.membre!.mesCampagnes.first.reste, 3000);
    });

    test('scope admin', () {
      final s = Statistiques.fromJson({
        'scope': 'admin',
        'kpis': {
          'totalMembers': 1,
          'activeMembers': 1,
          'registriesCount': 1,
          'activeProjects': 0,
          'balance': 0,
          'totalIncome': 0,
          'totalExpense': 0,
          'monthCollected': 0,
          'pendingPayments': 2,
          'totalCollected': 0,
        },
        'months': [
          {'label': 'août', 'income': 100, 'expense': 50}
        ],
        'monthlyStatus': null,
        'recentActivity': [],
        'catIncomes': [],
      });
      expect(s.admin, isNotNull);
      expect(s.admin!.paiementsEnAttente, 2);
      expect(s.admin!.mois.first.recettes, 100);
    });
  });
}
