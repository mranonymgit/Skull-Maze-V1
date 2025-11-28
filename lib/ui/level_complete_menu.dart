import 'package:flutter/material.dart';
import '../game/core/maze_game.dart';

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
    // Animación fluida de "Pop" (Escala)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Usamos ElasticOut para un efecto de rebote sutil y profesional
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
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            border: Border.all(color: const Color(0xFF00FFFF), width: 3), // Borde Neon Cyan
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withValues(alpha: 0.3),
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
                    // Animación de salida inversa antes de ejecutar la acción (opcional, pero inmediato es más fluido)
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
              
              // Botón Volver
              TextButton(
                onPressed: () => widget.game.goToMainMenu(),
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
