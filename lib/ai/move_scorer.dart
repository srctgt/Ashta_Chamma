import '../logic/board_path.dart';
import '../logic/move_validator.dart';
import '../models/board.dart';
import '../models/player.dart';

/// Scores individual moves for AI decision-making.
///
/// Uses a point-based system to evaluate the desirability of each move.
/// Higher scores indicate more favorable moves.
class MoveScorer {
  MoveScorer._();

  /// Score awarded for hitting an opponent pawn.
  static const int hitScore = 100;

  /// Score awarded for reaching home (center).
  static const int reachHomeScore = 90;

  /// Maximum score for advancing a pawn based on proximity to home.
  static const int maxProgressScore = 50;

  /// Score awarded for entering a new pawn onto the board.
  static const int entryScore = 40;

  /// Bonus score for landing on a safe square.
  static const int safeSquareBonus = 10;

  /// Bonus score for moving away from a vulnerable position.
  static const int avoidVulnerableBonus = 5;

  /// Calculates the total score for a given move.
  ///
  /// Parameters:
  /// - [move]: The move to evaluate.
  /// - [currentPlayer]: The player making the move.
  /// - [opponent]: The opposing player.
  ///
  /// Returns an integer score where higher values indicate better moves.
  static int scoreMove({
    required Move move,
    required Player currentPlayer,
    required Player opponent,
  }) {
    int score = 0;

    // Highest priority: hitting an opponent pawn
    if (move.isHit) {
      score += hitScore;
    }

    // Very high priority: reaching home
    if (move.reachesHome) {
      score += reachHomeScore;
    }

    // Medium priority: entering a new pawn
    if (move.isEntry) {
      score += entryScore;
    }

    // Progress-based score: reward pawns closer to home
    if (!move.isEntry && !move.reachesHome) {
      score += _calculateProgressScore(move.targetStep);
    }

    // Bonus: landing on a safe square
    if (!move.reachesHome && !move.isEntry) {
      score += _calculateSafeSquareBonus(move, currentPlayer);
    }

    // Bonus: avoiding vulnerability (leaving a currently unsafe position)
    if (!move.isEntry && !move.reachesHome) {
      score += _calculateVulnerabilityBonus(move, currentPlayer, opponent);
    }

    return score;
  }

  /// Calculates a progress score based on how close the pawn will be to home.
  ///
  /// Pawns closer to center (higher step counts) receive higher scores.
  static int _calculateProgressScore(int targetStep) {
    // Score proportional to progress along the path
    // targetStep ranges from 0 to BoardPath.centerStep - 1 (0 to 23)
    return (targetStep * maxProgressScore) ~/ (BoardPath.totalSteps - 1);
  }

  /// Calculates a bonus if the move lands on a safe square.
  static int _calculateSafeSquareBonus(Move move, Player currentPlayer) {
    final targetPosition =
        BoardPath.getPositionAtStep(move.pawn.player, move.targetStep);
    if (targetPosition != null && Board.isSafeSquare(targetPosition)) {
      return safeSquareBonus;
    }
    return 0;
  }

  /// Calculates a bonus for moving a pawn away from a vulnerable position.
  ///
  /// A pawn is considered vulnerable if it is not on a safe square and an
  /// opponent pawn could potentially reach it.
  static int _calculateVulnerabilityBonus(
    Move move,
    Player currentPlayer,
    Player opponent,
  ) {
    // Only applies to pawns already on the board (not entry moves)
    if (move.pawn.stepsCompleted == 0) return 0;

    final currentPosition = BoardPath.getPositionAtStep(
      move.pawn.player,
      move.pawn.stepsCompleted,
    );

    if (currentPosition == null) return 0;

    // If currently NOT on a safe square, get a bonus for moving
    if (!Board.isSafeSquare(currentPosition)) {
      // Check if any opponent pawn is within striking distance (1-8 steps away)
      if (_isVulnerableToOpponent(move.pawn.player, move.pawn.stepsCompleted,
          opponent)) {
        return avoidVulnerableBonus;
      }
    }

    return 0;
  }

  /// Checks if a pawn at a given step is vulnerable to being hit by an opponent.
  ///
  /// A pawn is vulnerable if an opponent pawn could reach it within the
  /// maximum possible dice roll (8 for cowrie shells).
  static bool _isVulnerableToOpponent(
    int player,
    int step,
    Player opponent,
  ) {
    final position = BoardPath.getPositionAtStep(player, step);
    if (position == null) return false;

    // Check if this position is on the outer ring (inner ring is player-specific)
    if (!BoardPath.isOuterRingStep(step)) return false;

    // Check each opponent pawn to see if they could potentially reach this position
    for (final opponentPawn in opponent.activePawns) {
      final opponentPosition = BoardPath.getPositionAtStep(
        opponentPawn.player,
        opponentPawn.stepsCompleted,
      );
      if (opponentPosition == null) continue;

      // Check if opponent could reach our position in 1-8 steps
      for (int dice = 1; dice <= 8; dice++) {
        final targetStep =
            BoardPath.calculateTargetStep(opponentPawn.stepsCompleted, dice);
        if (targetStep == null) continue;

        final targetPos =
            BoardPath.getPositionAtStep(opponentPawn.player, targetStep);
        if (targetPos == position) {
          return true;
        }
      }
    }

    return false;
  }
}
