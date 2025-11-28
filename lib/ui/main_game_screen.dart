import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/core/maze_game.dart';
import '../models/game_config.dart';
import 'level_complete_menu.dart'; // Importamos el nuevo menú animado

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  late MazeGame _game;

  @override
  void initState() {
    super.initState();
    _game = MazeGame();
    _game.config = Provider.of<GameConfig>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.loadMaze(_game.config.currentLevel, _game.config.currentSubMaze);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // --- HUD Lateral Izquierdo (Responsivo) ---
          if (MediaQuery.of(context).size.width > 800)
            Container(
              width: 250,
              color: Colors.grey[900],
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SKULL MAZE', style: TextStyle(color: Colors.cyan, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Consumer<GameConfig>(
                    builder: (context, config, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nivel: ${config.currentLevel}', style: const TextStyle(color: Colors.white)),
                        Text('Sub-Nivel: ${config.currentSubMaze} / ${config.maxSubMazes}', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 20),
                        Text('Tiempo: ${config.timeRemaining.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 20)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text('Controles:', style: TextStyle(color: Colors.white54)),
                  const Text('WASD / Flechas', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // --- Área de Juego Central ---
          Expanded(
            child: ClipRect( 
              child: GameWidget(
                game: _game,
                // Map de overlays actualizado
                overlayBuilderMap: {
                  'LevelCompleteMenu': (context, MazeGame game) {
                    // Usamos el nuevo widget con animación
                    return LevelCompleteMenu(game: game);
                  },
                },
                initialActiveOverlays: const [],
              ),
            ),
          ),

          // --- HUD Lateral Derecho (Simetría) ---
          if (MediaQuery.of(context).size.width > 1200)
             Container(width: 250, color: Colors.grey[900]),
        ],
      ),
    );
  }
}
