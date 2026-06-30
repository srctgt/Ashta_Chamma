import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/dice.dart';
import '../../logic/game_controller.dart';
import '../game_provider.dart';
import '../theme.dart';
import 'game_screen.dart';

/// Home screen with game mode selection and dice mode toggle.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DiceMode _selectedDiceMode = DiceMode.cowrieShells;

  void _startGame(GameMode gameMode) {
    final provider = context.read<GameProvider>();
    provider.startGame(gameMode, _selectedDiceMode);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const GameScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Ashta Chamma',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 40,
                          color: AshtaChammaTheme.deepRed,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Chowka Bhara',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AshtaChammaTheme.ochre,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Dice mode toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AshtaChammaTheme.cream,
                      border: Border.all(
                        color: AshtaChammaTheme.ochre,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Dice Mode',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<DiceMode>(
                          segments: const [
                            ButtonSegment(
                              value: DiceMode.cowrieShells,
                              label: Text('Cowrie Shells'),
                            ),
                            ButtonSegment(
                              value: DiceMode.regularDice,
                              label: Text('Regular Dice'),
                            ),
                          ],
                          selected: {_selectedDiceMode},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _selectedDiceMode = selection.first;
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AshtaChammaTheme.terracotta;
                              }
                              return AshtaChammaTheme.cream;
                            }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AshtaChammaTheme.cream;
                              }
                              return AshtaChammaTheme.textColor;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Game mode buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startGame(GameMode.humanVsHuman),
                      child: const Text('Human vs Human'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startGame(GameMode.humanVsAi),
                      child: const Text('Human vs AI'),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pass and play hint
                  Text(
                    'Human vs Human: Pass-and-play on same device',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
