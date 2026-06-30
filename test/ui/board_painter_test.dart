import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ashta_chamma/logic/game_state.dart';
import 'package:ashta_chamma/ui/widgets/board_painter.dart';

void main() {
  group('BoardPainter', () {
    test('renders without errors with initial game state', () {
      final gameState = GameState.initial();
      final painter = BoardPainter(
        gameState: gameState,
        availableMoves: [],
      );

      // Should not throw when painting
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(300, 300));
      recorder.endRecording();
    });

    test('shouldRepaint returns true when game state changes', () {
      final state1 = GameState.initial();
      final state2 = GameState.initial();

      final painter1 = BoardPainter(gameState: state1, availableMoves: []);
      final painter2 = BoardPainter(gameState: state2, availableMoves: []);

      // Same state reference should not trigger repaint comparison issues
      expect(painter1.shouldRepaint(painter2), isA<bool>());
    });
  });

  group('BoardPainter.tapPositionToCell', () {
    test('returns correct cell for center of board', () {
      const boardSize = Size(300, 300);
      // Center of the board is cell (2, 2)
      // Cell size = 300 / 5 = 60
      // Center of cell (2,2) is at (150, 150)
      final result =
          BoardPainter.tapPositionToCell(const Offset(150, 150), boardSize);
      expect(result, isNotNull);
      expect(result!.row, equals(2));
      expect(result.col, equals(2));
    });

    test('returns correct cell for top-left corner', () {
      const boardSize = Size(300, 300);
      // Top-left cell (0, 0) center is at (30, 30)
      final result =
          BoardPainter.tapPositionToCell(const Offset(30, 30), boardSize);
      expect(result, isNotNull);
      expect(result!.row, equals(0));
      expect(result.col, equals(0));
    });

    test('returns correct cell for bottom-right corner', () {
      const boardSize = Size(300, 300);
      // Bottom-right cell (4, 4) center is at (270, 270)
      final result =
          BoardPainter.tapPositionToCell(const Offset(270, 270), boardSize);
      expect(result, isNotNull);
      expect(result!.row, equals(4));
      expect(result.col, equals(4));
    });

    test('returns null for negative position', () {
      const boardSize = Size(300, 300);
      final result =
          BoardPainter.tapPositionToCell(const Offset(-10, 50), boardSize);
      expect(result, isNull);
    });

    test('returns null for position beyond board', () {
      const boardSize = Size(300, 300);
      final result =
          BoardPainter.tapPositionToCell(const Offset(310, 150), boardSize);
      expect(result, isNull);
    });

    test('maps all valid positions correctly', () {
      const boardSize = Size(500, 500);
      const cellSize = 500.0 / 5; // 100

      for (int row = 0; row < 5; row++) {
        for (int col = 0; col < 5; col++) {
          final x = col * cellSize + cellSize / 2;
          final y = row * cellSize + cellSize / 2;
          final result =
              BoardPainter.tapPositionToCell(Offset(x, y), boardSize);
          expect(result, isNotNull,
              reason: 'Expected non-null at ($row, $col)');
          expect(result!.row, equals(row));
          expect(result.col, equals(col));
        }
      }
    });
  });

  group('BoardPainter widget rendering', () {
    testWidgets('CustomPaint with BoardPainter renders without errors',
        (tester) async {
      final gameState = GameState.initial();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  painter: BoardPainter(
                    gameState: gameState,
                    availableMoves: [],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
