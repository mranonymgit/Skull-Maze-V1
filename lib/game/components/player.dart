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
    
    add(CircleHitbox(
      radius: size.x / 2 * 0.9, 
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

  // OPTIMIZACIÓN O(1): Solo verificamos paredes vecinas
  void _moveWithCollisions(Vector2 delta) {
    Vector2 newPosition = position + delta;
    bool collided = false;

    // Calculamos en qué celda está el jugador
    int gridCol = (position.x / MazeGame.wallSize).floor();
    int gridRow = (position.y / MazeGame.wallSize).floor();

    // Revisamos solo el área 3x3 alrededor del jugador
    // Esto reduce las comprobaciones de 2000+ a solo 9 por frame.
    for (int r = gridRow - 1; r <= gridRow + 1; r++) {
      for (int c = gridCol - 1; c <= gridCol + 1; c++) {
        
        // Consulta ultra-rápida al mapa booleano
        if (game.isWallAt(r, c)) {
          // Construimos la geometría de la pared al vuelo
          double wx = c * MazeGame.wallSize;
          double wy = r * MazeGame.wallSize;
          double wSize = MazeGame.wallSize;
          
          // Usamos una versión simplificada de _willCollide que acepta coordenadas
          if (_willCollideWithRect(newPosition, wx, wy, wSize, wSize)) {
            collided = true;
            Vector2 correction = _resolveCollisionWithRect(newPosition, wx, wy, wSize, wSize);
            position = correction;
            // Si corregimos una colisión, salimos del bucle interno para evitar conflictos
            // o podríamos intentar resolver múltiples, pero break es seguro.
            gotoEnd: break; 
          }
        }
      }
      if (collided) break;
    }

    if (!collided) {
      position = newPosition;
    }
    
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
  
  // Versión optimizada que no requiere objeto WallComponent
  Vector2 _resolveCollisionWithRect(Vector2 newPosition, double wx, double wy, double wWidth, double wHeight) {
    double wallLeft = wx;
    double wallRight = wx + wWidth;
    double wallTop = wy;
    double wallBottom = wy + wHeight;
    double playerRadius = size.x / 2;

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
    double playerRadius = size.x / 2;

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
