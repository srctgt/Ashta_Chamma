import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/board_path.dart';
import '../../logic/game_controller.dart';
import '../../models/board.dart';
import '../game_provider.dart';
import '../theme.dart';
import '../widgets/board_painter.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_info_panel.dart';
import '../widgets/pawn_widget.dart';

/// Main game screen combining the board, dice, and info panel.
///
/// Layout adapts based on screen width:
/// - Wide screens (>=700px): Board on the left, dice/info side panel on right.
/// - Narrow screens (<700px): Info panel (top), board (center), dice (bottom).
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  /// Breakpoint for switching to wide (side panel) layout.
  static const double _wideBreakpoint = 700;

  /// Maximum width for the game content on narrow screens.
  static const double _maxNarrowContentWidth = 600;

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
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _wideBreakpoint) {
                return _buildWideLayout(context, provider, constraints);
              } else {
                return _buildNarrowLayout(context, provider);
              }
            },
          );
        },
      ),
    );
  }

  /// Wide layout: board on left, side panel on right.
  Widget _buildWideLayout(
    BuildContext context,
    GameProvider provider,
    BoxConstraints constraints,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Board area (left side)
        Expanded(
          flex: 3,
          child: _buildBoardArea(context, provider),
        ),
        // Side panel (right side)
        SizedBox(
          width: 280,
          child: _buildSidePanel(context, provider),
        ),
      ],
    );
  }

  /// Narrow layout: vertical column (info top, board center, dice bottom).
  Widget _buildNarrowLayout(BuildContext context, GameProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxNarrowContentWidth),
        child: Column(
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
              child: _buildBoardArea(context, provider),
            ),
            // Dice widget
            DiceWidget(
              diceResult: provider.diceResult,
              diceMode: provider.diceMode,
              canRoll: provider.isRolling && !provider.isAiTurn,
              phase: provider.gameState.phase,
              isAnimating: provider.isAnimating,
              onRoll: () => provider.rollDice(),
              onAnimationStart: () {
                provider.isAnimating = true;
              },
              onAnimationEnd: () {
                provider.isAnimating = false;
              },
            ),
            // Win overlay
            if (provider.isGameOver) _buildWinBanner(provider),
          ],
        ),
      ),
    );
  }

  /// Board area with tap handling (shared between layouts).
  Widget _buildBoardArea(BuildContext context, GameProvider provider) {
    return Padding(
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
    );
  }

  /// Side panel for wide layout: player info, dice, status.
  Widget _buildSidePanel(BuildContext context, GameProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AshtaChammaTheme.cream,
        border: const Border(
          left: BorderSide(
            color: AshtaChammaTheme.boardLines,
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AshtaChammaTheme.boardLines.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Decorative top border
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AshtaChammaTheme.deepRed,
                  AshtaChammaTheme.terracotta,
                  AshtaChammaTheme.ochre,
                  AshtaChammaTheme.gold,
                ],
              ),
            ),
          ),
          // Player turn info section
          _buildSidePanelPlayerInfo(provider),
          const Divider(
            color: AshtaChammaTheme.boardLines,
            thickness: 1,
            height: 1,
          ),
          // Dice/Shell animation area (expanded to fill available space)
          Expanded(
            child: _buildSidePanelDiceArea(provider),
          ),
          // Status message section
          _buildSidePanelStatus(provider),
          // Win overlay (in side panel)
          if (provider.isGameOver) _buildSidePanelWinBanner(provider),
        ],
      ),
    );
  }

  /// Player info section for the side panel.
  Widget _buildSidePanelPlayerInfo(GameProvider provider) {
    final currentPlayerId = provider.gameState.currentPlayerId;
    final player1 = provider.gameState.player1;
    final player2 = provider.gameState.player2;
    final color = PawnHelper.getPlayerColor(currentPlayerId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // Current turn indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              PawnIndicator(
                playerId: currentPlayerId,
                size: 18,
                highlighted: true,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Player $currentPlayerId\'s Turn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (provider.gameState.hasBonusTurn)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AshtaChammaTheme.gold.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AshtaChammaTheme.gold,
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Bonus Turn!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AshtaChammaTheme.gold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Player scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: _buildMiniPlayerInfo(1, player1, currentPlayerId),
              ),
              Flexible(
                child: _buildMiniPlayerInfo(2, player2, currentPlayerId),
              ),
            ],
          ),
          // Game mode indicator
          if (provider.gameMode == GameMode.humanVsHuman)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Pass-and-play',
                style: TextStyle(
                  fontSize: 11,
                  color: AshtaChammaTheme.subtitleColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Compact player info for side panel.
  Widget _buildMiniPlayerInfo(
      int playerId, dynamic player, int currentPlayerId) {
    final isActive = playerId == currentPlayerId;
    final color = PawnHelper.getPlayerColor(playerId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: color, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'P$playerId',
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Home: ${player.pawnsAtHome}/4',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Dice area for side panel - larger and more prominent.
  Widget _buildSidePanelDiceArea(GameProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: DiceWidget(
          diceResult: provider.diceResult,
          diceMode: provider.diceMode,
          canRoll: provider.isRolling && !provider.isAiTurn,
          phase: provider.gameState.phase,
          isAnimating: provider.isAnimating,
          onRoll: () => provider.rollDice(),
          onAnimationStart: () {
            provider.isAnimating = true;
          },
          onAnimationEnd: () {
            provider.isAnimating = false;
          },
          expanded: true,
        ),
      ),
    );
  }

  /// Status message section for side panel.
  Widget _buildSidePanelStatus(GameProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AshtaChammaTheme.boardLines,
            width: 1,
          ),
        ),
      ),
      child: Text(
        provider.statusMessage,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AshtaChammaTheme.textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Win banner for side panel.
  Widget _buildSidePanelWinBanner(GameProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AshtaChammaTheme.gold.withAlpha(200),
      child: Text(
        'Player ${provider.winnerId} wins!',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AshtaChammaTheme.deepRed,
        ),
        textAlign: TextAlign.center,
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
