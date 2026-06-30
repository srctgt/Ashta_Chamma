import 'package:flutter/material.dart';

import '../../logic/game_controller.dart';
import '../../logic/game_state.dart';
import '../../models/player.dart';
import '../theme.dart';
import 'pawn_widget.dart';

/// Displays game information: current player, pawn counts, and status messages.
class GameInfoPanel extends StatelessWidget {
  /// Player 1 data.
  final Player player1;

  /// Player 2 data.
  final Player player2;

  /// The current player's ID.
  final int currentPlayerId;

  /// Status message to display.
  final String statusMessage;

  /// The game phase.
  final GamePhase phase;

  /// The game mode.
  final GameMode gameMode;

  /// Whether there is a bonus turn.
  final bool hasBonusTurn;

  const GameInfoPanel({
    super.key,
    required this.player1,
    required this.player2,
    required this.currentPlayerId,
    required this.statusMessage,
    required this.phase,
    required this.gameMode,
    this.hasBonusTurn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AshtaChammaTheme.cream,
        border: Border(
          bottom: BorderSide(
            color: AshtaChammaTheme.boardLines,
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player indicators row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerInfo(1, player1),
              _buildTurnIndicator(),
              _buildPlayerInfo(2, player2),
            ],
          ),
          const SizedBox(height: 8),
          // Status message
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: phase == GamePhase.won
                  ? AshtaChammaTheme.deepRed
                  : AshtaChammaTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          // Pass-and-play indicator
          if (gameMode == GameMode.humanVsHuman && phase != GamePhase.won)
            const Padding(
              padding: EdgeInsets.only(top: 4),
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

  Widget _buildPlayerInfo(int playerId, Player player) {
    final isCurrentPlayer = playerId == currentPlayerId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? PawnHelper.getPlayerColor(playerId).withAlpha(30)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentPlayer
            ? Border.all(
                color: PawnHelper.getPlayerColor(playerId),
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PawnIndicator(
                playerId: playerId,
                size: 16,
                highlighted: isCurrentPlayer,
              ),
              const SizedBox(width: 6),
              Text(
                'P$playerId',
                style: TextStyle(
                  fontWeight:
                      isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: PawnHelper.getPlayerColor(playerId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Home: ${player.pawnsAtHome}/4',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    final color = PawnHelper.getPlayerColor(currentPlayerId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.arrow_downward,
          color: color,
          size: 20,
        ),
        if (hasBonusTurn)
          const Text(
            'Bonus!',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AshtaChammaTheme.gold,
            ),
          ),
      ],
    );
  }
}
