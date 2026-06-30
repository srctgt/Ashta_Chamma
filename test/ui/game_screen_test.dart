import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ashta_chamma/logic/dice.dart';
import 'package:ashta_chamma/logic/game_controller.dart';
import 'package:ashta_chamma/ui/game_provider.dart';
import 'package:ashta_chamma/ui/screens/game_screen.dart';
import 'package:ashta_chamma/ui/widgets/dice_widget.dart';
import 'package:ashta_chamma/ui/widgets/game_info_panel.dart';

void main() {
  late GameProvider provider;

  setUp(() {
    provider = GameProvider();
    provider.startGame(GameMode.humanVsHuman, DiceMode.cowrieShells);
  });

  Widget buildGameScreen() {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        home: GameScreen(),
      ),
    );
  }

  group('GameScreen - narrow layout', () {
    testWidgets('shows board area, dice button, and player info',
        (tester) async {
      // Use narrow viewport to trigger narrow (vertical) layout
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildGameScreen());

      // Should find a CustomPaint widget (the board)
      expect(find.byType(CustomPaint), findsWidgets);

      // Should find the dice widget
      expect(find.byType(DiceWidget), findsOneWidget);

      // Should find the game info panel
      expect(find.byType(GameInfoPanel), findsOneWidget);

      // Should find the Roll button
      expect(find.text('Roll'), findsOneWidget);

      // Should show player info
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P2'), findsOneWidget);
    });

    testWidgets('roll button works in rolling phase', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildGameScreen());

      // Verify we are in rolling phase
      expect(provider.isRolling, isTrue);

      // Tap the roll button (starts animation)
      await tester.tap(find.text('Roll'));
      await tester.pump(); // trigger first frame
      // Advance past the roll animation (1200ms) + reveal (400ms) + bonus (500ms)
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 200));

      // After rolling animation completes, the actual roll logic fires.
      // Either we are in moving phase (if moves available) or
      // back to rolling for the other player (if no moves)
      expect(
        provider.isMoving || provider.isRolling,
        isTrue,
      );
    });

    testWidgets('shows status message', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildGameScreen());

      // Should show roll message
      expect(find.textContaining('Roll the dice'), findsOneWidget);
    });

    testWidgets('shows pass-and-play indicator in HvH mode', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildGameScreen());

      expect(find.text('Pass-and-play'), findsOneWidget);
    });

    testWidgets('shows home count for players', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildGameScreen());

      // Both players start with 0 pawns home
      expect(find.text('Home: 0/4'), findsNWidgets(2));
    });
  });

  group('GameScreen - wide layout', () {
    testWidgets('shows board, dice, and side panel on wide screens',
        (tester) async {
      // Use wide viewport to trigger wide (side panel) layout
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildGameScreen());

      // Should find a CustomPaint widget (the board)
      expect(find.byType(CustomPaint), findsWidgets);

      // Should find the dice widget (in side panel)
      expect(find.byType(DiceWidget), findsOneWidget);

      // Should find the Roll button
      expect(find.text('Roll'), findsOneWidget);

      // Should show player turn info
      expect(find.textContaining('Player 1'), findsWidgets);

      // Should show pass-and-play indicator
      expect(find.text('Pass-and-play'), findsOneWidget);
    });

    testWidgets('roll button works in wide layout', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildGameScreen());

      expect(provider.isRolling, isTrue);

      // Tap the roll button (starts animation)
      await tester.tap(find.text('Roll'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        provider.isMoving || provider.isRolling,
        isTrue,
      );
    });
  });
}
