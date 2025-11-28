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
    // Aquí podrías llamar a un AudioService para ajustar el volumen real
    // AudioService.setVolume(value);
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

  // Acción: Salir
  void exitToMenu(BuildContext context) {
    // Lógica de limpieza o guardado antes de salir
    // Navigator.of(context).pop(); // O pushReplacement hacia el menú
    print("Saliendo al menú...");
  }
}
