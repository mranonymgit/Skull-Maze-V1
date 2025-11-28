import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/game_config.dart';
import 'ui/main_game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameConfig(),
      child: const MazeApp(),
    ),
  );
}

class MazeApp extends StatelessWidget {
  const MazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skull Maze',
      debugShowCheckedModeBanner: false, // Quitar etiqueta DEBUG
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainGameScreen(),
    );
  }
}
