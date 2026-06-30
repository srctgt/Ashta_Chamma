import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/game_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const AshtaChammaApp());
}

class AshtaChammaApp extends StatelessWidget {
  const AshtaChammaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'Ashta Chamma',
        theme: AshtaChammaTheme.themeData,
        home: const HomeScreen(),
      ),
    );
  }
}
