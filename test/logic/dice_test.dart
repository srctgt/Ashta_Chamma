import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/logic/dice.dart';

void main() {
  group('Dice - Cowrie Shell Mode', () {
    test('cowrieValueFromMouthUp returns correct values', () {
      expect(Dice.cowrieValueFromMouthUp(0), 8); // Ashta
      expect(Dice.cowrieValueFromMouthUp(1), 1);
      expect(Dice.cowrieValueFromMouthUp(2), 2);
      expect(Dice.cowrieValueFromMouthUp(3), 3);
      expect(Dice.cowrieValueFromMouthUp(4), 4); // Chamma
    });

    test('cowrie shell roll produces only valid values (1, 2, 3, 4, 8)', () {
      final dice = Dice(mode: DiceMode.cowrieShells);
      final validValues = {1, 2, 3, 4, 8};

      for (int i = 0; i < 1000; i++) {
        final result = dice.roll();
        expect(validValues.contains(result.value), isTrue,
            reason: 'Got invalid value: ${result.value}');
      }
    });

    test('cowrie shell provides shell results', () {
      final dice = Dice(mode: DiceMode.cowrieShells);
      final result = dice.roll();
      expect(result.shellResults, isNotNull);
      expect(result.shellResults!.length, 4);
    });

    test('value 4 (Chamma) grants bonus turn', () {
      final result = Dice.cowrieResult(4);
      expect(result.grantsBonusTurn, isTrue);
      expect(result.allowsEntry, isTrue);
    });

    test('value 8 (Ashta) grants bonus turn', () {
      final result = Dice.cowrieResult(8);
      expect(result.grantsBonusTurn, isTrue);
      expect(result.allowsEntry, isTrue);
    });

    test('values 1, 2, 3 do not grant bonus turn', () {
      for (final value in [1, 2, 3]) {
        final result = Dice.cowrieResult(value);
        expect(result.grantsBonusTurn, isFalse,
            reason: 'Value $value should not grant bonus');
        expect(result.allowsEntry, isFalse,
            reason: 'Value $value should not allow entry');
      }
    });

    test('cowrieResult asserts on invalid values', () {
      expect(() => Dice.cowrieResult(5), throwsA(isA<AssertionError>()));
      expect(() => Dice.cowrieResult(0), throwsA(isA<AssertionError>()));
      expect(() => Dice.cowrieResult(6), throwsA(isA<AssertionError>()));
      expect(() => Dice.cowrieResult(7), throwsA(isA<AssertionError>()));
    });

    test('seeded random produces deterministic results', () {
      final dice1 = Dice(mode: DiceMode.cowrieShells, random: Random(42));
      final dice2 = Dice(mode: DiceMode.cowrieShells, random: Random(42));

      for (int i = 0; i < 100; i++) {
        expect(dice1.roll().value, dice2.roll().value);
      }
    });

    test('all values are achievable with enough rolls', () {
      final dice = Dice(mode: DiceMode.cowrieShells);
      final seenValues = <int>{};

      for (int i = 0; i < 10000; i++) {
        seenValues.add(dice.roll().value);
        if (seenValues.length == 5) break;
      }

      expect(seenValues, containsAll([1, 2, 3, 4, 8]));
    });
  });

  group('Dice - Regular Dice Mode', () {
    test('regular dice produces values 1-6', () {
      final dice = Dice(mode: DiceMode.regularDice);

      for (int i = 0; i < 1000; i++) {
        final result = dice.roll();
        expect(result.value, greaterThanOrEqualTo(1));
        expect(result.value, lessThanOrEqualTo(6));
      }
    });

    test('regular dice does not provide shell results', () {
      final dice = Dice(mode: DiceMode.regularDice);
      final result = dice.roll();
      expect(result.shellResults, isNull);
    });

    test('value 6 grants bonus turn for regular dice', () {
      final result = Dice.regularResult(6);
      expect(result.grantsBonusTurn, isTrue);
      expect(result.allowsEntry, isTrue);
    });

    test('values 1-5 do not grant bonus turn for regular dice', () {
      for (int value = 1; value <= 5; value++) {
        final result = Dice.regularResult(value);
        expect(result.grantsBonusTurn, isFalse,
            reason: 'Value $value should not grant bonus');
        expect(result.allowsEntry, isFalse,
            reason: 'Value $value should not allow entry');
      }
    });

    test('all values 1-6 are achievable', () {
      final dice = Dice(mode: DiceMode.regularDice);
      final seenValues = <int>{};

      for (int i = 0; i < 10000; i++) {
        seenValues.add(dice.roll().value);
        if (seenValues.length == 6) break;
      }

      expect(seenValues, containsAll([1, 2, 3, 4, 5, 6]));
    });
  });

  group('Dice - Bonus Turn Logic', () {
    test('isBonusTurnValue works for cowrie mode', () {
      expect(Dice.isBonusTurnValue(1, DiceMode.cowrieShells), isFalse);
      expect(Dice.isBonusTurnValue(2, DiceMode.cowrieShells), isFalse);
      expect(Dice.isBonusTurnValue(3, DiceMode.cowrieShells), isFalse);
      expect(Dice.isBonusTurnValue(4, DiceMode.cowrieShells), isTrue);
      expect(Dice.isBonusTurnValue(8, DiceMode.cowrieShells), isTrue);
    });

    test('isBonusTurnValue works for regular dice mode', () {
      expect(Dice.isBonusTurnValue(1, DiceMode.regularDice), isFalse);
      expect(Dice.isBonusTurnValue(5, DiceMode.regularDice), isFalse);
      expect(Dice.isBonusTurnValue(6, DiceMode.regularDice), isTrue);
    });

    test('isEntryValue works for cowrie mode', () {
      expect(Dice.isEntryValue(1, DiceMode.cowrieShells), isFalse);
      expect(Dice.isEntryValue(2, DiceMode.cowrieShells), isFalse);
      expect(Dice.isEntryValue(3, DiceMode.cowrieShells), isFalse);
      expect(Dice.isEntryValue(4, DiceMode.cowrieShells), isTrue);
      expect(Dice.isEntryValue(8, DiceMode.cowrieShells), isTrue);
    });

    test('isEntryValue works for regular dice mode', () {
      expect(Dice.isEntryValue(1, DiceMode.regularDice), isFalse);
      expect(Dice.isEntryValue(5, DiceMode.regularDice), isFalse);
      expect(Dice.isEntryValue(6, DiceMode.regularDice), isTrue);
    });
  });
}
