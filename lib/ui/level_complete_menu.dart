import 'package:flutter/material.dart';
import '../game/core/maze_game.dart';
import '../controllers/game_ui_controller.dart';
import 'package:provider/provider.dart';
import '../models/game_config.dart';

class LevelCompleteMenu extends StatefulWidget {
  final MazeGame game;

  const LevelCompleteMenu({super.key, required this.game});

  @override
  State<LevelCompleteMenu> createState() => _LevelCompleteMenuState();
}

class _LevelCompleteMenuState extends State<LevelCompleteMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<GameConfig>();
    
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9), // Corrección para compatibilidad
            border: Border.all(color: const Color(0xFF00FFFF), width: 3), 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withOpacity(0.3), // Corrección para compatibilidad
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF00FFFF), size: 60),
              const SizedBox(height: 15),
              const Text(
                'NIVEL COMPLETADO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              
              // Botón Siguiente Nivel
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.game.nextLevel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFFF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('SIGUIENTE NIVEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 15),
              
              // Botón Volver al Menú
              TextButton(
                onPressed: () {
                  // En móviles, a veces el Navigator.pop no funciona si el contexto no es el correcto
                  // o si Flame maneja los overlays de forma especial.
                  // Intentamos cerrar el overlay primero, y si no, salir de la pantalla.
                  
                  try {
                    // 1. Intentar salir de la pantalla (cerrar MainGameScreen)
                    Navigator.of(context, rootNavigator: true).pop(); 
                  } catch (e) {
                    // Fallback si falla el pop
                    debugPrint("Error al salir al menú: $e");
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text('Volver al Menú'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
