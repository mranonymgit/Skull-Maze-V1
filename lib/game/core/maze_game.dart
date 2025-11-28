import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game_config.dart';
import '../components/player.dart';
import '../components/wall.dart'; 
import '../components/maze_render_component.dart'; 
import '../components/goal.dart';
import '../controls/touch_buttons.dart';
import '../generator/maze_generator.dart';

class MazeGame extends FlameGame
with HasCollisionDetection, KeyboardEvents {

  late GameConfig config;
  late Player player;
  TouchControlButtons? touchControls;
  MazeRenderComponent? mazeRenderer;

  int _mazeCols = 0;
  int _mazeRows = 0;
  static const double wallSize = 24.0; 
  
  List<List<bool>>? _collisionMap;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  Color get wallColor => switch (config.currentLevel) {
    1 => const Color(0xFF00FFFF),    
    2 => const Color(0xFFFF00FF),    
    3 => const Color(0xFFFFFF00),    
    4 => const Color(0xFFFF6600),    
    _ => const Color(0xFF7CFC00),    
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Es vital llamar al ajuste de cámara cada vez que el tamaño del juego cambia
    _updateCameraZoom(size);
  }

  void loadMaze(int level, int subMazeIndex) {
    children.whereType<WallComponent>().toList().forEach(remove);
    children.whereType<MazeRenderComponent>().toList().forEach(remove);
    children.whereType<GoalComponent>().toList().forEach(remove);
    children.whereType<Player>().toList().forEach(remove);
    
    if (touchControls != null) {
      touchControls!.removeFromParent();
      touchControls = null;
    }

    final maze = MazeGenerator.generate(level, subMazeIndex);
    _mazeCols = maze.cols;
    _mazeRows = maze.rows;
    _collisionMap = maze.walls;

    mazeRenderer = MazeRenderComponent(
      walls: maze.walls,
      wallSize: wallSize,
      wallColor: wallColor,
    );
    add(mazeRenderer!);

    final goalR = maze.rows - 2;
    final goalC = maze.cols - 2;
    add(GoalComponent(
      position: Vector2(goalC * wallSize + wallSize / 2, goalR * wallSize + wallSize / 2),
      size: Vector2.all(wallSize * 0.7), 
    ));

    final startX = 1 * wallSize + wallSize / 2;
    final startY = 1 * wallSize + wallSize / 2;
    player = Player(position: Vector2(startX, startY), size: Vector2.all(wallSize * 0.5));
    add(player);

    // Definimos los límites del mundo, aunque con el zoom fit no deberían alcanzarse
    camera.setBounds(Rectangle.fromRect(
      Rect.fromLTWH(0, 0, _mazeCols * wallSize, _mazeRows * wallSize)
    ));
    
    // Ajuste inicial de la cámara
    _updateCameraZoom(canvasSize);

    _updateControls();
    
    overlays.remove('LevelCompleteMenu');
    paused = false;
  }
  
  bool isWallAt(int row, int col) {
    if (_collisionMap == null) return false;
    if (row < 0 || row >= _mazeRows || col < 0 || col >= _mazeCols) return true;
    return _collisionMap![row][col];
  }
  
  void onPlayerReachedExit() {
    paused = true;
    if (config.currentSubMaze < config.maxSubMazes) {
      config.advanceMaze();
      loadMaze(config.currentLevel, config.currentSubMaze);
    } else {
      overlays.add('LevelCompleteMenu');
    }
  }

  void nextLevel() {
    config.advanceMaze(); 
    loadMaze(config.currentLevel, config.currentSubMaze);
    overlays.remove('LevelCompleteMenu');
    paused = false;
  }
  
  void goToMainMenu() {
     overlays.remove('LevelCompleteMenu');
  }

  // === SOLUCIÓN DEFINITIVA DE AJUSTE DE CÁMARA (LETTERBOXING) ===
  void _updateCameraZoom(Vector2 screenSize) {
    if (_mazeCols == 0 || _mazeRows == 0) return;
    
    // Dimensiones reales del laberinto en el mundo
    final double mapWidth = _mazeCols * wallSize;
    final double mapHeight = _mazeRows * wallSize;
    
    // Calculamos el factor de escala para ancho y alto
    final double scaleX = screenSize.x / mapWidth;
    final double scaleY = screenSize.y / mapHeight;
    
    // MARGEN DE SEGURIDAD AGRESIVO
    // Usamos 0.9 (90%) para asegurar que siempre haya un borde negro visible alrededor.
    // Esto garantiza que NUNCA se corte, ni por arriba/abajo ni por los lados.
    const double marginFactor = 0.9;

    // "min" elige la escala más restrictiva. Si es muy ancho, limita por altura. Si es muy alto, limita por ancho.
    double zoomFit = min(scaleX, scaleY) * marginFactor; 

    // Aplicamos el zoom
    camera.viewfinder.zoom = zoomFit;
    
    // ANCLAJE CENTRAL PERFECTO
    camera.viewfinder.anchor = Anchor.center;
    
    // POSICIÓN EXACTA DEL CENTRO DEL LABERINTO
    final centerX = mapWidth / 2;
    final centerY = mapHeight / 2;
    camera.viewfinder.position = Vector2(centerX, centerY);
    
    // Detener cualquier movimiento automático o inercia
    camera.stop();
  }

  void _updateControls() {
    if (config.activeControl == ControlType.touchButtons && touchControls == null) {
      touchControls = TouchControlButtons(player);
      camera.viewport.add(touchControls!);
    } else if (config.activeControl != ControlType.touchButtons && touchControls != null) {
      touchControls!.removeFromParent();
      touchControls = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    config.updateTime(dt);
    _updateControls();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (config.activeControl != ControlType.keyboard) return KeyEventResult.ignored;
    player.handleKeyboardInput(keysPressed);
    return KeyEventResult.handled;
  }

  void onGamepadButton(int button, double value, bool isPressed) {
    if (isPressed && config.activeControl != ControlType.gamepad) {
      config.setActiveControl(ControlType.gamepad);
    }
  }
}
