import 'package:flutter/material.dart';

import '../../logic/board_path.dart';
import '../../models/pawn.dart';
import '../../models/player.dart';
import '../theme.dart';

/// Helper utilities for drawing pawns on the board.
///
/// This is not a standalone widget but provides painting helpers
/// used by [BoardPainter] and other board-related UI elements.
/// It also provides widgets for displaying pawn counts in info panels.
class PawnHelper {
  PawnHelper._();

  /// Gets the color for a player's pawns.
  static Color getPlayerColor(int playerId) {
    return playerId == 1
        ? AshtaChammaTheme.player1Color
        : AshtaChammaTheme.player2Color;
  }

  /// Gets the display name for a player.
  static String getPlayerName(int playerId) {
    return 'Player $playerId';
  }

  /// Returns the board position for a pawn, or null if not on board.
  static ({int row, int col})? getPawnBoardPosition(Pawn pawn) {
    if (pawn.state != PawnState.onBoard) return null;
    final pos = BoardPath.getPositionAtStep(pawn.player, pawn.stepsCompleted);
    if (pos == null) return null;
    return (row: pos.row, col: pos.col);
  }

  /// Counts pawns of a player at a specific board position.
  static int countPawnsAtPosition(Player player, int row, int col) {
    int count = 0;
    for (final pawn in player.activePawns) {
      final pos = BoardPath.getPositionAtStep(pawn.player, pawn.stepsCompleted);
      if (pos != null && pos.row == row && pos.col == col) {
        count++;
      }
    }
    return count;
  }
}

/// A small pawn indicator widget for use in info panels.
class PawnIndicator extends StatelessWidget {
  /// The player ID (1 or 2).
  final int playerId;

  /// The size of the indicator.
  final double size;

  /// Whether to show a highlight border.
  final bool highlighted;

  const PawnIndicator({
    super.key,
    required this.playerId,
    this.size = 20,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PawnHelper.getPlayerColor(playerId),
        border: Border.all(
          color: highlighted ? AshtaChammaTheme.gold : Colors.white,
          width: highlighted ? 3 : 1.5,
        ),
      ),
    );
  }
}
