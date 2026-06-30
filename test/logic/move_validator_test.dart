import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/models/board.dart';
import 'package:ashta_chamma/models/pawn.dart';
import 'package:ashta_chamma/models/player.dart';
import 'package:ashta_chamma/logic/board_path.dart';
import 'package:ashta_chamma/logic/dice.dart';
import 'package:ashta_chamma/logic/move_validator.dart';

void main() {
  group('MoveValidator - Entry Conditions', () {
    test('pawn can enter board on roll of 4', () {
      final player = Player(id: 1);
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(4);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.any((m) => m.isEntry), isTrue);
    });

    test('pawn can enter board on roll of 8', () {
      final player = Player(id: 1);
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(8);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.any((m) => m.isEntry), isTrue);
    });

    test('pawn cannot enter board on roll of 1, 2, or 3', () {
      final player = Player(id: 1);
      final opponent = Player(id: 2);

      for (final value in [1, 2, 3]) {
        final diceResult = Dice.cowrieResult(value);
        final moves = MoveValidator.getValidMoves(
          currentPlayer: player,
          opponent: opponent,
          diceResult: diceResult,
        );

        expect(moves.any((m) => m.isEntry), isFalse,
            reason: 'Roll of $value should not allow entry');
      }
    });

    test('entry move targets step 0', () {
      final player = Player(id: 1);
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(4);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      final entryMove = moves.firstWhere((m) => m.isEntry);
      expect(entryMove.targetStep, 0);
    });

    test('cannot enter if own pawn already at start position', () {
      // Player 1 with one pawn already at step 0 (start position)
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 0,
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(4);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      // Should not have entry moves (blocked by own pawn at start)
      expect(moves.where((m) => m.isEntry).length, 0);
    });
  });

  group('MoveValidator - Movement', () {
    test('pawn on board can move by dice value', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 5,
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(3);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.length, 1);
      expect(moves[0].targetStep, 8);
    });

    test('cannot overshoot center', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 23, // One step from center
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(2); // Would overshoot (23 + 2 = 25)

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.where((m) => m.pawn.pawnIndex == 0).length, 0);
    });

    test('can reach center with exact roll', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 23, // One step from center
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(1); // 23 + 1 = 24 = center

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      final homeMove = moves.firstWhere((m) => m.pawn.pawnIndex == 0);
      expect(homeMove.reachesHome, isTrue);
      expect(homeMove.targetStep, 24);
    });

    test('cannot land on own pawn', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 5,
      );
      const pawn1 = Pawn(
        player: 1,
        pawnIndex: 1,
        state: PawnState.onBoard,
        stepsCompleted: 8, // Would be the target of pawn0 + 3
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          pawn1,
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(3); // pawn0 would go to step 8

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      // Pawn0 cannot move to step 8 (blocked by pawn1)
      expect(moves.where((m) => m.pawn.pawnIndex == 0).length, 0);
    });
  });

  group('MoveValidator - Safe Square Protection', () {
    test('cannot hit opponent on safe square', () {
      // Place player 1 pawn near player 2's start (which is a safe square)
      // Player 2 start is at step 0 for player 2, which is outer ring index 4 = (0,4)
      // For player 1, (0,4) is at step... let's find it.
      final p1Path = BoardPath.getPlayerPath(1);
      final p2StartPos = Board.startPosition(2); // (0,4)
      final p1StepForP2Start = p1Path.indexOf(p2StartPos);

      // Place player 1 pawn at step just before opponent's safe square
      if (p1StepForP2Start > 0 && p1StepForP2Start < 16) {
        final pawn0 = Pawn(
          player: 1,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: p1StepForP2Start - 1,
        );
        final player = Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1),
            const Pawn(player: 1, pawnIndex: 2),
            const Pawn(player: 1, pawnIndex: 3),
          ],
        );

        // Place opponent pawn on the safe square
        const opponentPawn = Pawn(
          player: 2,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: 0, // Player 2's start position which is safe
        );
        final opponent = Player(
          id: 2,
          pawns: [
            opponentPawn,
            const Pawn(player: 2, pawnIndex: 1),
            const Pawn(player: 2, pawnIndex: 2),
            const Pawn(player: 2, pawnIndex: 3),
          ],
        );

        final diceResult = Dice.cowrieResult(1);
        final moves = MoveValidator.getValidMoves(
          currentPlayer: player,
          opponent: opponent,
          diceResult: diceResult,
        );

        // Should not be able to hit on a safe square
        final pawn0Moves = moves.where((m) => m.pawn.pawnIndex == 0);
        for (final m in pawn0Moves) {
          expect(m.isHit, isFalse,
              reason: 'Should not hit on safe square');
        }
      }
    });

    test('can hit opponent on non-safe square', () {
      // Find a non-safe square position on player 1's path
      final p1Path = BoardPath.getPlayerPath(1);
      int nonSafeStep = -1;
      for (int i = 1; i < 16; i++) {
        if (!Board.isSafeSquare(p1Path[i])) {
          nonSafeStep = i;
          break;
        }
      }

      if (nonSafeStep > 0) {
        final pawn0 = Pawn(
          player: 1,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: nonSafeStep - 1,
        );
        final player = Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1),
            const Pawn(player: 1, pawnIndex: 2),
            const Pawn(player: 1, pawnIndex: 3),
          ],
        );

        // Place opponent pawn at the non-safe position on the board
        // We need to find what step this corresponds to for player 2
        final targetPos = p1Path[nonSafeStep];
        final p2Path = BoardPath.getPlayerPath(2);
        final p2Step = p2Path.indexOf(targetPos);

        if (p2Step >= 0 && p2Step < 16) {
          final opponentPawn = Pawn(
            player: 2,
            pawnIndex: 0,
            state: PawnState.onBoard,
            stepsCompleted: p2Step,
          );
          final opponent = Player(
            id: 2,
            pawns: [
              opponentPawn,
              const Pawn(player: 2, pawnIndex: 1),
              const Pawn(player: 2, pawnIndex: 2),
              const Pawn(player: 2, pawnIndex: 3),
            ],
          );

          final diceResult = Dice.cowrieResult(1);
          final moves = MoveValidator.getValidMoves(
            currentPlayer: player,
            opponent: opponent,
            diceResult: diceResult,
          );

          final hitMove = moves.where(
              (m) => m.pawn.pawnIndex == 0 && m.isHit);
          expect(hitMove.isNotEmpty, isTrue,
              reason:
                  'Should be able to hit on non-safe square at step $nonSafeStep');
        }
      }
    });
  });

  group('MoveValidator - Inner Ring Access', () {
    test('cannot enter inner ring without having hit opponent', () {
      // Pawn at step 15 (last outer ring step), roll of 1 would go to step 16 (inner ring)
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 15,
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
        hasHitOpponent: false, // Has NOT hit anyone
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(1);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.where((m) => m.pawn.pawnIndex == 0).length, 0,
          reason: 'Should not be able to enter inner ring without hitting');
    });

    test('can enter inner ring after hitting opponent', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 15,
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
        hasHitOpponent: true, // HAS hit someone
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(1);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.where((m) => m.pawn.pawnIndex == 0).length, 1,
          reason: 'Should be able to enter inner ring after hitting');
      expect(moves.first.targetStep, 16);
    });

    test('can move within outer ring without hitting requirement', () {
      // Pawn at step 10, move 3 goes to step 13 - still outer ring
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 10,
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
        hasHitOpponent: false,
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(3);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.where((m) => m.pawn.pawnIndex == 0).length, 1);
      expect(moves.first.targetStep, 13);
    });

    test('pawn already on inner ring can move without hit requirement', () {
      // Pawn at step 18 (inner ring), move 2 goes to step 20 - still inner ring
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 18,
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1),
          const Pawn(player: 1, pawnIndex: 2),
          const Pawn(player: 1, pawnIndex: 3),
        ],
        hasHitOpponent: true, // must have been true to get here
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(2);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves.where((m) => m.pawn.pawnIndex == 0).length, 1);
      expect(moves.first.targetStep, 20);
    });
  });

  group('MoveValidator - No Valid Moves', () {
    test('returns empty list when all pawns at start and roll is not 4 or 8',
        () {
      final player = Player(id: 1);
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(2);

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves, isEmpty);
    });

    test('returns empty when pawn would overshoot and no other moves', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 22,
      );
      final player = Player(
        id: 1,
        pawns: [
          pawn0,
          const Pawn(player: 1, pawnIndex: 1, state: PawnState.atHome),
          const Pawn(player: 1, pawnIndex: 2, state: PawnState.atHome),
          const Pawn(player: 1, pawnIndex: 3, state: PawnState.atHome),
        ],
        hasHitOpponent: true,
      );
      final opponent = Player(id: 2);
      final diceResult = Dice.cowrieResult(3); // 22 + 3 = 25 > 24

      final moves = MoveValidator.getValidMoves(
        currentPlayer: player,
        opponent: opponent,
        diceResult: diceResult,
      );

      expect(moves, isEmpty);
    });
  });

  group('MoveValidator - getOpponentPawnAtPosition', () {
    test('finds opponent pawn at given position', () {
      const opponentPawn = Pawn(
        player: 2,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 5,
      );
      final opponent = Player(
        id: 2,
        pawns: [
          opponentPawn,
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ],
      );

      final position = BoardPath.getPositionAtStep(2, 5)!;
      final found = MoveValidator.getOpponentPawnAtPosition(opponent, position);

      expect(found, isNotNull);
      expect(found!.pawnIndex, 0);
    });

    test('returns null when no opponent pawn at position', () {
      final opponent = Player(id: 2);
      final position = BoardPath.getPositionAtStep(2, 5)!;
      final found = MoveValidator.getOpponentPawnAtPosition(opponent, position);

      expect(found, isNull);
    });
  });
}
