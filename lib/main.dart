import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/game_config.dart';
import 'ui/login_screen.dart'; 
import 'firebase_options.dart';
import 'services/notification_service.dart'; // Importar el servicio

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Inicializar servicio de notificaciones
    await NotificationService().init();

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
      home: const LoginScreen(),
    );
  }
}
