// Tests — formatage FR (FCFA, dates, libellés).
import 'package:flutter_test/flutter_test.dart';
import 'package:agbe_family_mobile/core/format.dart' as fmt;

void main() {
  group('fcfa', () {
    test('milliers avec espaces', () {
      expect(fmt.fcfa(12500), '12 500 FCFA');
    });
    test('petits montants', () {
      expect(fmt.fcfa(0), '0 FCFA');
      expect(fmt.fcfa(999), '999 FCFA');
    });
    test('grands montants', () {
      expect(fmt.fcfa(1500000), '1 500 000 FCFA');
    });
    test('montant négatif (dépenses > recettes)', () {
      expect(fmt.fcfa(-4500).startsWith('−'), isTrue);
    });
  });

  group('parseDate (epoch-millis Prisma)', () {
    test('millisecondes → DateTime local', () {
      final d = fmt.parseDate(1789194090695);
      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 9);
      expect(d.day, 12);
    });
    test('null / vide → null', () {
      expect(fmt.parseDate(null), isNull);
      expect(fmt.parseDate(''), isNull);
    });
    test('ISO 8601 accepté', () {
      final d = fmt.parseDate('2026-09-12T06:21:30.000Z');
      expect(d, isNotNull);
      expect(d!.year, 2026);
    });
  });

  group('libellés métier', () {
    test('rôles', () {
      expect(fmt.libelleRole('SUPER_ADMIN'), 'Administrateur Général');
      expect(fmt.libelleRole('TREASURER'), 'Trésorier');
      expect(fmt.libelleRole('MEMBER'), 'Membre');
      expect(fmt.libelleRole(null), 'Membre');
    });
    test('droits admin', () {
      expect(fmt.estAdmin('SUPER_ADMIN'), isTrue);
      expect(fmt.estAdmin('HEAD'), isTrue);
      expect(fmt.estAdmin('TREASURER'), isTrue);
      expect(fmt.estAdmin('MEMBER'), isFalse);
      expect(fmt.estAdmin(null), isFalse);
    });
    test('méthodes de paiement', () {
      expect(fmt.libelleMethode('MOBILE_MONEY'), 'Mobile Money');
      expect(fmt.libelleMethode('CASH'), 'Espèces');
    });
  });

  group('dates françaises', () {
    test('date longue', () {
      final d = fmt.parseDate(1789194090695);
      expect(fmt.dateLong(d), contains('septembre'));
      expect(fmt.dateLong(d), contains('2026'));
    });
    test('relatif', () {
      expect(fmt.ilYA(DateTime.now()), "à l'instant");
      expect(fmt.ilYA(DateTime.now().subtract(const Duration(minutes: 5))), 'il y a 5 min');
    });
  });
}
