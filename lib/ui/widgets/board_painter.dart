import 'package:flutter/material.dart';

import '../../logic/board_path.dart';
import '../../logic/game_state.dart';
import '../../logic/move_validator.dart';
import '../../models/board.dart';
import '../../models/pawn.dart';
import '../../models/player.dart';
import '../theme.dart';

/// Callback type for when a cell on the board is tapped.
typedef CellTapCallback = void Function(int row, int col);

/// CustomPainter that draws the 5x5 Ashta Chamma board.
///
/// Renders the board grid, safe squares with X patterns, pawns at their
/// correct positions, and highlights movable pawns during the moving phase.
class BoardPainter extends CustomPainter {
  /// The current game state.
  final GameState gameState;

  /// Available moves for highlighting.
  final List<Move> availableMoves;

  BoardPainter({
    required this.gameState,
    required this.availableMoves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 5;

    _drawBackground(canvas, size);
    _drawGrid(canvas, size, cellSize);
    _drawSafeSquares(canvas, cellSize);
    _drawCenterSquare(canvas, cellSize);
    _drawPawns(canvas, cellSize);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = AshtaChammaTheme.boardBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawGrid(Canvas canvas, Size size, double cellSize) {
    final linePaint = Paint()
      ..color = AshtaChammaTheme.boardLines
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw outer board border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      linePaint,
    );

    // Draw cell boundaries
    for (int i = 1; i < 5; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        linePaint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        linePaint,
      );
    }

    // Draw cell fills for outer and inner rings
    final outerFill = Paint()..color = AshtaChammaTheme.outerRingColor;
    final innerFill = Paint()..color = AshtaChammaTheme.innerRingColor;

    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        final pos = BoardPosition(row, col);
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );
        if (Board.isOnOuterRing(pos)) {
          canvas.drawRect(rect, outerFill);
        } else if (Board.isOnInnerRing(pos)) {
          canvas.drawRect(rect, innerFill);
        }
      }
    }

    // Redraw grid lines on top of fills
    for (int i = 0; i <= 5; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        linePaint,
      );
    }
  }

  void _drawSafeSquares(Canvas canvas, double cellSize) {
    final safeBorderPaint = Paint()
      ..color = AshtaChammaTheme.safeSquareColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final xPaint = Paint()
      ..color = AshtaChammaTheme.safeSquareColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final pos in Board.safeSquares) {
      final rect = Rect.fromLTWH(
        pos.col * cellSize,
        pos.row * cellSize,
        cellSize,
        cellSize,
      );

      // Draw gold border
      canvas.drawRect(rect, safeBorderPaint);

      // Draw X pattern
      final padding = cellSize * 0.15;
      canvas.drawLine(
        Offset(rect.left + padding, rect.top + padding),
        Offset(rect.right - padding, rect.bottom - padding),
        xPaint,
      );
      canvas.drawLine(
        Offset(rect.right - padding, rect.top + padding),
        Offset(rect.left + padding, rect.bottom - padding),
        xPaint,
      );
    }
  }

  void _drawCenterSquare(Canvas canvas, double cellSize) {
    final centerPaint = Paint()..color = AshtaChammaTheme.centerColor;
    final rect = Rect.fromLTWH(
      2 * cellSize,
      2 * cellSize,
      cellSize,
      cellSize,
    );
    canvas.drawRect(rect, centerPaint);

    // Draw a decorative border on center
    final borderPaint = Paint()
      ..color = AshtaChammaTheme.deepRed
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);
  }

  void _drawPawns(Canvas canvas, double cellSize) {
    // Collect pawn positions for both players
    final pawnPositions = <String, List<_PawnInfo>>{};

    _collectPawnPositions(gameState.player1, pawnPositions);
    _collectPawnPositions(gameState.player2, pawnPositions);

    // Draw pawns at their positions
    for (final entry in pawnPositions.entries) {
      final pawns = entry.value;
      if (pawns.isEmpty) continue;

      final row = pawns.first.row;
      final col = pawns.first.col;
      final centerX = col * cellSize + cellSize / 2;
      final centerY = row * cellSize + cellSize / 2;
      final radius = cellSize * 0.25;

      if (pawns.length == 1) {
        _drawSinglePawn(canvas, centerX, centerY, radius, pawns.first);
      } else {
        // Multiple pawns on same square - offset them
        _drawMultiplePawns(canvas, centerX, centerY, radius, cellSize, pawns);
      }
    }
  }

  void _collectPawnPositions(
      Player player, Map<String, List<_PawnInfo>> positions) {
    for (final pawn in player.pawns) {
      if (pawn.state == PawnState.atHome) {
        continue;
      }

      BoardPosition? pos;
      if (pawn.state == PawnState.atStart) {
        // Render start pawns at their entry corner so players can tap them
        pos = Board.startPosition(pawn.player);
      } else {
        pos = BoardPath.getPositionAtStep(pawn.player, pawn.stepsCompleted);
      }
      if (pos == null) continue;

      final key = '${pos.row},${pos.col}';
      positions.putIfAbsent(key, () => []);
      positions[key]!.add(_PawnInfo(
        row: pos.row,
        col: pos.col,
        player: pawn.player,
        pawnIndex: pawn.pawnIndex,
        isMovable: _isPawnMovable(pawn),
        isAtStart: pawn.state == PawnState.atStart,
      ));
    }
  }

  bool _isPawnMovable(Pawn pawn) {
    return availableMoves.any((m) => m.pawn.pawnIndex == pawn.pawnIndex &&
        m.pawn.player == pawn.player);
  }

  void _drawSinglePawn(
      Canvas canvas, double cx, double cy, double radius, _PawnInfo pawn) {
    final baseColor = pawn.player == 1
        ? AshtaChammaTheme.player1Color
        : AshtaChammaTheme.player2Color;

    // Pawns at start are rendered semi-transparent to distinguish from
    // on-board pawns while still providing a visible tap target.
    final color = pawn.isAtStart ? baseColor.withAlpha(160) : baseColor;

    final fillPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    // Draw a dashed-style inner ring for at-start pawns to indicate they
    // need to be entered onto the board
    if (pawn.isAtStart) {
      final innerPaint = Paint()
        ..color = Colors.white.withAlpha(180)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, cy), radius * 0.6, innerPaint);
    }

    // Highlight if movable
    if (pawn.isMovable && gameState.phase == GamePhase.moving) {
      final highlightPaint = Paint()
        ..color = AshtaChammaTheme.gold
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, cy), radius + 3, highlightPaint);
    }
  }

  void _drawMultiplePawns(Canvas canvas, double cx, double cy, double radius,
      double cellSize, List<_PawnInfo> pawns) {
    final smallRadius = radius * 0.7;
    final offsets = _getMultiPawnOffsets(pawns.length, cellSize * 0.15);

    for (int i = 0; i < pawns.length; i++) {
      final offset = i < offsets.length ? offsets[i] : Offset.zero;
      _drawSinglePawn(
        canvas,
        cx + offset.dx,
        cy + offset.dy,
        smallRadius,
        pawns[i],
      );
    }

    // Draw count badge
    if (pawns.length > 1) {
      final badgePaint = Paint()..color = AshtaChammaTheme.textColor;
      final badgeRadius = smallRadius * 0.5;
      canvas.drawCircle(
        Offset(cx + cellSize * 0.25, cy - cellSize * 0.25),
        badgeRadius,
        badgePaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${pawns.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          cx + cellSize * 0.25 - textPainter.width / 2,
          cy - cellSize * 0.25 - textPainter.height / 2,
        ),
      );
    }
  }

  List<Offset> _getMultiPawnOffsets(int count, double spacing) {
    switch (count) {
      case 2:
        return [Offset(-spacing, 0), Offset(spacing, 0)];
      case 3:
        return [
          Offset(-spacing, spacing),
          Offset(spacing, spacing),
          Offset(0, -spacing),
        ];
      case 4:
        return [
          Offset(-spacing, -spacing),
          Offset(spacing, -spacing),
          Offset(-spacing, spacing),
          Offset(spacing, spacing),
        ];
      default:
        return [Offset.zero];
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.gameState != gameState ||
        oldDelegate.availableMoves != availableMoves;
  }

  /// Converts a tap position to a board cell (row, col).
  /// Returns null if the tap is outside the board.
  static BoardPosition? tapPositionToCell(Offset tapPosition, Size boardSize) {
    final cellSize = boardSize.width / 5;
    final col = (tapPosition.dx / cellSize).floor();
    final row = (tapPosition.dy / cellSize).floor();

    if (row < 0 || row > 4 || col < 0 || col > 4) {
      return null;
    }

    return BoardPosition(row, col);
  }
}

/// Internal helper class for pawn rendering information.
class _PawnInfo {
  final int row;
  final int col;
  final int player;
  final int pawnIndex;
  final bool isMovable;
  final bool isAtStart;

  const _PawnInfo({
    required this.row,
    required this.col,
    required this.player,
    required this.pawnIndex,
    required this.isMovable,
    this.isAtStart = false,
  });
}
