import 'dart:math';

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

  /// Random instance for the controller.
  final Random _random;

  GameController({
    DiceMode diceMode = DiceMode.cowrieShells,
    this.gameMode = GameMode.humanVsHuman,
    Random? random,
  })  : _dice = Dice(mode: diceMode, random: random),
        _random = random ?? Random(),
        _state = GameState.initial(diceMode: diceMode);

  /// Creates a controller with a specific initial state (for testing).
  GameController.withState({
    required GameState state,
    this.gameMode = GameMode.humanVsHuman,
    Random? random,
  })  : _state = state,
        _dice = Dice(mode: state.diceMode, random: random),
        _random = random ?? Random();

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
      final move = _selectAiMove(_state.availableMoves);
      _state = _state.executeMove(move);
    }

    return true;
  }

  /// Selects the best move for the AI using simple heuristics.
  ///
  /// Priority order:
  /// 1. Hit an opponent pawn (aggressive play)
  /// 2. Move a pawn home if possible
  /// 3. Move the pawn closest to home (advance furthest pawn)
  /// 4. Enter a new pawn onto the board
  /// 5. Random valid move
  Move _selectAiMove(List<Move> moves) {
    // Priority 1: Hit opponent
    final hitMoves = moves.where((m) => m.isHit).toList();
    if (hitMoves.isNotEmpty) {
      return hitMoves[_random.nextInt(hitMoves.length)];
    }

    // Priority 2: Reach home
    final homeMoves = moves.where((m) => m.reachesHome).toList();
    if (homeMoves.isNotEmpty) {
      return homeMoves[_random.nextInt(homeMoves.length)];
    }

    // Priority 3: Move furthest pawn (closest to home)
    final boardMoves =
        moves.where((m) => !m.isEntry && !m.reachesHome).toList();
    if (boardMoves.isNotEmpty) {
      boardMoves.sort((a, b) => b.targetStep.compareTo(a.targetStep));
      return boardMoves.first;
    }

    // Priority 4: Enter a new pawn
    final entryMoves = moves.where((m) => m.isEntry).toList();
    if (entryMoves.isNotEmpty) {
      return entryMoves[_random.nextInt(entryMoves.length)];
    }

    // Fallback: random
    return moves[_random.nextInt(moves.length)];
  }

  /// Resets the game to initial state.
  void reset({DiceMode? diceMode}) {
    _state = GameState.initial(diceMode: diceMode ?? _state.diceMode);
  }
}
