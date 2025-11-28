import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WallComponent extends RectangleComponent with CollisionCallbacks {
  // Permitimos pasar el color en el constructor
  WallComponent({
    required super.position,
    required super.size,
    required Paint paint,
  }) : super(
    paint: paint, // Usamos el paint dinámico
    anchor: Anchor.topLeft,
    priority: 0,
  ) {
    // FÍSICA ESTRICTA (MANTENIDA): Hitbox expandido para barrera impenetrable
    final double expansionFactor = 1.2;
    final Vector2 hitBoxSize = size * expansionFactor;
    final Vector2 hitBoxOffset = (size - hitBoxSize) / 2;

    add(RectangleHitbox(
      position: hitBoxOffset,
      size: hitBoxSize,
      isSolid: true,
    ));
  }
}
