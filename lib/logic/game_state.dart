import '../models/pawn.dart';
import '../models/player.dart';
import 'board_path.dart';
import 'dice.dart';
import 'move_validator.dart';

/// Represents the current phase of the game.
enum GamePhase {
  /// Waiting for a dice roll.
  rolling,

  /// Player has rolled and must select a move.
  moving,

  /// The game has been won.
  won,
}

/// Represents the complete state of the game.
class GameState {
  /// Player 1.
  final Player player1;

  /// Player 2.
  final Player player2;

  /// The current player's ID (1 or 2).
  final int currentPlayerId;

  /// The dice mode being used.
  final DiceMode diceMode;

  /// The current dice result (null if no roll yet this turn).
  final DiceResult? currentRoll;

  /// Available moves for the current player.
  final List<Move> availableMoves;

  /// Current game phase.
  final GamePhase phase;

  /// ID of the winning player (null if no winner yet).
  final int? winnerId;

  /// Whether the current roll grants a bonus turn.
  final bool hasBonusTurn;

  /// Number of consecutive bonus turns (to prevent infinite loops with testing).
  final int consecutiveBonusTurns;

  const GameState({
    required this.player1,
    required this.player2,
    required this.currentPlayerId,
    required this.diceMode,
    this.currentRoll,
    this.availableMoves = const [],
    this.phase = GamePhase.rolling,
    this.winnerId,
    this.hasBonusTurn = false,
    this.consecutiveBonusTurns = 0,
  });

  /// Creates the initial game state.
  factory GameState.initial({DiceMode diceMode = DiceMode.cowrieShells}) {
    return GameState(
      player1: Player(id: 1),
      player2: Player(id: 2),
      currentPlayerId: 1,
      diceMode: diceMode,
    );
  }

  /// Gets the current player.
  Player get currentPlayer => currentPlayerId == 1 ? player1 : player2;

  /// Gets the opponent player.
  Player get opponent => currentPlayerId == 1 ? player2 : player1;

  /// Gets a player by ID.
  Player getPlayer(int id) => id == 1 ? player1 : player2;

  /// Processes a dice roll and returns the new game state.
  GameState rollDice(DiceResult result) {
    if (phase != GamePhase.rolling) {
      return this; // Cannot roll if not in rolling phase
    }

    final moves = MoveValidator.getValidMoves(
      currentPlayer: currentPlayer,
      opponent: opponent,
      diceResult: result,
    );

    // Determine if this is a bonus turn
    final bonus = result.grantsBonusTurn;

    if (moves.isEmpty) {
      // No valid moves - switch to next player (unless bonus turn)
      if (bonus) {
        // Bonus turn but no moves - still get another roll
        return copyWith(
          currentRoll: result,
          availableMoves: [],
          phase: GamePhase.rolling,
          hasBonusTurn: false,
          consecutiveBonusTurns: consecutiveBonusTurns + 1,
        );
      }
      return _switchTurn();
    }

    return copyWith(
      currentRoll: result,
      availableMoves: moves,
      phase: GamePhase.moving,
      hasBonusTurn: bonus,
    );
  }

