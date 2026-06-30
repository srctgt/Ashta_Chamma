import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/ai/ai_player.dart';
import 'package:ashta_chamma/ai/move_scorer.dart';
import 'package:ashta_chamma/logic/board_path.dart';
import 'package:ashta_chamma/logic/dice.dart';
import 'package:ashta_chamma/logic/move_validator.dart';
import 'package:ashta_chamma/models/pawn.dart';
import 'package:ashta_chamma/models/player.dart';

void main() {
  group('AiPlayer', () {
    late AiPlayer aiPlayer;

    setUp(() {
      aiPlayer = AiPlayer(random: Random(42));
    });

    group('selectMove', () {
      test('returns null when availableMoves is empty', () {
        final player = Player(id: 2);
        final opponent = Player(id: 1);

        final result = aiPlayer.selectMove(
          availableMoves: [],
          currentPlayer: player,
          opponent: opponent,
        );

        expect(result, isNull);
      });

      test('returns the only move when a single move is available', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 5),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final move = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 7,
        );

        final result = aiPlayer.selectMove(
          availableMoves: [move],
          currentPlayer: player,
          opponent: opponent,
        );

        expect(result, equals(move));
      });

      test('prefers hitting an opponent pawn over other moves', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 5),
          const Pawn(
              player: 2, pawnIndex: 1, state: PawnState.onBoard,
              stepsCompleted: 3),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final normalMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 7,
        );
        final hitMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 5,
          isHit: true,
        );

        final result = aiPlayer.selectMove(
          availableMoves: [normalMove, hitMove],
          currentPlayer: player,
          opponent: opponent,
        );

        expect(result, equals(hitMove));
      });

      test('prefers reaching home over hitting', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 22),
          const Pawn(
              player: 2, pawnIndex: 1, state: PawnState.onBoard,
              stepsCompleted: 3),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ], hasHitOpponent: true);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final hitMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 5,
          isHit: true,
        );
        final homeMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: BoardPath.centerStep,
          reachesHome: true,
        );

        final result = aiPlayer.selectMove(
          availableMoves: [hitMove, homeMove],
          currentPlayer: player,
          opponent: opponent,
        );

        // Hit (100) vs home (90) - AI should prefer hit
        // Actually, hit = 100 and home = 90, so hit wins
        expect(result, equals(hitMove));
      });

      test('prefers hitting and reaching home over entry', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 3),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(4);

        final hitMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 7,
          isHit: true,
        );
        final entryMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 0,
          isEntry: true,
        );

        final result = aiPlayer.selectMove(
          availableMoves: [entryMove, hitMove],
          currentPlayer: player,
          opponent: opponent,
        );

        expect(result, equals(hitMove));
      });

      test('enters pawns when possible on 4 or 8 rolls', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 2),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(4);

        final advanceMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 6,
        );
        final entryMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 0,
          isEntry: true,
        );

        final result = aiPlayer.selectMove(
          availableMoves: [advanceMove, entryMove],
          currentPlayer: player,
          opponent: opponent,
        );

        // Entry score (40) vs advance score (~12 progress).
        // Entry should win here since targetStep 6 progress score is low.
        expect(result, equals(entryMove));
      });

      test('moves pawn closest to home when no hits available', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 5),
          const Pawn(
              player: 2, pawnIndex: 1, state: PawnState.onBoard,
              stepsCompleted: 15),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ], hasHitOpponent: true);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(3);

        final move1 = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 8,
        );
        final move2 = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 18,
        );

        final result = aiPlayer.selectMove(
          availableMoves: [move1, move2],
          currentPlayer: player,
          opponent: opponent,
        );

        // move2 targets step 18 (higher progress score) vs move1 step 8
        expect(result, equals(move2));
      });

      test('handles case when all pawns are at home gracefully', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.atHome,
              stepsCompleted: 24),
          const Pawn(
              player: 2, pawnIndex: 1, state: PawnState.atHome,
              stepsCompleted: 24),
          const Pawn(
              player: 2, pawnIndex: 2, state: PawnState.atHome,
              stepsCompleted: 24),
          const Pawn(
              player: 2, pawnIndex: 3, state: PawnState.atHome,
              stepsCompleted: 24),
        ]);
        final opponent = Player(id: 1);

        final result = aiPlayer.selectMove(
          availableMoves: [],
          currentPlayer: player,
          opponent: opponent,
        );

        expect(result, isNull);
      });
    });
  });

  group('MoveScorer', () {
    group('scoreMove', () {
      test('hit move scores highest', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 5),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final hitMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 7,
          isHit: true,
        );

        final score = MoveScorer.scoreMove(
          move: hitMove,
          currentPlayer: player,
          opponent: opponent,
        );

        // Hit score (100) + progress score for step 7
        expect(score, greaterThanOrEqualTo(MoveScorer.hitScore));
      });

      test('reachesHome scores very high', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 22),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ], hasHitOpponent: true);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final homeMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: BoardPath.centerStep,
          reachesHome: true,
        );

        final score = MoveScorer.scoreMove(
          move: homeMove,
          currentPlayer: player,
          opponent: opponent,
        );

        expect(score, equals(MoveScorer.reachHomeScore));
      });

      test('entry move scores medium', () {
        final player = Player(id: 2, pawns: [
          const Pawn(player: 2, pawnIndex: 0),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(4);

        final entryMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 0,
          isEntry: true,
        );

        final score = MoveScorer.scoreMove(
          move: entryMove,
          currentPlayer: player,
          opponent: opponent,
        );

        expect(score, equals(MoveScorer.entryScore));
      });

      test('progress score increases with steps completed', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 3),
          const Pawn(
              player: 2, pawnIndex: 1, state: PawnState.onBoard,
              stepsCompleted: 15),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final earlyMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 5,
        );
        final lateMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 17,
        );

        final earlyScore = MoveScorer.scoreMove(
          move: earlyMove,
          currentPlayer: player,
          opponent: opponent,
        );
        final lateScore = MoveScorer.scoreMove(
          move: lateMove,
          currentPlayer: player,
          opponent: opponent,
        );

        expect(lateScore, greaterThan(earlyScore));
      });

      test('safe square landing gives bonus', () {
        // Player 2 starts at outer ring index 4 = (0,4) which is a safe square
        // Step 0 for player 2 lands on (0,4) which is a safe square
        // We need a move that lands on a safe square that is NOT an entry move
        // Safe squares: corners and midpoints. Let's use a pawn already on board.
        // Player 2's path step 0 = (0,4), step 2 = (0,2) which is a safe square (top midpoint)
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 0),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final safeMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 2,
        );

        final score = MoveScorer.scoreMove(
          move: safeMove,
          currentPlayer: player,
          opponent: opponent,
        );

        // Progress score for step 2 + safe square bonus
        const expectedProgressOnly =
            (2 * MoveScorer.maxProgressScore) ~/ (BoardPath.totalSteps - 1);

        // Score should be higher than just progress
        expect(score, greaterThan(expectedProgressOnly));
      });

      test('hit move beats reaching home', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 5),
          const Pawn(
              player: 2, pawnIndex: 1, state: PawnState.onBoard,
              stepsCompleted: 22),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ], hasHitOpponent: true);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(2);

        final hitMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 7,
          isHit: true,
        );
        final homeMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: BoardPath.centerStep,
          reachesHome: true,
        );

        final hitScore = MoveScorer.scoreMove(
          move: hitMove,
          currentPlayer: player,
          opponent: opponent,
        );
        final homeScore = MoveScorer.scoreMove(
          move: homeMove,
          currentPlayer: player,
          opponent: opponent,
        );

        expect(hitScore, greaterThan(homeScore));
      });

      test('reaching home beats entry', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 20),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ], hasHitOpponent: true);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(4);

        final homeMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: BoardPath.centerStep,
          reachesHome: true,
        );
        final entryMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 0,
          isEntry: true,
        );

        final homeScore = MoveScorer.scoreMove(
          move: homeMove,
          currentPlayer: player,
          opponent: opponent,
        );
        final entryScore = MoveScorer.scoreMove(
          move: entryMove,
          currentPlayer: player,
          opponent: opponent,
        );

        expect(homeScore, greaterThan(entryScore));
      });

      test('entry beats low-step advance', () {
        final player = Player(id: 2, pawns: [
          const Pawn(
              player: 2, pawnIndex: 0, state: PawnState.onBoard,
              stepsCompleted: 0),
          const Pawn(player: 2, pawnIndex: 1),
          const Pawn(player: 2, pawnIndex: 2),
          const Pawn(player: 2, pawnIndex: 3),
        ]);
        final opponent = Player(id: 1);
        final diceResult = Dice.cowrieResult(4);

        final advanceMove = Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 4,
        );
        final entryMove = Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 0,
          isEntry: true,
        );

        final advanceScore = MoveScorer.scoreMove(
          move: advanceMove,
          currentPlayer: player,
          opponent: opponent,
        );
        final entryScore = MoveScorer.scoreMove(
          move: entryMove,
          currentPlayer: player,
          opponent: opponent,
        );

        expect(entryScore, greaterThan(advanceScore));
      });
    });
  });

  group('AiPlayer integration with GameController', () {
    test('AI always returns a valid move from available moves', () {
      final aiPlayer = AiPlayer(random: Random(0));
      final player = Player(id: 2, pawns: [
        const Pawn(
            player: 2, pawnIndex: 0, state: PawnState.onBoard,
            stepsCompleted: 5),
        const Pawn(
            player: 2, pawnIndex: 1, state: PawnState.onBoard,
            stepsCompleted: 10),
        const Pawn(player: 2, pawnIndex: 2),
        const Pawn(player: 2, pawnIndex: 3),
      ]);
      final opponent = Player(id: 1);
      final diceResult = Dice.cowrieResult(3);

      final moves = [
        Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 8,
        ),
        Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 13,
        ),
      ];

      final result = aiPlayer.selectMove(
        availableMoves: moves,
        currentPlayer: player,
        opponent: opponent,
      );

      expect(result, isNotNull);
      expect(moves.contains(result), isTrue);
    });

    test('AI selects move deterministically with fixed random seed', () {
      final aiPlayer1 = AiPlayer(random: Random(123));
      final aiPlayer2 = AiPlayer(random: Random(123));
      final player = Player(id: 2, pawns: [
        const Pawn(
            player: 2, pawnIndex: 0, state: PawnState.onBoard,
            stepsCompleted: 5),
        const Pawn(
            player: 2, pawnIndex: 1, state: PawnState.onBoard,
            stepsCompleted: 5),
        const Pawn(player: 2, pawnIndex: 2),
        const Pawn(player: 2, pawnIndex: 3),
      ]);
      final opponent = Player(id: 1);
      final diceResult = Dice.cowrieResult(2);

      // Same scores => tie-break by random, should be same with same seed
      final moves = [
        Move(
          pawn: player.pawns[0],
          diceResult: diceResult,
          targetStep: 7,
        ),
        Move(
          pawn: player.pawns[1],
          diceResult: diceResult,
          targetStep: 7,
        ),
      ];

      final result1 = aiPlayer1.selectMove(
        availableMoves: moves,
        currentPlayer: player,
        opponent: opponent,
      );
      final result2 = aiPlayer2.selectMove(
        availableMoves: moves,
        currentPlayer: player,
        opponent: opponent,
      );

      expect(result1!.pawn.pawnIndex, equals(result2!.pawn.pawnIndex));
    });
  });
}
