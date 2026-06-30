import 'pawn.dart';

/// Represents a player in the game.
class Player {
  /// Player number (1 or 2).
  final int id;

  /// The player's 4 pawns.
  final List<Pawn> pawns;

  /// Whether this player has hit at least one opponent pawn.
  /// Required before any of this player's pawns can enter the inner ring.
  final bool hasHitOpponent;

  Player({
    required this.id,
    List<Pawn>? pawns,
    this.hasHitOpponent = false,
  }) : pawns = pawns ??
            List.generate(
              4,
              (i) => Pawn(player: id, pawnIndex: i),
            );

  /// Returns the number of pawns still at start.
  int get pawnsAtStart =>
      pawns.where((p) => p.state == PawnState.atStart).length;

  /// Returns the number of pawns currently on the board.
  int get pawnsOnBoard =>
      pawns.where((p) => p.state == PawnState.onBoard).length;

  /// Returns the number of pawns that have reached home.
  int get pawnsAtHome =>
      pawns.where((p) => p.state == PawnState.atHome).length;

  /// Whether all pawns have reached home (player has won).
  bool get hasWon => pawnsAtHome == 4;

  /// Returns pawns that are currently on the board.
  List<Pawn> get activePawns =>
      pawns.where((p) => p.state == PawnState.onBoard).toList();

  /// Returns pawns that are still at start.
  List<Pawn> get startPawns =>
      pawns.where((p) => p.state == PawnState.atStart).toList();

  /// Creates a copy of this player with optional field changes.
  Player copyWith({
    List<Pawn>? pawns,
    bool? hasHitOpponent,
  }) {
    return Player(
      id: id,
      pawns: pawns ?? List.from(this.pawns),
      hasHitOpponent: hasHitOpponent ?? this.hasHitOpponent,
    );
  }

  /// Returns a new Player with one pawn updated.
  Player updatePawn(int pawnIndex, Pawn newPawn) {
    final newPawns = List<Pawn>.from(pawns);
    newPawns[pawnIndex] = newPawn;
    return copyWith(pawns: newPawns);
  }

  @override
  String toString() =>
      'Player(id: $id, pawnsAtStart: $pawnsAtStart, pawnsOnBoard: $pawnsOnBoard, pawnsAtHome: $pawnsAtHome, hasHitOpponent: $hasHitOpponent)';
}
