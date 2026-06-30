import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/logic/dice.dart';
import 'package:ashta_chamma/logic/game_state.dart';
import 'package:ashta_chamma/models/pawn.dart';
import 'package:ashta_chamma/models/player.dart';

void main() {
  group('GameState.copyWith - nullable field clearing', () {
    test('can clear currentRoll to null explicitly', () {
      final state = GameState.initial();
      // Roll to get a currentRoll value
      final rolledState = state.rollDice(Dice.cowrieResult(4));
      expect(rolledState.currentRoll, isNotNull);

      // Clear the currentRoll using copyWith
      final clearedState = rolledState.copyWith(currentRoll: null);
      expect(clearedState.currentRoll, isNull);
    });

    test('preserves currentRoll when not passed to copyWith', () {
      final state = GameState.initial();
      final rolledState = state.rollDice(Dice.cowrieResult(4));
      expect(rolledState.currentRoll, isNotNull);

      // copyWith without currentRoll should preserve it
      final copiedState = rolledState.copyWith(phase: GamePhase.rolling);
      expect(copiedState.currentRoll, rolledState.currentRoll);
    });

    test('can clear winnerId to null explicitly', () {
      final state = GameState(
        player1: Player(id: 1),
        player2: Player(id: 2),
        currentPlayerId: 1,
        diceMode: DiceMode.cowrieShells,
        phase: GamePhase.won,
        winnerId: 1,
      );
      expect(state.winnerId, 1);

      final clearedState = state.copyWith(winnerId: null);
      expect(clearedState.winnerId, isNull);
    });

    test('preserves winnerId when not passed to copyWith', () {
      final state = GameState(
        player1: Player(id: 1),
        player2: Player(id: 2),
        currentPlayerId: 1,
        diceMode: DiceMode.cowrieShells,
        phase: GamePhase.won,
        winnerId: 2,
      );

      final copiedState = state.copyWith(phase: GamePhase.rolling);
      expect(copiedState.winnerId, 2);
    });

    test('bonus turn clears currentRoll after move', () {
      final state = GameState.initial();
      // Roll 4 (bonus turn + entry)
      var newState = state.rollDice(Dice.cowrieResult(4));
      expect(newState.currentRoll, isNotNull);
      expect(newState.hasBonusTurn, isTrue);

      // Execute entry move
      final move = newState.availableMoves.first;
      newState = newState.executeMove(move);

      // After bonus turn, currentRoll should be cleared
      expect(newState.currentRoll, isNull);
      expect(newState.phase, GamePhase.rolling);
    });

    test('win state clears currentRoll', () {
      // Set up state where player 1 is about to win
      final state = GameState(
        player1: Player(
          id: 1,
          pawns: [
            const Pawn(
              player: 1,
              pawnIndex: 0,
              state: PawnState.onBoard,
              stepsCompleted: 23,
            ),
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
      expect(newState.currentRoll, isNotNull);

      final move = newState.availableMoves.first;
      newState = newState.executeMove(move);

      expect(newState.phase, GamePhase.won);
      expect(newState.winnerId, 1);
      // currentRoll should be cleared in win state
      expect(newState.currentRoll, isNull);
    });
  });
}
