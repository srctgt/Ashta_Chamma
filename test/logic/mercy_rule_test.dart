import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/logic/dice.dart';
import 'package:ashta_chamma/logic/game_controller.dart';
import 'package:ashta_chamma/logic/game_state.dart';
import 'package:ashta_chamma/models/pawn.dart';
import 'package:ashta_chamma/models/player.dart';

void main() {
  group('Mercy Rule - GameController', () {
    test('tracks consecutive non-entry rolls for a player', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
      );

      // Player 1 rolls a non-entry value (switches to player 2)
      controller.rollDiceWithResult(Dice.cowrieResult(2));
      expect(controller.getConsecutiveNonEntryRolls(1), 1);
    });

    test('resets counter when entry value is rolled', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
      );

      // Player 1 rolls non-entry, then player 2 rolls non-entry
      controller.rollDiceWithResult(Dice.cowrieResult(1)); // P1 -> switch to P2
      controller.rollDiceWithResult(Dice.cowrieResult(3)); // P2 -> switch to P1
      expect(controller.getConsecutiveNonEntryRolls(1), 1);

      // Player 1 rolls entry value (4) - counter should reset
      controller.rollDiceWithResult(Dice.cowrieResult(4)); // P1 gets entry
      expect(controller.getConsecutiveNonEntryRolls(1), 0);
    });

    test('counter increments across multiple turns for same player', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
      );

      // Both players start with all pawns at start.
      // Non-entry rolls just switch turns.
      controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1
      expect(controller.getConsecutiveNonEntryRolls(1), 1);

      controller.rollDiceWithResult(Dice.cowrieResult(1)); // P2
      expect(controller.getConsecutiveNonEntryRolls(2), 1);

      controller.rollDiceWithResult(Dice.cowrieResult(3)); // P1
      expect(controller.getConsecutiveNonEntryRolls(1), 2);

      controller.rollDiceWithResult(Dice.cowrieResult(2)); // P2
      expect(controller.getConsecutiveNonEntryRolls(2), 2);

      controller.rollDiceWithResult(Dice.cowrieResult(1)); // P1
      expect(controller.getConsecutiveNonEntryRolls(1), 3);
    });

    test('forces entry roll after 5 consecutive non-entry rolls', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
        random: Random(42),
      );

      // Build up 5 consecutive non-entry rolls for player 1.
      // Non-entry rolls switch turns, so we alternate P1 and P2.
      for (int i = 0; i < 5; i++) {
        controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1 non-entry
        controller.rollDiceWithResult(Dice.cowrieResult(1)); // P2 non-entry
      }

      expect(controller.getConsecutiveNonEntryRolls(1), 5);
      expect(controller.state.currentPlayerId, 1);
      expect(controller.state.phase, GamePhase.rolling);

      // Now player 1 rolls - mercy rule should activate
      final result = controller.rollDice();
      expect(result, isNotNull);
      expect(result!.allowsEntry, isTrue);
      expect(result.value == 4 || result.value == 8, isTrue);
    });

    test('mercy rule resets counter after forced entry roll', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
        random: Random(42),
      );

      // Build up 5 non-entry rolls for player 1
      for (int i = 0; i < 5; i++) {
        controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1
        controller.rollDiceWithResult(Dice.cowrieResult(3)); // P2
      }

      expect(controller.getConsecutiveNonEntryRolls(1), 5);

      // Mercy rule kicks in
      controller.rollDice();
      expect(controller.getConsecutiveNonEntryRolls(1), 0);
    });

    test('mercy rule does not activate when player has pawns on board', () {
      // Create a state where player 1 has a pawn on board
      final player1 = Player(
        id: 1,
        pawns: [
          const Pawn(
              player: 1,
              pawnIndex: 0,
              state: PawnState.onBoard,
              stepsCompleted: 3),
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
      );

      final state = GameState(
        player1: player1,
        player2: Player(id: 2),
        currentPlayerId: 1,
        diceMode: DiceMode.cowrieShells,
      );

      final controller = GameController.withState(
        state: state,
        gameMode: GameMode.humanVsHuman,
        random: Random(42),
      );

      // Roll non-entry values many times - counter should not increment
      // because player has pawns on board
      controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1 - has pawn on board, can move
      expect(controller.getConsecutiveNonEntryRolls(1), 0);
    });

    test('mercy rule applies to both players equally', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
        random: Random(42),
      );

      // Build up 5 non-entry rolls for both players
      for (int i = 0; i < 5; i++) {
        controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1
        controller.rollDiceWithResult(Dice.cowrieResult(3)); // P2
      }

      expect(controller.getConsecutiveNonEntryRolls(1), 5);
      expect(controller.getConsecutiveNonEntryRolls(2), 5);

      // Player 1's turn - mercy rule activates
      final result1 = controller.rollDice();
      expect(result1!.allowsEntry, isTrue);
      expect(controller.getConsecutiveNonEntryRolls(1), 0);
    });

    test('does not activate when less than 5 consecutive non-entry rolls', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
        random: Random(0),
      );

      // Roll only 4 non-entry values for player 1
      for (int i = 0; i < 4; i++) {
        controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1
        controller.rollDiceWithResult(Dice.cowrieResult(1)); // P2
      }

      expect(controller.getConsecutiveNonEntryRolls(1), 4);

      // Player 1 rolls again - mercy rule should NOT activate,
      // so if we provide a non-entry, it stays non-entry
      final result = controller.rollDiceWithResult(Dice.cowrieResult(3));
      expect(result!.value, 3);
      expect(controller.getConsecutiveNonEntryRolls(1), 5);
    });

    test('reset clears mercy rule counters', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
      );

      // Build up some non-entry rolls
      controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1
      controller.rollDiceWithResult(Dice.cowrieResult(1)); // P2
      expect(controller.getConsecutiveNonEntryRolls(1), 1);
      expect(controller.getConsecutiveNonEntryRolls(2), 1);

      controller.reset();
      expect(controller.getConsecutiveNonEntryRolls(1), 0);
      expect(controller.getConsecutiveNonEntryRolls(2), 0);
    });

    test('counter resets when player no longer needs entry (pawn moved to board by other means)', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsHuman,
      );

      // Build up 3 non-entry rolls for player 1
      for (int i = 0; i < 3; i++) {
        controller.rollDiceWithResult(Dice.cowrieResult(2)); // P1
        controller.rollDiceWithResult(Dice.cowrieResult(1)); // P2
      }
      expect(controller.getConsecutiveNonEntryRolls(1), 3);

      // Player 1 rolls a 4 (entry value) and enters a pawn
      controller.rollDiceWithResult(Dice.cowrieResult(4)); // P1 enters
      expect(controller.getConsecutiveNonEntryRolls(1), 0);
      expect(controller.state.phase, GamePhase.moving);
      controller.selectMove(0); // Enter pawn 0

      // Player 1 gets bonus turn (rolled 4), now has a pawn on board
      // Rolling non-entry should NOT increment counter since pawn is on board
      expect(controller.state.currentPlayerId, 1); // bonus turn
      controller.rollDiceWithResult(Dice.cowrieResult(2)); // moves pawn on board
      expect(controller.getConsecutiveNonEntryRolls(1), 0);
    });
  });

  group('Mercy Rule - Dice.forceEntryRoll', () {
    test('produces value 4 or 8 for cowrie shells', () {
      final dice = Dice(mode: DiceMode.cowrieShells, random: Random(42));
      for (int i = 0; i < 20; i++) {
        final result = dice.forceEntryRoll();
        expect(result.value == 4 || result.value == 8, isTrue);
        expect(result.allowsEntry, isTrue);
        expect(result.grantsBonusTurn, isTrue);
      }
    });

    test('shell results match the value (4 = all up, 8 = all down)', () {
      final dice = Dice(mode: DiceMode.cowrieShells, random: Random(42));
      for (int i = 0; i < 20; i++) {
        final result = dice.forceEntryRoll();
        if (result.value == 4) {
          expect(result.shellResults, [true, true, true, true]);
        } else {
          expect(result.shellResults, [false, false, false, false]);
        }
      }
    });

    test('produces value 6 for regular dice', () {
      final dice = Dice(mode: DiceMode.regularDice, random: Random(42));
      final result = dice.forceEntryRoll();
      expect(result.value, 6);
      expect(result.allowsEntry, isTrue);
      expect(result.grantsBonusTurn, isTrue);
    });
  });

  group('Mercy Rule - AI Player', () {
    test('mercy rule applies to AI player equally', () {
      final controller = GameController(
        diceMode: DiceMode.cowrieShells,
        gameMode: GameMode.humanVsAi,
        random: Random(42),
      );

      // Player 1 (human) rolls non-entry values and AI (player 2) also
      // gets non-entry values. Since both have all pawns at start,
      // non-entry values just switch turns.
      // Give player 1 entry first so the counter for AI can build up.
      
      // Build up 5 non-entry rolls for AI (player 2)
      // Just alternate non-entry rolls between the two players
      for (int i = 0; i < 5; i++) {
        // Player 1's turn
        expect(controller.state.currentPlayerId, 1);
        controller.rollDiceWithResult(Dice.cowrieResult(1)); // P1 non-entry -> P2
        
        // Player 2 (AI) turn
        expect(controller.state.currentPlayerId, 2);
        controller.rollDiceWithResult(Dice.cowrieResult(2)); // P2 non-entry -> P1
      }

      expect(controller.getConsecutiveNonEntryRolls(2), 5);
      expect(controller.state.currentPlayerId, 1);

      // Give player 1 a non-entry to switch to AI
      controller.rollDiceWithResult(Dice.cowrieResult(3)); // P1 -> P2

      // Now AI rolls - mercy rule should activate
      expect(controller.state.currentPlayerId, 2);
      expect(controller.state.phase, GamePhase.rolling);
      final result = controller.rollDice();
      expect(result, isNotNull);
      expect(result!.allowsEntry, isTrue);
      expect(result.value == 4 || result.value == 8, isTrue);
    });
  });
}
