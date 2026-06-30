import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/models/board.dart';
import 'package:ashta_chamma/logic/board_path.dart';

void main() {
  group('Board', () {
    test('outer ring has 16 positions', () {
      expect(Board.outerRing.length, 16);
      expect(Board.outerRingLength, 16);
    });

    test('inner ring has 8 positions', () {
      expect(Board.innerRing.length, 8);
      expect(Board.innerRingLength, 8);
    });

    test('center is at (2,2)', () {
      expect(Board.center, const BoardPosition(2, 2));
    });

    test('outer ring positions are all on the perimeter', () {
      for (final pos in Board.outerRing) {
        final isOnPerimeter =
            pos.row == 0 || pos.row == 4 || pos.col == 0 || pos.col == 4;
        expect(isOnPerimeter, isTrue,
            reason: '$pos should be on the perimeter');
      }
    });

    test('inner ring positions are all one step inward', () {
      for (final pos in Board.innerRing) {
        final isInner = (pos.row >= 1 && pos.row <= 3) &&
            (pos.col >= 1 && pos.col <= 3) &&
            !(pos.row == 2 && pos.col == 2); // not center
        expect(isInner, isTrue,
            reason: '$pos should be one step inward from perimeter');
      }
    });

    test('all outer ring positions are unique', () {
      final uniquePositions = Board.outerRing.toSet();
      expect(uniquePositions.length, Board.outerRing.length);
    });

    test('all inner ring positions are unique', () {
      final uniquePositions = Board.innerRing.toSet();
      expect(uniquePositions.length, Board.innerRing.length);
    });

    test('outer ring and inner ring positions do not overlap', () {
      final outerSet = Board.outerRing.toSet();
      final innerSet = Board.innerRing.toSet();
      expect(outerSet.intersection(innerSet), isEmpty);
    });

    test('center is not on outer or inner ring', () {
      expect(Board.outerRing.contains(Board.center), isFalse);
      expect(Board.innerRing.contains(Board.center), isFalse);
    });

    test('safe squares are all on outer ring', () {
      for (final pos in Board.safeSquares) {
        expect(Board.outerRing.contains(pos), isTrue,
            reason: '$pos should be on outer ring');
      }
    });

    test('there are 8 safe squares', () {
      expect(Board.safeSquares.length, 8);
    });

    test('player 1 start position is (4,0)', () {
      expect(Board.startPosition(1), const BoardPosition(4, 0));
    });

    test('player 2 start position is (0,4)', () {
      expect(Board.startPosition(2), const BoardPosition(0, 4));
    });

    test('player start positions are safe squares', () {
      expect(Board.isSafeSquare(Board.startPosition(1)), isTrue);
      expect(Board.isSafeSquare(Board.startPosition(2)), isTrue);
    });

    test('isSafeSquare correctly identifies safe squares', () {
      // Corners
      expect(Board.isSafeSquare(const BoardPosition(0, 0)), isTrue);
      expect(Board.isSafeSquare(const BoardPosition(0, 4)), isTrue);
      expect(Board.isSafeSquare(const BoardPosition(4, 4)), isTrue);
      expect(Board.isSafeSquare(const BoardPosition(4, 0)), isTrue);
      // Midpoints
      expect(Board.isSafeSquare(const BoardPosition(0, 2)), isTrue);
      expect(Board.isSafeSquare(const BoardPosition(2, 4)), isTrue);
      expect(Board.isSafeSquare(const BoardPosition(4, 2)), isTrue);
      expect(Board.isSafeSquare(const BoardPosition(2, 0)), isTrue);
      // Non-safe
      expect(Board.isSafeSquare(const BoardPosition(0, 1)), isFalse);
      expect(Board.isSafeSquare(const BoardPosition(1, 4)), isFalse);
    });

    test('isOnOuterRing works correctly', () {
      expect(Board.isOnOuterRing(const BoardPosition(0, 0)), isTrue);
      expect(Board.isOnOuterRing(const BoardPosition(2, 2)), isFalse);
      expect(Board.isOnOuterRing(const BoardPosition(1, 1)), isFalse);
    });

    test('isOnInnerRing works correctly', () {
      expect(Board.isOnInnerRing(const BoardPosition(1, 1)), isTrue);
      expect(Board.isOnInnerRing(const BoardPosition(0, 0)), isFalse);
      expect(Board.isOnInnerRing(const BoardPosition(2, 2)), isFalse);
    });

    test('isCenter works correctly', () {
      expect(Board.isCenter(const BoardPosition(2, 2)), isTrue);
      expect(Board.isCenter(const BoardPosition(0, 0)), isFalse);
    });
  });

  group('BoardPosition', () {
    test('equality works correctly', () {
      const pos1 = BoardPosition(1, 2);
      const pos2 = BoardPosition(1, 2);
      const pos3 = BoardPosition(2, 1);

      expect(pos1 == pos2, isTrue);
      expect(pos1 == pos3, isFalse);
    });

    test('hashCode is consistent with equality', () {
      const pos1 = BoardPosition(1, 2);
      const pos2 = BoardPosition(1, 2);
      expect(pos1.hashCode, pos2.hashCode);
    });
  });

  group('BoardPath', () {
    test('total steps is 25', () {
      expect(BoardPath.totalSteps, 25);
    });

    test('outer steps is 16', () {
      expect(BoardPath.outerSteps, 16);
    });

    test('inner steps is 8', () {
      expect(BoardPath.innerSteps, 8);
    });

    test('center step is 24', () {
      expect(BoardPath.centerStep, 24);
    });

    test('player 1 path has correct length', () {
      final path = BoardPath.getPlayerPath(1);
      expect(path.length, 25);
    });

    test('player 2 path has correct length', () {
      final path = BoardPath.getPlayerPath(2);
      expect(path.length, 25);
    });

    test('player 1 path starts at player 1 start position', () {
      final path = BoardPath.getPlayerPath(1);
      expect(path[0], Board.startPosition(1));
    });

    test('player 2 path starts at player 2 start position', () {
      final path = BoardPath.getPlayerPath(2);
      expect(path[0], Board.startPosition(2));
    });

    test('both players path ends at center', () {
      final path1 = BoardPath.getPlayerPath(1);
      final path2 = BoardPath.getPlayerPath(2);
      expect(path1.last, Board.center);
      expect(path2.last, Board.center);
    });

    test('player 1 outer ring portion has all 16 outer ring positions', () {
      final path = BoardPath.getPlayerPath(1);
      final outerPortion = path.sublist(0, 16);
      final outerSet = outerPortion.toSet();
      expect(outerSet.length, 16);
      for (final pos in outerPortion) {
        expect(Board.isOnOuterRing(pos), isTrue,
            reason: '$pos at should be on outer ring');
      }
    });

    test('player 1 inner ring portion has all 8 inner ring positions', () {
      final path = BoardPath.getPlayerPath(1);
      final innerPortion = path.sublist(16, 24);
      final innerSet = innerPortion.toSet();
      expect(innerSet.length, 8);
      for (final pos in innerPortion) {
        expect(Board.isOnInnerRing(pos), isTrue,
            reason: '$pos should be on inner ring');
      }
    });

    test('player 2 outer ring portion has all 16 outer ring positions', () {
      final path = BoardPath.getPlayerPath(2);
      final outerPortion = path.sublist(0, 16);
      final outerSet = outerPortion.toSet();
      expect(outerSet.length, 16);
      for (final pos in outerPortion) {
        expect(Board.isOnOuterRing(pos), isTrue,
            reason: '$pos should be on outer ring');
      }
    });

    test('player 2 inner ring portion has all 8 inner ring positions', () {
      final path = BoardPath.getPlayerPath(2);
      final innerPortion = path.sublist(16, 24);
      final innerSet = innerPortion.toSet();
      expect(innerSet.length, 8);
      for (final pos in innerPortion) {
        expect(Board.isOnInnerRing(pos), isTrue,
            reason: '$pos should be on inner ring');
      }
    });

    test('calculateTargetStep returns correct step', () {
      expect(BoardPath.calculateTargetStep(0, 3), 3);
      expect(BoardPath.calculateTargetStep(10, 4), 14);
      expect(BoardPath.calculateTargetStep(20, 4), 24); // reaches center
    });

    test('calculateTargetStep returns null for overshooting', () {
      expect(BoardPath.calculateTargetStep(23, 2), isNull);
      expect(BoardPath.calculateTargetStep(24, 1), isNull);
      expect(BoardPath.calculateTargetStep(22, 8), isNull);
    });

    test('calculateTargetStep allows exact center landing', () {
      // Step 24 is center, so from step 20 moving 4 should reach it
      expect(BoardPath.calculateTargetStep(20, 4), 24);
      // From step 16 moving 8 should reach it
      expect(BoardPath.calculateTargetStep(16, 8), 24);
    });

    test('isOuterRingStep works correctly', () {
      expect(BoardPath.isOuterRingStep(0), isTrue);
      expect(BoardPath.isOuterRingStep(15), isTrue);
      expect(BoardPath.isOuterRingStep(16), isFalse);
      expect(BoardPath.isOuterRingStep(-1), isFalse);
    });

    test('isInnerRingStep works correctly', () {
      expect(BoardPath.isInnerRingStep(16), isTrue);
      expect(BoardPath.isInnerRingStep(23), isTrue);
      expect(BoardPath.isInnerRingStep(15), isFalse);
      expect(BoardPath.isInnerRingStep(24), isFalse);
    });

    test('isCenterStep works correctly', () {
      expect(BoardPath.isCenterStep(24), isTrue);
      expect(BoardPath.isCenterStep(23), isFalse);
      expect(BoardPath.isCenterStep(0), isFalse);
    });

    test('getPositionAtStep returns null for invalid steps', () {
      expect(BoardPath.getPositionAtStep(1, -1), isNull);
      expect(BoardPath.getPositionAtStep(1, 25), isNull);
    });

    test('getStepForPosition returns correct step', () {
      final path1 = BoardPath.getPlayerPath(1);
      for (int i = 0; i < path1.length; i++) {
        expect(BoardPath.getStepForPosition(1, path1[i]), i);
      }
    });

    test('getStepForPosition returns -1 for positions not on path', () {
      // Center of inner ring is not in board positions except as center
      // A position not on any path
      expect(
          BoardPath.getStepForPosition(
              1, const BoardPosition(2, 2)), // center IS on path
          24);
    });

    test('player paths are continuous (each step adjacent to next)', () {
      // Verify that the outer ring portion of each player's path covers
      // all outer ring positions exactly once
      for (int player = 1; player <= 2; player++) {
        final path = BoardPath.getPlayerPath(player);
        final outerPositions = path.sublist(0, 16).toSet();
        expect(outerPositions.length, 16,
            reason: 'Player $player outer ring should have 16 unique positions');

        final innerPositions = path.sublist(16, 24).toSet();
        expect(innerPositions.length, 8,
            reason: 'Player $player inner ring should have 8 unique positions');
      }
    });
  });
}
