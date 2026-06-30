import 'dart:math';

import '../ai/ai_player.dart';
import '../models/pawn.dart';
import 'dice.dart';
import 'game_state.dart';
import 'move_validator.dart';

/// The type of game being played.
enum GameMode {
  /// Human vs Human (pass-and-play on same device).
  humanVsHuman,

  /// Human vs AI (computer opponent).
  humanVsAi,
}

/// High-level game flow controller.
///
/// Orchestrates the game by managing state transitions, processing player
/// actions, managing turn flow including bonus turns, and determining when
/// the AI should act.
class GameController {
  /// The current game state.
  GameState _state;

  /// The dice instance used for rolling.
  final Dice _dice;

  /// The game mode.
  final GameMode gameMode;

  /// The AI player ID (always player 2 in HumanVsAi mode).
  final int aiPlayerId = 2;

  /// The AI player instance.
  final AiPlayer _aiPlayer;

  GameController({
    DiceMode diceMode = DiceMode.cowrieShells,
    this.gameMode = GameMode.humanVsHuman,
    Random? random,
  })  : _dice = Dice(mode: diceMode, random: random),
        _aiPlayer = AiPlayer(random: random),
        _state = GameState.initial(diceMode: diceMode);

  /// Creates a controller with a specific initial state (for testing).
  GameController.withState({
    required GameState state,
    this.gameMode = GameMode.humanVsHuman,
    Random? random,
  })  : _state = state,
        _dice = Dice(mode: state.diceMode, random: random),
        _aiPlayer = AiPlayer(random: random);

  /// The current game state (read-only).
  GameState get state => _state;

  /// Whether it's the AI's turn.
  bool get isAiTurn =>
      gameMode == GameMode.humanVsAi && _state.currentPlayerId == aiPlayerId;

  /// Whether the game is over.
  bool get isGameOver => _state.phase == GamePhase.won;

  /// The winner's ID, or null if no winner yet.
  int? get winnerId => _state.winnerId;

  /// Rolls the dice for the current player.
  /// Returns the dice result, or null if rolling is not allowed.
  DiceResult? rollDice() {
    if (_state.phase != GamePhase.rolling) {
      return null;
    }

    final result = _dice.roll();
    _state = _state.rollDice(result);
    return result;
  }

  /// Rolls the dice with a specific result (for testing/replay).
  DiceResult? rollDiceWithResult(DiceResult result) {
    if (_state.phase != GamePhase.rolling) {
      return null;
    }

    _state = _state.rollDice(result);
    return result;
  }

  /// Selects a move from the available moves.
  /// Returns true if the move was executed successfully.
  bool selectMove(int pawnIndex) {
    if (_state.phase != GamePhase.moving) {
      return false;
    }

    // Find the move for this pawn
    final move = _state.availableMoves.firstWhere(
      (m) => m.pawn.pawnIndex == pawnIndex,
      orElse: () => const Move(
        pawn: Pawn(player: 0, pawnIndex: -1),
        diceResult: DiceResult(
          value: 1,
          grantsBonusTurn: false,
          allowsEntry: false,
        ),
        targetStep: -1,
      ),
    );

    if (move.pawn.player == 0) {
      return false; // No valid move found for this pawn
    }

    _state = _state.executeMove(move);
    return true;
  }

  /// Executes a specific move.
  /// Returns true if successful.
  bool executeMove(Move move) {
    if (_state.phase != GamePhase.moving) {
      return false;
    }

    _state = _state.executeMove(move);
    return true;
  }

  /// Performs the AI's turn. Rolls dice and selects a move.
  /// Returns true if the AI took an action.
  bool performAiTurn() {
    if (!isAiTurn) return false;
    if (_state.phase == GamePhase.won) return false;

    if (_state.phase == GamePhase.rolling) {
      rollDice();
    }

    if (_state.phase == GamePhase.moving && _state.availableMoves.isNotEmpty) {
      final move = _aiPlayer.selectMove(
        availableMoves: _state.availableMoves,
        currentPlayer: _state.currentPlayer,
        opponent: _state.opponent,
      );
      if (move != null) {
        _state = _state.executeMove(move);
      }
    }

    return true;
  }

  /// Resets the game to initial state.
  void reset({DiceMode? diceMode}) {
    _state = GameState.initial(diceMode: diceMode ?? _state.diceMode);
  }
}
