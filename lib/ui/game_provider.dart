import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../logic/dice.dart';
import '../logic/game_controller.dart';
import '../logic/game_state.dart';
import '../logic/move_validator.dart';
import '../models/player.dart';

/// ChangeNotifier that wraps GameController for state management.
///
/// Provides the game state to the UI and handles user interactions
/// such as rolling dice, selecting pawns, and triggering AI moves.
class GameProvider extends ChangeNotifier {
  GameController? _controller;

  /// Whether this provider has been disposed.
  bool _disposed = false;

  /// Maximum number of consecutive AI turns before forcing a stop.
  /// This prevents infinite recursion in degenerate bonus-turn streaks.
  static const int maxConsecutiveAiTurns = 10;

  /// The current game state.
  GameState get gameState =>
      _controller?.state ?? GameState.initial();

  /// The current player.
  Player get currentPlayer => gameState.currentPlayer;

  /// The opponent player.
  Player get opponent => gameState.opponent;

  /// Whether the game is in the rolling phase.
  bool get isRolling => gameState.phase == GamePhase.rolling;

  /// Whether the game is in the moving phase.
  bool get isMoving => gameState.phase == GamePhase.moving;

  /// Whether the game is over.
  bool get isGameOver => gameState.phase == GamePhase.won;

  /// The current dice result.
  DiceResult? get diceResult => gameState.currentRoll;

  /// Available moves for the current player.
  List<Move> get availableMoves => gameState.availableMoves;

  /// Whether it is the AI's turn.
  bool get isAiTurn => _controller?.isAiTurn ?? false;

  /// The winner ID, or null.
  int? get winnerId => gameState.winnerId;

  /// The current game mode.
  GameMode get gameMode => _controller?.gameMode ?? GameMode.humanVsHuman;

  /// The current dice mode.
  DiceMode get diceMode => gameState.diceMode;

  /// Whether a game is currently active.
  bool get hasActiveGame => _controller != null;

  /// Returns a status message for the current game state.
  String get statusMessage {
    if (_controller == null) return 'Start a new game';

    if (isGameOver) {
      return 'Player $winnerId wins!';
    }

    if (isAiTurn) {
      return 'AI is thinking...';
    }

    if (isRolling) {
      return 'Player ${gameState.currentPlayerId}: Roll the dice';
    }

    if (isMoving) {
      if (availableMoves.length == 1) {
        return 'Player ${gameState.currentPlayerId}: Tap the pawn to move';
      }
      return 'Player ${gameState.currentPlayerId}: Select a pawn to move';
    }

    return '';
  }

  /// Starts a new game with the given modes.
  void startGame(GameMode gameMode, DiceMode diceMode) {
    _controller = GameController(
      diceMode: diceMode,
      gameMode: gameMode,
      random: Random(),
    );
    notifyListeners();
  }

  /// Rolls the dice for the current player.
  void rollDice() {
    if (_controller == null || !isRolling || isAiTurn) return;

    _controller!.rollDice();
    notifyListeners();

    // If no moves available, the state may have already switched turns
    // Check if it's now AI's turn
    if (isAiTurn && !isGameOver) {
      _scheduleAiTurn();
    }
  }

  /// Selects a pawn to move by pawn index.
  void selectPawn(int pawnIndex) {
    if (_controller == null || !isMoving || isAiTurn) return;

    // Check if this pawn has a valid move
    final hasMove = availableMoves.any((m) => m.pawn.pawnIndex == pawnIndex);
    if (!hasMove) return;

    _controller!.selectMove(pawnIndex);
    notifyListeners();

    // Check if it's now AI's turn
    if (isAiTurn && !isGameOver) {
      _scheduleAiTurn();
    }
  }

  /// Performs the AI turn with a delay for natural feel.
  void _scheduleAiTurn([int depth = 0]) {
    if (depth >= maxConsecutiveAiTurns) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_disposed || _controller == null || isGameOver) return;
      _performAiTurnWithDepth(depth);
    });
  }

  /// Performs the AI's turn immediately.
  void performAiTurn() {
    _performAiTurnWithDepth(0);
  }

  /// Internal: performs AI turn with depth tracking.
  void _performAiTurnWithDepth(int depth) {
    if (_disposed || _controller == null || !isAiTurn || isGameOver) return;
    if (depth >= maxConsecutiveAiTurns) return;

    _controller!.performAiTurn();
    if (_disposed) return;
    notifyListeners();

    // AI may get a bonus turn
    if (isAiTurn && !isGameOver) {
      _scheduleAiTurn(depth + 1);
    }
  }

  /// Resets the game to initial state.
  void resetGame() {
    _controller?.reset();
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
