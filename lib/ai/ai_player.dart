import 'dart:math';

import '../logic/move_validator.dart';
import '../models/player.dart';
import 'move_scorer.dart';

/// AI opponent that selects moves based on heuristic scoring.
///
/// Evaluates all available moves using [MoveScorer] and selects the move
/// with the highest score. When multiple moves have the same score, one
/// is chosen randomly.
class AiPlayer {
  /// Random instance for tie-breaking.
  final Random _random;

  /// Creates an AI player.
  ///
  /// An optional [random] parameter can be provided for deterministic
  /// behavior in tests.
  AiPlayer({Random? random}) : _random = random ?? Random();

  /// Selects the best move from the available moves.
  ///
  /// Parameters:
  /// - [availableMoves]: List of valid moves to choose from.
  /// - [currentPlayer]: The AI's player state.
  /// - [opponent]: The opponent's player state.
  ///
  /// Returns the best move, or null if [availableMoves] is empty.
  Move? selectMove({
    required List<Move> availableMoves,
    required Player currentPlayer,
    required Player opponent,
  }) {
    if (availableMoves.isEmpty) {
      return null;
    }

    // Score all available moves
    final scoredMoves = <_ScoredMove>[];
    for (final move in availableMoves) {
      final score = MoveScorer.scoreMove(
        move: move,
        currentPlayer: currentPlayer,
        opponent: opponent,
      );
      scoredMoves.add(_ScoredMove(move: move, score: score));
    }

    // Find the maximum score
    final maxScore = scoredMoves
        .map((sm) => sm.score)
        .reduce((a, b) => a > b ? a : b);

    // Collect all moves with the maximum score (for tie-breaking)
    final bestMoves =
        scoredMoves.where((sm) => sm.score == maxScore).toList();

    // Pick randomly among tied best moves
    return bestMoves[_random.nextInt(bestMoves.length)].move;
  }
}

/// Internal class pairing a move with its computed score.
class _ScoredMove {
  final Move move;
  final int score;

  const _ScoredMove({required this.move, required this.score});
}
