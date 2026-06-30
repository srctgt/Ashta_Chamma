import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/logic/dice.dart';
import 'package:ashta_chamma/logic/game_controller.dart';
import 'package:ashta_chamma/ui/game_provider.dart';

void main() {
  group('GameProvider - dispose safety', () {
    test('does not throw when disposed before AI callback fires', () {
      final provider = GameProvider();
      provider.startGame(GameMode.humanVsAi, DiceMode.cowrieShells);

      // Dispose immediately
      provider.dispose();

      // Calling performAiTurn after dispose should not throw
      expect(() => provider.performAiTurn(), returnsNormally);
    });

    test('hasActiveGame returns true after starting game', () {
      final provider = GameProvider();
      provider.startGame(GameMode.humanVsHuman, DiceMode.cowrieShells);
      expect(provider.hasActiveGame, isTrue);
      provider.dispose();
    });

    test('resetGame does not throw after dispose', () {
      final provider = GameProvider();
      provider.startGame(GameMode.humanVsHuman, DiceMode.cowrieShells);
      provider.dispose();
      // Should not throw
      expect(() => provider.resetGame(), returnsNormally);
    });
  });

  group('GameProvider - AI turn depth cap', () {
    test('maxConsecutiveAiTurns is a reasonable positive value', () {
      expect(GameProvider.maxConsecutiveAiTurns, greaterThan(0));
      expect(GameProvider.maxConsecutiveAiTurns, lessThanOrEqualTo(20));
    });

    test('provider starts game in correct mode', () {
      final provider = GameProvider();
      provider.startGame(GameMode.humanVsAi, DiceMode.cowrieShells);
      expect(provider.gameMode, GameMode.humanVsAi);
      expect(provider.diceMode, DiceMode.cowrieShells);
      provider.dispose();
    });

    test('provider starts game in HvH mode', () {
      final provider = GameProvider();
      provider.startGame(GameMode.humanVsHuman, DiceMode.regularDice);
      expect(provider.gameMode, GameMode.humanVsHuman);
      expect(provider.diceMode, DiceMode.regularDice);
      provider.dispose();
    });
  });

  group('GameProvider - basic functionality', () {
    test('initial state has no active game', () {
      final provider = GameProvider();
      expect(provider.hasActiveGame, isFalse);
      provider.dispose();
    });

    test('statusMessage shows "Start a new game" without active game', () {
      final provider = GameProvider();
      expect(provider.statusMessage, 'Start a new game');
      provider.dispose();
    });

    test('isRolling after starting game', () {
      final provider = GameProvider();
      provider.startGame(GameMode.humanVsHuman, DiceMode.cowrieShells);
      expect(provider.isRolling, isTrue);
      expect(provider.isMoving, isFalse);
      expect(provider.isGameOver, isFalse);
      provider.dispose();
    });

    test('rollDice changes state', () {
      final provider = GameProvider();
      provider.startGame(GameMode.humanVsHuman, DiceMode.cowrieShells);
      // Keep rolling until state changes (dice is random)
      final initialPlayerId = provider.gameState.currentPlayerId;
      var stateChanged = false;
      for (int i = 0; i < 50; i++) {
        provider.rollDice();
        if (provider.gameState.currentPlayerId != initialPlayerId ||
            provider.isMoving) {
          stateChanged = true;
          break;
        }
      }
      expect(stateChanged, isTrue);
      provider.dispose();
    });
  });
}
