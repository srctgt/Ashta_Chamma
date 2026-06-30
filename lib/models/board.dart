/// Represents the 5x5 Ashta Chamma (Chowka Bhara) game board.
///
/// The board consists of:
/// - Outer ring: 16 positions (the perimeter cells of the 5x5 grid)
/// - Inner ring: 8 positions (the ring inside the outer ring)
/// - Center: 1 position (home/winning square)
///
/// Board coordinate system (row, col) with (0,0) at top-left:
///
///   (0,0) (0,1) (0,2) (0,3) (0,4)
///   (1,0) (1,1) (1,2) (1,3) (1,4)
///   (2,0) (2,1) (2,2) (2,3) (2,4)
///   (3,0) (3,1) (3,2) (3,3) (3,4)
///   (4,0) (4,1) (4,2) (4,3) (4,4)
library;

/// A position on the board represented by row and column.
class BoardPosition {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is BoardPosition && other.row == row && other.col == col;

  @override
  int get hashCode => row * 5 + col;

  @override
  String toString() => 'BoardPosition($row, $col)';
}

/// Defines the board layout and properties.
class Board {
  Board._();

  /// The center (home) position.
  static const BoardPosition center = BoardPosition(2, 2);

  /// Outer ring positions in order (anti-clockwise starting from top-left).
  /// The outer ring consists of the 16 perimeter cells of the 5x5 grid,
  /// traversed anti-clockwise starting from (0, 0).
  static const List<BoardPosition> outerRing = [
    // Top row: left to right
    BoardPosition(0, 0), // index 0
    BoardPosition(0, 1), // index 1
    BoardPosition(0, 2), // index 2
    BoardPosition(0, 3), // index 3
    BoardPosition(0, 4), // index 4
    // Right column: top to bottom (excluding top-right corner already counted)
    BoardPosition(1, 4), // index 5
    BoardPosition(2, 4), // index 6
    BoardPosition(3, 4), // index 7
    BoardPosition(4, 4), // index 8
    // Bottom row: right to left (excluding bottom-right corner already counted)
    BoardPosition(4, 3), // index 9
    BoardPosition(4, 2), // index 10
    BoardPosition(4, 1), // index 11
    BoardPosition(4, 0), // index 12
    // Left column: bottom to top (excluding corners already counted)
    BoardPosition(3, 0), // index 13
    BoardPosition(2, 0), // index 14
    BoardPosition(1, 0), // index 15
  ];

  /// Inner ring positions in order (clockwise starting from top-left inner).
  /// The inner ring consists of the 8 cells one step inward from the outer ring.
  static const List<BoardPosition> innerRing = [
    // Top inner row
    BoardPosition(1, 1), // index 0
    BoardPosition(1, 2), // index 1
    BoardPosition(1, 3), // index 2
    // Right inner column
    BoardPosition(2, 3), // index 3
    // Bottom inner row (right to left)
    BoardPosition(3, 3), // index 4
    BoardPosition(3, 2), // index 5
    BoardPosition(3, 1), // index 6
    // Left inner column
    BoardPosition(2, 1), // index 7
  ];

  /// Total positions on the outer ring.
  static int get outerRingLength => outerRing.length; // 16

  /// Total positions on the inner ring.
  static int get innerRingLength => innerRing.length; // 8

  /// Safe square positions (crossed/X squares).
  /// These are the 4 corners and 4 midpoints of the outer ring.
  /// No hitting is allowed on these squares.
  static const List<BoardPosition> safeSquares = [
    // Corners of outer ring
    BoardPosition(0, 0), // top-left corner
    BoardPosition(0, 4), // top-right corner
    BoardPosition(4, 4), // bottom-right corner
    BoardPosition(4, 0), // bottom-left corner
    // Midpoints of outer ring sides
    BoardPosition(0, 2), // top midpoint
    BoardPosition(2, 4), // right midpoint
    BoardPosition(4, 2), // bottom midpoint
    BoardPosition(2, 0), // left midpoint
  ];

  /// Starting position index on the outer ring for Player 1.
  /// Player 1 starts at the bottom-left corner (outer ring index 12 = (4,0)).
  static const int player1StartOuterIndex = 12;

  /// Starting position index on the outer ring for Player 2.
  /// Player 2 starts at the top-right corner (outer ring index 4 = (0,4)).
  static const int player2StartOuterIndex = 4;

  /// Returns the starting outer ring index for a given player.
  static int startOuterIndex(int player) {
    assert(player == 1 || player == 2);
    return player == 1 ? player1StartOuterIndex : player2StartOuterIndex;
  }

  /// Returns the starting board position for a given player.
  static BoardPosition startPosition(int player) {
    return outerRing[startOuterIndex(player)];
  }

  /// Checks if a board position is a safe square.
  static bool isSafeSquare(BoardPosition position) {
    return safeSquares.contains(position);
  }

  /// Checks if a board position is on the outer ring.
  static bool isOnOuterRing(BoardPosition position) {
    return outerRing.contains(position);
  }

  /// Checks if a board position is on the inner ring.
  static bool isOnInnerRing(BoardPosition position) {
    return innerRing.contains(position);
  }

  /// Checks if a board position is the center (home).
  static bool isCenter(BoardPosition position) {
    return position == center;
  }

  /// Gets the outer ring index of a position, or -1 if not on outer ring.
  static int outerRingIndexOf(BoardPosition position) {
    return outerRing.indexOf(position);
  }

  /// Gets the inner ring index of a position, or -1 if not on inner ring.
  static int innerRingIndexOf(BoardPosition position) {
    return innerRing.indexOf(position);
  }
}
