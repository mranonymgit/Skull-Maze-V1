import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/maze_game.dart';
import 'wall.dart';
import 'goal.dart';

class Player extends PositionComponent
    with HasGameReference<MazeGame>, CollisionCallbacks {
  
  // === VELOCIDAD ADAPTATIVA ===
  // Se incrementa la velocidad base para mayor fluidez
  static double get baseSpeed => kIsWeb ? 240.0 : 300.0; 
  
  Vector2 direction = Vector2.zero(); 
  bool goalReached = false;
  Vector2 _previousPosition = Vector2.zero();
  
  final Paint _paint = Paint()..color = const Color(0xFF18FFFF);
  SpriteComponent? _spriteComponent;

  Player({
    required super.position,
    required Vector2 size,
    super.anchor = Anchor.center,
  }) {
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Cargar sprite del personaje seleccionado
    final charName = game.config.selectedCharacter;
    // Asumimos que el nombre en config (ej: "Catty") coincide con el archivo (ej: "Catty.png")
    
    try {
      final spritePath = 'Personajes/$charName.png';
      Sprite? sprite;
      String fullPath = spritePath;
      if (charName == 'Sora' || charName == 'Ury') {
         fullPath = 'Personajes/$charName.jpeg';
      }
      
      sprite = await game.loadSprite(fullPath);
      
      _spriteComponent = SpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.center,
        position: size / 2, 
      );
      add(_spriteComponent!);
      
    } catch (e) {
      debugPrint("Error cargando sprite del personaje: $e");
    }
    
    add(CircleHitbox(
      radius: size.x / 2 * 0.9, // Reducido ligeramente hitbox para evitar atascos en esquinas
      anchor: Anchor.center,
      position: size / 2,
      collisionType: CollisionType.active,
    ));
    
    _previousPosition = position.clone();
  }

  @override
  void update(double dt) {
    // --- SUAVIZADO DE MOVIMIENTO (INTERPOLACIÓN) ---
    // Si el dt es muy alto (lag spike), lo limitamos para no "teletransportar" al jugador
    // a través de paredes. Si dt es muy bajo (altos Hz), el movimiento es suave.
    double safeDt = dt.clamp(0.0, 0.05); 
    
    super.update(safeDt);

    if (goalReached || direction == Vector2.zero()) return;

    // Calculamos velocidad
    final velocity = direction.normalized() * baseSpeed * safeDt;
    
    _moveWithCollisions(velocity);
  }
  
  void setDirection(Vector2 dir) {
    direction = dir;
  }

  // OPTIMIZACIÓN O(1) + RESOLUCIÓN MULTI-PASADA (Anti-Tunneling)
  void _moveWithCollisions(Vector2 delta) {
    Vector2 currentPos = position + delta;
    
    // Aumentamos pasadas para mayor precisión a alta velocidad
    for (int i = 0; i < 4; i++) { 
      bool collisionFound = false;

      int gridCol = (currentPos.x / MazeGame.wallSize).floor();
      int gridRow = (currentPos.y / MazeGame.wallSize).floor();

      // Revisamos vecinos 3x3
      for (int r = gridRow - 1; r <= gridRow + 1; r++) {
        for (int c = gridCol - 1; c <= gridCol + 1; c++) {
          
          if (game.isWallAt(r, c)) {
            double wx = c * MazeGame.wallSize;
            double wy = r * MazeGame.wallSize;
            double wSize = MazeGame.wallSize;
            
            if (_willCollideWithRect(currentPos, wx, wy, wSize, wSize)) {
              currentPos = _resolveCollisionWithRect(currentPos, wx, wy, wSize, wSize);
              collisionFound = true;
            }
          }
        }
      }
      
      if (!collisionFound) break;
    }

    position = currentPos;
    _previousPosition = position.clone();
  }

  void handleKeyboardInput(Set<LogicalKeyboardKey> keysPressed) {
    Vector2 input = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || keysPressed.contains(LogicalKeyboardKey.keyW)) {
      input.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || keysPressed.contains(LogicalKeyboardKey.keyS)) {
      input.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA)) {
      input.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD)) {
      input.x += 1;
    }

    setDirection(input);
  }
  
  void move(Vector2 newDirection) {
    setDirection(newDirection);
  }
  
  Vector2 _resolveCollisionWithRect(Vector2 newPosition, double wx, double wy, double wWidth, double wHeight) {
    double wallLeft = wx;
    double wallRight = wx + wWidth;
    double wallTop = wy;
    double wallBottom = wy + wHeight;
    double playerRadius = size.x / 2 * 0.9; 

    double closestX = newPosition.x.clamp(wallLeft, wallRight);
    double closestY = newPosition.y.clamp(wallTop, wallBottom);

    double dx = newPosition.x - closestX;
    double dy = newPosition.y - closestY;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance < playerRadius) {
      double overlap = playerRadius - distance;
      if (distance > 0) {
        double normalX = dx / distance;
        double normalY = dy / distance;
        return Vector2(
          newPosition.x + normalX * overlap,
          newPosition.y + normalY * overlap,
        );
      } else {
        return _previousPosition;
      }
    }
    return newPosition;
  }

  bool _willCollideWithRect(Vector2 newPosition, double wx, double wy, double wWidth, double wHeight) {
    double wallLeft = wx;
    double wallRight = wx + wWidth;
    double wallTop = wy;
    double wallBottom = wy + wHeight;
    double playerRadius = size.x / 2 * 0.9; 

    double closestX = newPosition.x.clamp(wallLeft, wallRight);
    double closestY = newPosition.y.clamp(wallTop, wallBottom);

    double dx = newPosition.x - closestX;
    double dy = newPosition.y - closestY;
    double distanceSquared = dx * dx + dy * dy;

    return distanceSquared < (playerRadius * playerRadius);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is GoalComponent && !goalReached) {
      goalReached = true;
      game.onPlayerReachedExit();
    }
  }
  
  @override
  void render(Canvas canvas) {
     if (_spriteComponent == null) {
       canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, _paint);
     }
  }
}
