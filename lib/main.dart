import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/game_config.dart';
import 'ui/level_selector_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Intentar inicializar Firebase si está disponible, sino continuar (para evitar crashes si no está configurado aún)
  try {
     // Si firebase_options.dart existiera, usaríamos: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
     // Por ahora, usamos la inicialización automática para Android (si google-services.json está bien)
     await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase no inicializado o error: $e");
  }

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      // La pantalla inicial ahora es el Selector de Niveles
      home: const LevelSelectorScreen(),
    );
  }
}
