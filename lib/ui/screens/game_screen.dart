import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/board_path.dart';
import '../../models/board.dart';
import '../game_provider.dart';
import '../theme.dart';
import '../widgets/board_painter.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_info_panel.dart';

/// Main game screen combining the board, dice, and info panel.
///
/// Layout: game info panel (top), board (center), dice widget (bottom).
/// Handles user interactions and AI turn execution.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ashta Chamma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context),
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Game info panel
              GameInfoPanel(
                player1: provider.gameState.player1,
                player2: provider.gameState.player2,
                currentPlayerId: provider.gameState.currentPlayerId,
                statusMessage: provider.statusMessage,
                phase: provider.gameState.phase,
                gameMode: provider.gameMode,
                hasBonusTurn: provider.gameState.hasBonusTurn,
              ),
              // Board area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTapUp: (details) => _handleBoardTap(
                              context,
                              details.localPosition,
                              constraints.biggest,
                              provider,
                            ),
                            child: CustomPaint(
                              size: constraints.biggest,
                              painter: BoardPainter(
                                gameState: provider.gameState,
                                availableMoves: provider.availableMoves,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Dice widget
              DiceWidget(
                diceResult: provider.diceResult,
                diceMode: provider.diceMode,
                canRoll: provider.isRolling && !provider.isAiTurn,
                phase: provider.gameState.phase,
                onRoll: () => provider.rollDice(),
              ),
              // Win overlay
              if (provider.isGameOver) _buildWinBanner(provider),
            ],
          );
        },
      ),
    );
  }

  void _handleBoardTap(
    BuildContext context,
    Offset tapPosition,
    Size boardSize,
    GameProvider provider,
  ) {
    if (!provider.isMoving || provider.isAiTurn) return;

    final cell = BoardPainter.tapPositionToCell(tapPosition, boardSize);
    if (cell == null) return;

    // Find which pawn is at the tapped cell that has a valid move
    for (final move in provider.availableMoves) {
      final pawn = move.pawn;
      BoardPosition? pawnPosition;

      if (move.isEntry) {
        // Entry moves: the pawn is at start, check if user tapped
        // the start position for this player
        pawnPosition = Board.startPosition(pawn.player);
      } else {
        pawnPosition =
            BoardPath.getPositionAtStep(pawn.player, pawn.stepsCompleted);
      }

      if (pawnPosition != null &&
          pawnPosition.row == cell.row &&
          pawnPosition.col == cell.col) {
        provider.selectPawn(pawn.pawnIndex);
        return;
      }
    }
  }

  Widget _buildWinBanner(GameProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AshtaChammaTheme.gold.withAlpha(200),
      child: Text(
        'Player ${provider.winnerId} wins!',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AshtaChammaTheme.deepRed,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Game'),
        content: const Text('Start a new game? Current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }
}
