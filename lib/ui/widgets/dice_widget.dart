import 'package:flutter/material.dart';

import '../../logic/dice.dart';
import '../../logic/game_state.dart';
import '../theme.dart';

/// Widget that displays the dice/cowrie shell area.
///
/// Shows the current roll result and provides a roll button.
/// For cowrie mode, displays 4 shell icons (filled = mouth up).
/// For regular dice mode, shows the dice value with dots pattern.
class DiceWidget extends StatelessWidget {
  /// The current dice result (null if not rolled yet).
  final DiceResult? diceResult;

  /// The dice mode.
  final DiceMode diceMode;

  /// Whether the roll button is enabled.
  final bool canRoll;

  /// Callback when the roll button is pressed.
  final VoidCallback? onRoll;

  /// Current game phase.
  final GamePhase phase;

  const DiceWidget({
    super.key,
    required this.diceResult,
    required this.diceMode,
    required this.canRoll,
    required this.phase,
    this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AshtaChammaTheme.cream,
        border: Border(
          top: BorderSide(
            color: AshtaChammaTheme.boardLines,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dice display area
          Expanded(
            child: _buildDiceDisplay(),
          ),
          // Roll button
          _buildRollButton(),
        ],
      ),
    );
  }

  Widget _buildDiceDisplay() {
    if (diceResult == null) {
      return const Center(
        child: Text(
          'Tap Roll to start',
          style: TextStyle(
            color: AshtaChammaTheme.subtitleColor,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Roll value display
        Text(
          '${diceResult!.value}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AshtaChammaTheme.deepRed,
          ),
        ),
        const SizedBox(height: 4),
        // Shell or dice icons
        if (diceMode == DiceMode.cowrieShells)
          _buildShellDisplay()
        else
          _buildDiceDots(),
        // Bonus turn indicator
        if (diceResult!.grantsBonusTurn)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Bonus turn!',
              style: TextStyle(
                color: AshtaChammaTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShellDisplay() {
    final shells = diceResult?.shellResults ?? [false, false, false, false];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: shells.map((mouthUp) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mouthUp ? AshtaChammaTheme.ochre : Colors.transparent,
              border: Border.all(
                color: AshtaChammaTheme.boardLines,
                width: 1.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiceDots() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AshtaChammaTheme.boardLines, width: 1.5),
      ),
      child: Center(
        child: _buildDotsPattern(diceResult!.value),
      ),
    );
  }

  Widget _buildDotsPattern(int value) {
    // Simple dot representation
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      runSpacing: 3,
      children: List.generate(
        value,
        (_) => Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AshtaChammaTheme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRollButton() {
    return ElevatedButton(
      onPressed: canRoll ? onRoll : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canRoll
            ? AshtaChammaTheme.terracotta
            : AshtaChammaTheme.terracotta.withAlpha(100),
        foregroundColor: AshtaChammaTheme.cream,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Roll',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
