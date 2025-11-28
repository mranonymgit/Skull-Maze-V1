import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/maze_game.dart';
import 'wall.dart';
import 'goal.dart';

class Player extends CircleComponent
    with HasGameReference<MazeGame>, CollisionCallbacks {
  
  // === VELOCIDAD ADAPTATIVA ===
  static double get baseSpeed => kIsWeb ? 170.0 : 220.0;
  
  Vector2 direction = Vector2.zero(); 
  bool goalReached = false;
  Vector2 _previousPosition = Vector2.zero();

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
    paint = Paint()..color = const Color(0xFF18FFFF); 
    
    // MEJORA: Hitbox un poco más grande (95%) para evitar que el sprite visual corte esquinas
    add(CircleHitbox(
      radius: size.x / 2 * 0.95, 
      anchor: Anchor.center,
      position: size / 2,
      collisionType: CollisionType.active,
    ));
    
    _previousPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (goalReached || direction == Vector2.zero()) return;

    final velocity = direction.normalized() * baseSpeed * dt;
    
    _moveWithCollisions(velocity);
  }
  
  void setDirection(Vector2 dir) {
    direction = dir;
  }

  // OPTIMIZACIÓN O(1) + RESOLUCIÓN MULTI-PASADA (Anti-Tunneling)
  void _moveWithCollisions(Vector2 delta) {
    // Posición propuesta inicial
    Vector2 currentPos = position + delta;
    
    // BUCLE DE RESOLUCIÓN ITERATIVA
    // Realizamos varias pasadas (3) para resolver conflictos complejos (ej. esquinas internas)
    // Si resolvemos pared A y nos empuja contra pared B, la siguiente pasada resolverá pared B.
    for (int i = 0; i < 3; i++) {
      bool collisionFound = false;

      // Calculamos celda actual basada en la posición corregida de esta iteración
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
              // Resolvemos y actualizamos currentPos inmediatamente para la siguiente verificación
              currentPos = _resolveCollisionWithRect(currentPos, wx, wy, wSize, wSize);
              collisionFound = true;
            }
          }
        }
      }
      
      // Si en una pasada no hubo colisiones, terminamos antes (optimización)
      if (!collisionFound) break;
    }

    // Aplicamos la posición final libre de colisiones
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
    double playerRadius = size.x / 2 * 0.95; // Usar el mismo radio ajustado

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
    double playerRadius = size.x / 2 * 0.95; // Radio consistente

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
     canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paint);
  }
}