  /// Executes a move and returns the new game state.
  GameState executeMove(Move move) {
    if (phase != GamePhase.moving) {
      return this; // Cannot move if not in moving phase
    }

    // Validate that this move is in the available moves
    final isValid = availableMoves.any((m) =>
        m.pawn.pawnIndex == move.pawn.pawnIndex &&
        m.targetStep == move.targetStep);
    if (!isValid) {
      return this; // Invalid move
    }

    var newPlayer1 = player1;
    var newPlayer2 = player2;

    final movingPlayer = currentPlayerId == 1 ? player1 : player2;
    var opponentPlayer = currentPlayerId == 1 ? player2 : player1;

    // Update the pawn's position
    Pawn updatedPawn;
    if (move.isEntry) {
      updatedPawn = move.pawn.copyWith(
        state: PawnState.onBoard,
        stepsCompleted: 0,
      );
    } else if (move.reachesHome) {
      updatedPawn = move.pawn.copyWith(
        state: PawnState.atHome,
        stepsCompleted: BoardPath.centerStep,
      );
    } else {
      updatedPawn = move.pawn.copyWith(
        stepsCompleted: move.targetStep,
      );
    }

    var updatedMovingPlayer =
        movingPlayer.updatePawn(move.pawn.pawnIndex, updatedPawn);

    // Handle hit
    bool hitOccurred = move.isHit;
    if (hitOccurred) {
      final targetPosition =
          BoardPath.getPositionAtStep(move.pawn.player, move.targetStep)!;
      final hitPawn = MoveValidator.getOpponentPawnAtPosition(
          opponentPlayer, targetPosition);
      if (hitPawn != null) {
        // Send opponent pawn back to start
        final resetPawn = hitPawn.copyWith(
          state: PawnState.atStart,
          stepsCompleted: 0,
        );
        opponentPlayer =
            opponentPlayer.updatePawn(hitPawn.pawnIndex, resetPawn);
      }
      // Mark that current player has hit an opponent
      updatedMovingPlayer = updatedMovingPlayer.copyWith(hasHitOpponent: true);
    }

    // Update players
    if (currentPlayerId == 1) {
      newPlayer1 = updatedMovingPlayer;
      newPlayer2 = opponentPlayer;
    } else {
      newPlayer1 = opponentPlayer;
      newPlayer2 = updatedMovingPlayer;
    }

    // Check win condition
    if (updatedMovingPlayer.hasWon) {
      return copyWith(
        player1: newPlayer1,
        player2: newPlayer2,
        phase: GamePhase.won,
        winnerId: currentPlayerId,
        currentRoll: null,
        availableMoves: [],
      );
    }

    // Determine next phase
    // Bonus turn if: rolled 4 or 8 (cowrie) OR hit occurred
    if (hasBonusTurn || hitOccurred) {
      return copyWith(
        player1: newPlayer1,
        player2: newPlayer2,
        phase: GamePhase.rolling,
        currentRoll: null,
        availableMoves: [],
        hasBonusTurn: false,
        consecutiveBonusTurns:
            hitOccurred ? 0 : consecutiveBonusTurns + 1,
      );
    }

    // Switch to next player
    return GameState(
      player1: newPlayer1,
      player2: newPlayer2,
      currentPlayerId: currentPlayerId == 1 ? 2 : 1,
      diceMode: diceMode,
      phase: GamePhase.rolling,
    );
  }

  /// Switches turn to the next player.
  GameState _switchTurn() {
    return GameState(
      player1: player1,
      player2: player2,
      currentPlayerId: currentPlayerId == 1 ? 2 : 1,
      diceMode: diceMode,
      phase: GamePhase.rolling,
    );
  }

  /// Creates a copy of this state with optional field changes.
  GameState copyWith({
    Player? player1,
    Player? player2,
    int? currentPlayerId,
    DiceMode? diceMode,
    DiceResult? currentRoll,
    List<Move>? availableMoves,
    GamePhase? phase,
    int? winnerId,
    bool? hasBonusTurn,
    int? consecutiveBonusTurns,
  }) {
    return GameState(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      diceMode: diceMode ?? this.diceMode,
      currentRoll: currentRoll ?? this.currentRoll,
      availableMoves: availableMoves ?? this.availableMoves,
      phase: phase ?? this.phase,
      winnerId: winnerId ?? this.winnerId,
      hasBonusTurn: hasBonusTurn ?? this.hasBonusTurn,
      consecutiveBonusTurns:
          consecutiveBonusTurns ?? this.consecutiveBonusTurns,
    );
  }

  @override
  String toString() =>
      'GameState(phase: $phase, currentPlayer: $currentPlayerId, roll: ${currentRoll?.value}, moves: ${availableMoves.length})';
}
