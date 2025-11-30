import 'package:flutter/material.dart';
import '../models/game_config.dart';
import '../game/core/maze_game.dart';

// === CONTROLADOR (C) ===
// Maneja la lógica de interacción entre la Vista y el Modelo/Juego.
class GameUIController {
  final GameConfig config;
  final MazeGame game;

  GameUIController({required this.config, required this.game});

  // Acción: Alternar Pausa
  void togglePause() {
    if (game.paused) {
      game.resumeEngine();
      config.setPaused(false);
    } else {
      game.pauseEngine();
      config.setPaused(true);
    }
  }

  // Acción: Cambiar Volumen
  void updateVolume(double value) {
    config.setVolume(value);
  }

  // Acción: Cambiar Notificaciones
  void toggleNotifications(bool value) {
    config.setNotifications(value);
  }

  // Acción: Cambiar Vibración
  void toggleVibration(bool value) {
    config.setVibration(value);
  }

  // Acción: Cambiar Control (Touch/Acelerómetro)
  void setControlMode(bool useTouch) {
    config.setActiveControl(
      useTouch ? ControlType.touchButtons : ControlType.accelerometer
    );
  }

  // Acción: Salir con Confirmación (Usado desde el menú de pausa)
  Future<void> exitToMenuWithConfirmation(BuildContext context) async {
    // Pausar el juego si no está pausado
    if (!game.paused) {
      togglePause();
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            '¿Salir al Menú?', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          content: const Text(
            'Perderás el progreso del nivel actual.',
            style: TextStyle(color: Colors.white70)
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _performExit(context);
    }
  }

  // Acción: Salir Directo (Usado al completar nivel)
  void exitToMenuDirect(BuildContext context) {
    _performExit(context);
  }

  // Lógica interna de salida
  void _performExit(BuildContext context) {
    // Limpiar recursos si es necesario
    game.pauseEngine(); // Asegurar que el motor esté detenido
    
    // Navegar de vuelta al Selector de Niveles (que ahora es la pantalla principal/home)
    // Usamos popUntil para regresar a la primera ruta (que es LevelSelectorScreen)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
