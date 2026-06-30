/// Represents the state of a pawn on the board.
enum PawnState {
  /// Pawn has not yet entered the board.
  atStart,

  /// Pawn is on the board (outer or inner ring).
  onBoard,

  /// Pawn has reached the center (home).
  atHome,
}

/// Represents a single pawn in the game.
class Pawn {
  /// Which player owns this pawn (1 or 2).
  final int player;

  /// Index of this pawn for the player (0-3).
  final int pawnIndex;

  /// Current state of the pawn.
  final PawnState state;

  /// Number of steps completed along the player's path.
  /// 0 = at start position on the board (first step on outer ring).
  /// Only meaningful when state is [PawnState.onBoard].
  final int stepsCompleted;

  const Pawn({
    required this.player,
    required this.pawnIndex,
    this.state = PawnState.atStart,
    this.stepsCompleted = 0,
  });

  /// Whether this pawn has entered the board.
  bool get hasEnteredBoard => state != PawnState.atStart;

  /// Whether this pawn has reached home (center).
  bool get isHome => state == PawnState.atHome;

  /// Whether this pawn is currently on the board (not at start, not at home).
  bool get isOnBoard => state == PawnState.onBoard;

  /// Creates a copy of this pawn with optional field changes.
  Pawn copyWith({
    PawnState? state,
    int? stepsCompleted,
  }) {
    return Pawn(
      player: player,
      pawnIndex: pawnIndex,
      state: state ?? this.state,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Pawn &&
      other.player == player &&
      other.pawnIndex == pawnIndex &&
      other.state == state &&
      other.stepsCompleted == stepsCompleted;

  @override
  int get hashCode =>
      player.hashCode ^
      pawnIndex.hashCode ^
      state.hashCode ^
      stepsCompleted.hashCode;

  @override
  String toString() =>
      'Pawn(player: $player, index: $pawnIndex, state: $state, steps: $stepsCompleted)';
}
