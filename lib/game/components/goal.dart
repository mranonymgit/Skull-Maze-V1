import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GoalComponent extends RectangleComponent with CollisionCallbacks {
  GoalComponent({required Vector2 position, required Vector2 size})
      : super(
          position: position,
          size: size,
          paint: Paint()..color = Colors.greenAccent, // Color distintivo
          anchor: Anchor.center,
        ) {
    // Sensor: true significa que detecta colisión pero no frena al jugador físicamente
    add(RectangleHitbox(isSolid: false)); 
  }
}
