import '../models/board.dart';

/// Manages path calculations for each player.
///
/// Each player's path:
/// 1. Starts at their starting position on the outer ring
/// 2. Goes anti-clockwise around the outer ring (16 positions)
/// 3. Transitions to inner ring, goes clockwise (8 positions)
/// 4. Ends at center (home)
///
/// Total path length: 16 (outer) + 8 (inner) + 1 (center) = 25 steps
/// Step indices: 0-15 = outer ring, 16-23 = inner ring, 24 = center
class BoardPath {
  BoardPath._();

  /// Total steps to reach home (outer ring + inner ring + center).
  static const int totalSteps = 25; // 16 outer + 8 inner + 1 center

  /// Number of steps on the outer ring.
  static const int outerSteps = 16;

  /// Number of steps on the inner ring.
  static const int innerSteps = 8;

  /// The step index that represents the center (home).
  static const int centerStep = 24;

  /// The first step on the inner ring.
  static const int innerRingStartStep = 16;

  /// Gets the complete path for a player as a list of board positions.
  /// Index 0 is the player's starting position on the outer ring.
  /// Index 24 is the center (home).
  static List<BoardPosition> getPlayerPath(int player) {
    assert(player == 1 || player == 2);

    final path = <BoardPosition>[];
    final startIndex = Board.startOuterIndex(player);

    // Outer ring: anti-clockwise from player's start
    // For a clockwise-defined ring, anti-clockwise means going in reverse
    // But our outer ring is defined in a specific order.
    // Anti-clockwise traversal from the start index:
    // We go backwards through the outerRing list (since the list is in clockwise order)
    for (int i = 0; i < Board.outerRingLength; i++) {
      final index =
          (startIndex - i + Board.outerRingLength) % Board.outerRingLength;
      path.add(Board.outerRing[index]);
    }

    // Inner ring: clockwise from the entry point
    // Entry point to inner ring depends on player.
    // Player 1 starts at outer index 12 (4,0), enters inner ring near (3,1).
    // Player 2 starts at outer index 4 (0,4), enters inner ring near (1,3).
    final innerStartIndex = _getInnerRingEntryIndex(player);
    for (int i = 0; i < Board.innerRingLength; i++) {
      final index =
          (innerStartIndex + i) % Board.innerRingLength;
      path.add(Board.innerRing[index]);
    }

    // Center (home)
    path.add(Board.center);

    return path;
  }

  /// Gets the inner ring entry index for a player.
  /// This determines where the player enters the inner ring after completing
  /// the outer ring.
  static int _getInnerRingEntryIndex(int player) {
    // Player 1 starts at (4,0) -> goes anti-clockwise -> after completing
    // outer ring, enters inner ring at position adjacent to their start.
    // Player 1's last outer position before transition is (1,0) (index 15
    // in outer ring), so they enter inner ring at (1,1) which is inner index 0,
    // then go clockwise: (1,1), (1,2), (1,3), (2,3), (3,3), (3,2), (3,1), (2,1)
    //
    // Player 2 starts at (0,4) -> goes anti-clockwise -> after completing
    // outer ring, enters inner ring at position adjacent to their start.
    // Player 2's last outer position before transition is (1,4) (index 5),
    // so they enter inner ring at (1,3) which is inner index 2,
    // then go clockwise: (1,3), (2,3), (3,3), (3,2), (3,1), (2,1), (1,1), (1,2)
    if (player == 1) {
      return 0; // Enter at (1,1)
    } else {
      return 4; // Enter at (3,3)
    }
  }

  /// Gets the board position for a given step on a player's path.
  /// Returns null if step is out of range.
  static BoardPosition? getPositionAtStep(int player, int step) {
    if (step < 0 || step >= totalSteps) return null;
    final path = getPlayerPath(player);
    return path[step];
  }

  /// Gets the step index for a given board position on a player's path.
  /// Returns -1 if the position is not on the player's path.
  static int getStepForPosition(int player, BoardPosition position) {
    final path = getPlayerPath(player);
    return path.indexOf(position);
  }

  /// Calculates the target step after moving a given number of steps.
  /// Returns null if the move would overshoot the center.
  static int? calculateTargetStep(int currentStep, int diceValue) {
    final targetStep = currentStep + diceValue;
    if (targetStep >= totalSteps) {
      return null; // Overshooting center
    }
    return targetStep;
  }

  /// Checks if a step is on the outer ring portion of the path.
  static bool isOuterRingStep(int step) {
    return step >= 0 && step < outerSteps;
  }

  /// Checks if a step is on the inner ring portion of the path.
  static bool isInnerRingStep(int step) {
    return step >= innerRingStartStep && step < centerStep;
  }

  /// Checks if a step is the center (home).
  static bool isCenterStep(int step) {
    return step == centerStep;
  }
}
