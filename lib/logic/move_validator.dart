import '../models/board.dart';
import '../models/pawn.dart';
import '../models/player.dart';
import 'board_path.dart';
import 'dice.dart';

/// Represents a valid move a player can make.
class Move {
  /// The pawn to move.
  final Pawn pawn;

  /// The dice result used for this move.
  final DiceResult diceResult;

  /// The target step on the player's path after this move.
  final int targetStep;

  /// Whether this move enters the pawn onto the board.
  final bool isEntry;

  /// Whether this move hits an opponent pawn.
  final bool isHit;

  /// Whether this move reaches center (home).
  final bool reachesHome;

  const Move({
    required this.pawn,
    required this.diceResult,
    required this.targetStep,
    this.isEntry = false,
    this.isHit = false,
    this.reachesHome = false,
  });

  @override
  String toString() =>
      'Move(pawn: ${pawn.pawnIndex}, target: $targetStep, entry: $isEntry, hit: $isHit, home: $reachesHome)';
}

/// Validates and generates possible moves for a player.
class MoveValidator {
  MoveValidator._();

  /// Gets all valid moves for a player given a dice result.
  ///
  /// Parameters:
  /// - [currentPlayer]: The player whose turn it is.
  /// - [opponent]: The opposing player.
  /// - [diceResult]: The result of the dice roll.
  ///
  /// Returns a list of valid [Move]s the player can make.
  static List<Move> getValidMoves({
    required Player currentPlayer,
    required Player opponent,
    required DiceResult diceResult,
  }) {
    final moves = <Move>[];

    // Check if any pawn at start can enter the board
    if (diceResult.allowsEntry) {
      for (final pawn in currentPlayer.startPawns) {
        final entryMove = _validateEntry(
          pawn: pawn,
          currentPlayer: currentPlayer,
          opponent: opponent,
          diceResult: diceResult,
        );
        if (entryMove != null) {
          moves.add(entryMove);
        }
      }
    }

    // Check moves for pawns already on the board
    for (final pawn in currentPlayer.activePawns) {
      final move = _validateMove(
        pawn: pawn,
        currentPlayer: currentPlayer,
        opponent: opponent,
        diceResult: diceResult,
      );
      if (move != null) {
        moves.add(move);
      }
    }

    return moves;
  }

  /// Validates an entry move for a pawn.
  static Move? _validateEntry({
    required Pawn pawn,
    required Player currentPlayer,
    required Player opponent,
    required DiceResult diceResult,
  }) {
    assert(pawn.state == PawnState.atStart);

    // Pawn enters at step 0 (player's start position on outer ring)
    const targetStep = 0;
    final targetPosition = BoardPath.getPositionAtStep(pawn.player, targetStep)!;

    // Check if own pawn is already at the start position
    if (_isOwnPawnAtPosition(currentPlayer, targetPosition, exclude: pawn)) {
      return null;
    }

    // Check for opponent at entry position
    final isHit = _isOpponentAtPosition(opponent, targetPosition);
    // Entry position is always a safe square (corners), so no hit possible
    if (isHit && Board.isSafeSquare(targetPosition)) {
      return null;
    }

    return Move(
      pawn: pawn,
      diceResult: diceResult,
      targetStep: targetStep,
      isEntry: true,
      isHit: isHit,
    );
  }

  /// Validates a move for a pawn already on the board.
  static Move? _validateMove({
    required Pawn pawn,
    required Player currentPlayer,
    required Player opponent,
    required DiceResult diceResult,
  }) {
    assert(pawn.state == PawnState.onBoard);

    final currentStep = pawn.stepsCompleted;

    // Calculate target step
    final targetStep =
        BoardPath.calculateTargetStep(currentStep, diceResult.value);
    if (targetStep == null) {
      // Overshooting center - invalid move
      return null;
    }

    // Check if trying to enter inner ring without having hit an opponent
    if (_wouldEnterInnerRing(currentStep, targetStep) &&
        !currentPlayer.hasHitOpponent) {
      return null;
    }

    final targetPosition =
        BoardPath.getPositionAtStep(pawn.player, targetStep)!;
    final reachesHome = BoardPath.isCenterStep(targetStep);

    // Cannot land on own pawn
    if (!reachesHome &&
        _isOwnPawnAtPosition(currentPlayer, targetPosition, exclude: pawn)) {
      return null;
    }

    // Check for opponent hit
    bool isHit = false;
    if (!reachesHome) {
      final opponentAtTarget = _isOpponentAtPosition(opponent, targetPosition);
      if (opponentAtTarget) {
        if (Board.isSafeSquare(targetPosition)) {
          // Cannot hit on safe square - move is still valid, just blocked
          return null;
        }
        isHit = true;
      }
    }

    return Move(
      pawn: pawn,
      diceResult: diceResult,
      targetStep: targetStep,
      isHit: isHit,
      reachesHome: reachesHome,
    );
  }

  /// Checks if the move would cross from outer ring to inner ring.
  static bool _wouldEnterInnerRing(int currentStep, int targetStep) {
    return currentStep < BoardPath.innerRingStartStep &&
        targetStep >= BoardPath.innerRingStartStep;
  }

  /// Checks if any of the player's own pawns are at a position (excluding a specific pawn).
  static bool _isOwnPawnAtPosition(
    Player player,
    BoardPosition position, {
    required Pawn exclude,
  }) {
    for (final pawn in player.activePawns) {
      if (pawn == exclude) continue;
      final pawnPosition =
          BoardPath.getPositionAtStep(pawn.player, pawn.stepsCompleted);
      if (pawnPosition == position) {
        return true;
      }
    }
    return false;
  }

  /// Checks if any of the opponent's pawns are at a position.
  static bool _isOpponentAtPosition(Player opponent, BoardPosition position) {
    for (final pawn in opponent.activePawns) {
      final pawnPosition =
          BoardPath.getPositionAtStep(pawn.player, pawn.stepsCompleted);
      if (pawnPosition == position) {
        return true;
      }
    }
    return false;
  }

  /// Gets the opponent pawn at a specific position, if any.
  static Pawn? getOpponentPawnAtPosition(
      Player opponent, BoardPosition position) {
    for (final pawn in opponent.activePawns) {
      final pawnPosition =
          BoardPath.getPositionAtStep(pawn.player, pawn.stepsCompleted);
      if (pawnPosition == position) {
        return pawn;
      }
    }
    return null;
  }
}
