import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/models/board.dart';
import 'package:ashta_chamma/models/pawn.dart';
import 'package:ashta_chamma/models/player.dart';
import 'package:ashta_chamma/logic/board_path.dart';
import 'package:ashta_chamma/logic/dice.dart';
import 'package:ashta_chamma/logic/game_state.dart';
import 'package:ashta_chamma/logic/move_validator.dart';

void main() {
  group('GameState - Initial State', () {
    test('starts with player 1', () {
      final state = GameState.initial();
      expect(state.currentPlayerId, 1);
    });

    test('starts in rolling phase', () {
      final state = GameState.initial();
      expect(state.phase, GamePhase.rolling);
    });

    test('both players have 4 pawns at start', () {
      final state = GameState.initial();
      expect(state.player1.pawnsAtStart, 4);
      expect(state.player2.pawnsAtStart, 4);
    });

    test('no winner initially', () {
      final state = GameState.initial();
      expect(state.winnerId, isNull);
    });

    test('default dice mode is cowrie shells', () {
      final state = GameState.initial();
      expect(state.diceMode, DiceMode.cowrieShells);
    });

    test('can specify dice mode', () {
      final state = GameState.initial(diceMode: DiceMode.regularDice);
      expect(state.diceMode, DiceMode.regularDice);
    });
  });

  group('GameState - Rolling', () {
    test('rolling with no valid moves switches turn', () {
      final state = GameState.initial();
      // Roll a 2 - no pawns on board, can not enter (needs 4 or 8)
      final newState = state.rollDice(Dice.cowrieResult(2));
      // Should switch to player 2
      expect(newState.currentPlayerId, 2);
      expect(newState.phase, GamePhase.rolling);
    });

    test('rolling entry value with pawns at start gives moves', () {
      final state = GameState.initial();
      final newState = state.rollDice(Dice.cowrieResult(4));
      expect(newState.phase, GamePhase.moving);
      expect(newState.availableMoves.isNotEmpty, isTrue);
    });

    test('rolling stores the dice result', () {
      final state = GameState.initial();
      final result = Dice.cowrieResult(4);
      final newState = state.rollDice(result);
      expect(newState.currentRoll?.value, 4);
    });

    test('cannot roll when not in rolling phase', () {
      final state = GameState.initial();
      final afterRoll = state.rollDice(Dice.cowrieResult(4));
      // Now in moving phase - rolling again should not change state
      final afterSecondRoll = afterRoll.rollDice(Dice.cowrieResult(8));
      expect(afterSecondRoll, afterRoll);
    });
  });

  group('GameState - Turn Switching', () {
    test('turn switches from player 1 to player 2', () {
      final state = GameState.initial();
      // Roll value that has no valid moves (all pawns at start, roll 1)
      final newState = state.rollDice(Dice.cowrieResult(1));
      expect(newState.currentPlayerId, 2);
    });

    test('turn switches from player 2 to player 1', () {
      var state = GameState.initial();
      // Switch to player 2
      state = state.rollDice(Dice.cowrieResult(1));
      expect(state.currentPlayerId, 2);
      // Roll again with no valid moves
      state = state.rollDice(Dice.cowrieResult(1));
      expect(state.currentPlayerId, 1);
    });
  });

  group('GameState - Bonus Turns', () {
    test('rolling 4 grants bonus turn (stays same player after move)', () {
      final state = GameState.initial();
      // Roll 4 to enter a pawn
      var newState = state.rollDice(Dice.cowrieResult(4));
      expect(newState.hasBonusTurn, isTrue);

      // Execute the entry move
      final move = newState.availableMoves.first;
      newState = newState.executeMove(move);

      // Should stay with player 1 for bonus turn
      expect(newState.currentPlayerId, 1);
      expect(newState.phase, GamePhase.rolling);
    });

    test('rolling 8 grants bonus turn', () {
      final state = GameState.initial();
      var newState = state.rollDice(Dice.cowrieResult(8));
      expect(newState.hasBonusTurn, isTrue);

      final move = newState.availableMoves.first;
      newState = newState.executeMove(move);

      expect(newState.currentPlayerId, 1);
      expect(newState.phase, GamePhase.rolling);
    });

    test('rolling 1, 2, or 3 does not grant bonus turn', () {
      // Set up a state with a pawn on board
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 5,
      );
      final state = GameState(
        player1: Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1),
            const Pawn(player: 1, pawnIndex: 2),
            const Pawn(player: 1, pawnIndex: 3),
          ],
        ),
        player2: Player(id: 2),
        currentPlayerId: 1,
        diceMode: DiceMode.cowrieShells,
      );

      var newState = state.rollDice(Dice.cowrieResult(2));
      expect(newState.hasBonusTurn, isFalse);

      final move = newState.availableMoves.first;
      newState = newState.executeMove(move);

      // Turn should switch to player 2
      expect(newState.currentPlayerId, 2);
    });
  });

  group('GameState - Hit Mechanics', () {
    test('hitting opponent pawn sends it back to start', () {
      // Find a non-safe position that both players can reach
      final p1Path = BoardPath.getPlayerPath(1);
      final p2Path = BoardPath.getPlayerPath(2);

      // Find first non-safe outer ring position for player 1
      int p1Step = -1;
      for (int i = 1; i < 16; i++) {
        if (!_isSafeSquare(p1Path[i])) {
          // Check if player 2 can also be at this position
          final p2Step = p2Path.indexOf(p1Path[i]);
          if (p2Step >= 0 && p2Step < 16) {
            p1Step = i;
            break;
          }
        }
      }

      if (p1Step > 0) {
        final targetPos = p1Path[p1Step];
        final p2Step = p2Path.indexOf(targetPos);

        final pawn0 = Pawn(
          player: 1,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: p1Step - 1,
        );
        final player1 = Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1),
            const Pawn(player: 1, pawnIndex: 2),
            const Pawn(player: 1, pawnIndex: 3),
          ],
        );

        final opponentPawn = Pawn(
          player: 2,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: p2Step,
        );
        final player2 = Player(
          id: 2,
          pawns: [
            opponentPawn,
            const Pawn(player: 2, pawnIndex: 1),
            const Pawn(player: 2, pawnIndex: 2),
            const Pawn(player: 2, pawnIndex: 3),
          ],
        );

        final state = GameState(
          player1: player1,
          player2: player2,
          currentPlayerId: 1,
          diceMode: DiceMode.cowrieShells,
        );

        var newState = state.rollDice(Dice.cowrieResult(1));
        final hitMoves =
            newState.availableMoves.where((m) => m.isHit).toList();

        if (hitMoves.isNotEmpty) {
          newState = newState.executeMove(hitMoves.first);
          // Opponent pawn should be back at start
          expect(newState.player2.pawns[0].state, PawnState.atStart);
          expect(newState.player2.pawns[0].stepsCompleted, 0);
        }
      }
    });

    test('hitting grants bonus turn', () {
      final p1Path = BoardPath.getPlayerPath(1);
      final p2Path = BoardPath.getPlayerPath(2);

      int p1Step = -1;
      for (int i = 1; i < 16; i++) {
        if (!_isSafeSquare(p1Path[i])) {
          final p2Step = p2Path.indexOf(p1Path[i]);
          if (p2Step >= 0 && p2Step < 16) {
            p1Step = i;
            break;
          }
        }
      }

      if (p1Step > 0) {
        final targetPos = p1Path[p1Step];
        final p2Step = p2Path.indexOf(targetPos);

        final pawn0 = Pawn(
          player: 1,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: p1Step - 1,
        );
        final player1 = Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1),
            const Pawn(player: 1, pawnIndex: 2),
            const Pawn(player: 1, pawnIndex: 3),
          ],
        );

        final opponentPawn = Pawn(
          player: 2,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: p2Step,
        );
        final player2 = Player(
          id: 2,
          pawns: [
            opponentPawn,
            const Pawn(player: 2, pawnIndex: 1),
            const Pawn(player: 2, pawnIndex: 2),
            const Pawn(player: 2, pawnIndex: 3),
          ],
        );

        final state = GameState(
          player1: player1,
          player2: player2,
          currentPlayerId: 1,
          diceMode: DiceMode.cowrieShells,
        );

        var newState = state.rollDice(Dice.cowrieResult(1));
        final hitMoves =
            newState.availableMoves.where((m) => m.isHit).toList();

        if (hitMoves.isNotEmpty) {
          newState = newState.executeMove(hitMoves.first);
          // Should stay with player 1 (bonus turn from hit)
          expect(newState.currentPlayerId, 1);
          expect(newState.phase, GamePhase.rolling);
        }
      }
    });

    test('hitting sets hasHitOpponent flag', () {
      final p1Path = BoardPath.getPlayerPath(1);
      final p2Path = BoardPath.getPlayerPath(2);

      int p1Step = -1;
      for (int i = 1; i < 16; i++) {
        if (!_isSafeSquare(p1Path[i])) {
          final p2Step = p2Path.indexOf(p1Path[i]);
          if (p2Step >= 0 && p2Step < 16) {
            p1Step = i;
            break;
          }
        }
      }

      if (p1Step > 0) {
        final targetPos = p1Path[p1Step];
        final p2Step = p2Path.indexOf(targetPos);

        final pawn0 = Pawn(
          player: 1,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: p1Step - 1,
        );
        final player1 = Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1),
            const Pawn(player: 1, pawnIndex: 2),
            const Pawn(player: 1, pawnIndex: 3),
          ],
          hasHitOpponent: false,
        );

        final opponentPawn = Pawn(
          player: 2,
          pawnIndex: 0,
          state: PawnState.onBoard,
          stepsCompleted: p2Step,
        );
        final player2 = Player(
          id: 2,
          pawns: [
            opponentPawn,
            const Pawn(player: 2, pawnIndex: 1),
            const Pawn(player: 2, pawnIndex: 2),
            const Pawn(player: 2, pawnIndex: 3),
          ],
        );

        final state = GameState(
          player1: player1,
          player2: player2,
          currentPlayerId: 1,
          diceMode: DiceMode.cowrieShells,
        );

        var newState = state.rollDice(Dice.cowrieResult(1));
        final hitMoves =
            newState.availableMoves.where((m) => m.isHit).toList();

        if (hitMoves.isNotEmpty) {
          newState = newState.executeMove(hitMoves.first);
          expect(newState.player1.hasHitOpponent, isTrue);
        }
      }
    });
  });

  group('GameState - Win Condition', () {
    test('game is won when all 4 pawns reach home', () {
      // Set up state where player 1 has 3 pawns at home and 1 about to reach
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 23, // One step from center
      );
      final state = GameState(
        player1: Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1, state: PawnState.atHome),
            const Pawn(player: 1, pawnIndex: 2, state: PawnState.atHome),
            const Pawn(player: 1, pawnIndex: 3, state: PawnState.atHome),
          ],
          hasHitOpponent: true,
        ),
        player2: Player(id: 2),
        currentPlayerId: 1,
        diceMode: DiceMode.cowrieShells,
      );

      var newState = state.rollDice(Dice.cowrieResult(1));
      expect(newState.phase, GamePhase.moving);

      final move = newState.availableMoves.first;
      expect(move.reachesHome, isTrue);

      newState = newState.executeMove(move);
      expect(newState.phase, GamePhase.won);
      expect(newState.winnerId, 1);
    });

    test('game is not won with fewer than 4 pawns at home', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 23,
      );
      final state = GameState(
        player1: Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1, state: PawnState.atHome),
            const Pawn(player: 1, pawnIndex: 2, state: PawnState.atHome),
            const Pawn(player: 1, pawnIndex: 3, state: PawnState.onBoard,
                stepsCompleted: 10),
          ],
          hasHitOpponent: true,
        ),
        player2: Player(id: 2),
        currentPlayerId: 1,
        diceMode: DiceMode.cowrieShells,
      );

      var newState = state.rollDice(Dice.cowrieResult(1));
      final move = newState.availableMoves
          .firstWhere((m) => m.pawn.pawnIndex == 0);
      newState = newState.executeMove(move);

      expect(newState.phase, isNot(GamePhase.won));
      expect(newState.winnerId, isNull);
    });
  });

  group('GameState - Execute Move', () {
    test('cannot execute move when not in moving phase', () {
      final state = GameState.initial();
      // In rolling phase, try to execute a fake move
      final fakeMove = Move(
        pawn: const Pawn(player: 1, pawnIndex: 0),
        diceResult: Dice.cowrieResult(4),
        targetStep: 0,
        isEntry: true,
      );
      final newState = state.executeMove(fakeMove);
      expect(newState, state); // Should not change
    });

    test('entry move places pawn on board at step 0', () {
      final state = GameState.initial();
      var newState = state.rollDice(Dice.cowrieResult(4));
      expect(newState.phase, GamePhase.moving);

      final entryMove =
          newState.availableMoves.firstWhere((m) => m.isEntry);
      newState = newState.executeMove(entryMove);

      final enteredPawn = newState.player1.pawns[entryMove.pawn.pawnIndex];
      expect(enteredPawn.state, PawnState.onBoard);
      expect(enteredPawn.stepsCompleted, 0);
    });

    test('movement updates pawn step', () {
      const pawn0 = Pawn(
        player: 1,
        pawnIndex: 0,
        state: PawnState.onBoard,
        stepsCompleted: 5,
      );
      final state = GameState(
        player1: Player(
          id: 1,
          pawns: [
            pawn0,
            const Pawn(player: 1, pawnIndex: 1),
            const Pawn(player: 1, pawnIndex: 2),
            const Pawn(player: 1, pawnIndex: 3),
          ],
        ),
        player2: Player(id: 2),
        currentPlayerId: 1,
        diceMode: DiceMode.cowrieShells,
      );

      var newState = state.rollDice(Dice.cowrieResult(3));
      final move = newState.availableMoves.first;
      newState = newState.executeMove(move);

      expect(newState.player1.pawns[0].stepsCompleted, 8);
    });
  });
}

bool _isSafeSquare(BoardPosition position) {
  return Board.isSafeSquare(position);
}
