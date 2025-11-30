import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/experimental.dart';
import 'package:flame_audio/flame_audio.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart'; 
import 'dart:async' as async; // Aliased to avoid conflict with Flame's Timer

import '../../models/game_config.dart';
import '../../controllers/game_ui_controller.dart';
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
  
  async.StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Vector2 _tiltDirection = Vector2.zero();

  // Variable para controlar si la música ya se inició
  bool _musicStarted = false;
  // BGM filename
  static const String bgmFile = 'fondo.mp3';

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
    
    // Inicializar audio
    FlameAudio.bgm.initialize();

    if (config.isAccelerometerAvailable) {
      _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        final double sensitivity = 2.0;
        double x = -event.x / sensitivity; 
        double y = event.y / sensitivity; 
        _tiltDirection = Vector2(x, y);
      });
    }
  }
  
  @override
  void onRemove() {
    _accelSubscription?.cancel();
    _stopBackgroundMusic(); // Detener música al salir
    super.onRemove();
  }

  // Método para iniciar música con fade in
  void _startBackgroundMusic() {
    if (!_musicStarted) {
      _musicStarted = true;
      // Reproducir en loop
      FlameAudio.bgm.play(bgmFile, volume: 0); 
      
      // Fade in manual
      double targetVolume = config.volume;
      double currentVol = 0;
      const fadeDuration = Duration(seconds: 2);
      const steps = 20;
      final stepTime = Duration(milliseconds: fadeDuration.inMilliseconds ~/ steps);
      final volStep = targetVolume / steps;

      async.Timer.periodic(stepTime, (timer) {
        currentVol += volStep;
        if (currentVol >= targetVolume) {
          currentVol = targetVolume;
          timer.cancel();
        }
        // Solo ajustar si la música sigue sonando
        if (_musicStarted) {
          FlameAudio.bgm.audioPlayer.setVolume(currentVol);
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _stopBackgroundMusic() async {
    if (_musicStarted) {
      _musicStarted = false;
      
      // Fade out
      double currentVol = config.volume; 
      
      const fadeDuration = Duration(seconds: 2);
      const steps = 20;
      final stepTime = Duration(milliseconds: fadeDuration.inMilliseconds ~/ steps);
      final volStep = currentVol / steps;

      async.Timer.periodic(stepTime, (timer) async {
        currentVol -= volStep;
        if (currentVol <= 0) {
          currentVol = 0;
          timer.cancel();
          await FlameAudio.bgm.stop();
        } else {
           FlameAudio.bgm.audioPlayer.setVolume(currentVol);
        }
      });
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateCameraZoom(size);
  }

  void loadMaze(int level, int subMazeIndex) {
    // Iniciar música si es la primera vez que cargamos un nivel
    if (!_musicStarted) {
      _startBackgroundMusic();
    }

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

    // USAR POSICIONES DEL GENERADOR
    add(GoalComponent(
      position: Vector2(maze.goalCol * wallSize + wallSize / 2, maze.goalRow * wallSize + wallSize / 2),
      size: Vector2.all(wallSize * 0.7), 
    ));

    // USAR POSICIONES DEL GENERADOR
    player = Player(
      position: Vector2(maze.startCol * wallSize + wallSize / 2, maze.startRow * wallSize + wallSize / 2), 
      size: Vector2.all(wallSize * 0.5)
    );
    add(player);

    camera.setBounds(Rectangle.fromRect(
      Rect.fromLTWH(0, 0, _mazeCols * wallSize, _mazeRows * wallSize)
    ));
    
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

  void _updateCameraZoom(Vector2 screenSize) {
    if (_mazeCols == 0 || _mazeRows == 0) return;
    
    final double mapWidth = _mazeCols * wallSize;
    final double mapHeight = _mazeRows * wallSize;
    final double scaleX = screenSize.x / mapWidth;
    final double scaleY = screenSize.y / mapHeight;
    
    bool isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    double marginFactor = isMobile ? 0.90 : 0.95;

    double zoomFit = min(scaleX, scaleY) * marginFactor; 

    camera.viewfinder.zoom = zoomFit;
    camera.viewfinder.anchor = Anchor.center;
    
    final centerX = mapWidth / 2;
    final centerY = mapHeight / 2;
    camera.viewfinder.position = Vector2(centerX, centerY);
    
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
    
    // Actualizar volumen en tiempo real
    if (_musicStarted) {
       FlameAudio.bgm.audioPlayer.setVolume(config.volume);
    }

    if (config.activeControl == ControlType.accelerometer) {
      if (_tiltDirection.length > 0.2) {
        player.move(_tiltDirection);
      } else {
        player.move(Vector2.zero());
      }
    }
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
