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
import '../components/wall.dart'; // Ya no se instancia masivamente, pero se deja por si acaso
import '../components/maze_render_component.dart'; // Nuevo renderer
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
  
  // Mapa para consulta rápida de colisiones
  List<List<bool>>? _collisionMap;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  // === COLORES DINÁMICOS POR NIVEL ===
  Color get wallColor => switch (config.currentLevel) {
    1 => const Color(0xFF00FFFF),    // Cian neon
    2 => const Color(0xFFFF00FF),    // Magenta
    3 => const Color(0xFFFFFF00),    // Amarillo
    4 => const Color(0xFFFF6600),    // Naranja fuego
    _ => const Color(0xFF7CFC00),    // Verde ácido
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateCameraZoom(size);
  }

  void loadMaze(int level, int subMazeIndex) {
    // Limpieza eficiente
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

    // OPTIMIZACIÓN DE RENDERIZADO:
    // En lugar de 2000 componentes, usamos uno solo que dibuja todo el mapa cacheado.
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

    camera.setBounds(Rectangle.fromRect(
      Rect.fromLTWH(0, 0, _mazeCols * wallSize, _mazeRows * wallSize)
    ));
    // IMPORTANTE: Ya no detenemos la cámara aquí siempre. Se ajusta dinámicamente.
    _updateCameraZoom(canvasSize);

    _updateControls();
    
    overlays.remove('LevelCompleteMenu');
    paused = false;
  }
  
  // Método público para consulta rápida de colisiones (Usado por el Player)
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

  // === CÁMARA HÍBRIDA ADAPTATIVA ===
  // - Si el laberinto cabe en pantalla con un zoom decente: CENTRAR.
  // - Si el laberinto es gigante y requiere zoom microscópico: ZOOM MINIMO + SEGUIR JUGADOR.
  void _updateCameraZoom(Vector2 screenSize) {
    if (_mazeCols == 0 || _mazeRows == 0) return;
    
    final double mapWidth = _mazeCols * wallSize;
    final double mapHeight = _mazeRows * wallSize;
    
    // Zoom necesario para ver TODO el mapa (Fit)
    final double scaleX = screenSize.x / mapWidth;
    final double scaleY = screenSize.y / mapHeight;
    
    // Márgenes (Móvil vs Web)
    bool isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    double marginFactor = isMobile ? 0.75 : 0.85;
    double zoomFit = min(scaleX, scaleY) * marginFactor; 

    // DEFINIMOS EL ZOOM MÍNIMO ACEPTABLE
    // Si zoomFit es menor que esto, las paredes se ven demasiado pequeñas.
    // Valor sugerido: 0.6 (ajustar a gusto).
    double minAcceptableZoom = 0.6;

    if (zoomFit >= minAcceptableZoom) {
      // A) El laberinto cabe bien -> Modo Estático Centrado
      camera.viewfinder.zoom = zoomFit;
      camera.viewfinder.anchor = Anchor.center;
      
      // Centramos la cámara en el centro del mapa
      final centerX = mapWidth / 2;
      final centerY = mapHeight / 2;
      camera.viewfinder.position = Vector2(centerX, centerY);
      
      camera.stop(); // Dejamos de seguir al jugador
    } else {
      // B) El laberinto es demasiado grande -> Modo Scroll (Seguir Jugador)
      // Fijamos el zoom al mínimo aceptable para que se vea bien
      camera.viewfinder.zoom = minAcceptableZoom;
      camera.viewfinder.anchor = Anchor.center;
      
      // Activamos seguimiento suave
      camera.follow(player, maxSpeed: 1000, snap: false);
      
      // Opcional: Ajustar los bounds para que la cámara no muestre mucho negro
      // camera.setBounds está configurado en loadMaze, así que restringirá el movimiento.
    }
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
