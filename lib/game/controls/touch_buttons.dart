import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../components/player.dart';
import '../core/maze_game.dart';

// Clase que agrupa y posiciona los 4 botones direccionales
class TouchControlButtons extends PositionComponent with HasGameReference<MazeGame> {
  final Player player;

  // Eliminado positionType que ya no existe
  TouchControlButtons(this.player);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Parámetros de diseño
    const double padding = 30;
    const double size = 60;
    const double offset = size + padding / 2;

    final viewportSize = game.camera.viewport.virtualSize;
    
    // Posición base (esquina inferior izquierda)
    final baseX = padding;
    final baseY = viewportSize.y - padding - size;

    // Componente para pintar la forma del botón
    PositionComponent createButtonShape(Color color, String label) {
      return RectangleComponent(
        size: Vector2.all(size),
        paint: Paint()..color = color.withValues(alpha: 0.7), // Actualizado withOpacity -> withValues
      )..add(TextComponent(
        text: label,
        position: Vector2(size / 2, size / 2),
        anchor: Anchor.center,
        textRenderer: TextPaint(style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
      ));
    }

    // Función para crear un botón funcional
    HudButtonComponent createButton(Vector2 dir, double x, double y, String label, String debugName) {
      // HudButtonComponent en versiones nuevas usa onPressed y onReleased
      final button = HudButtonComponent(
        button: createButtonShape(Colors.blue.shade600, label),
        buttonDown: createButtonShape(Colors.blue.shade800, label),
        position: Vector2(x, y),
      );

      // Asignamos los callbacks
      button.onPressed = () {
        player.move(dir);
        // print('🐛 Debug: Control Táctil - Movimiento: $debugName');
      };
      
      button.onReleased = () {
        player.move(Vector2.zero());
      };

      button.onCancelled = () {
        player.move(Vector2.zero());
      };

      return button;
    }

    // --- Botones (Configuración tipo D-Pad) ---
    add(createButton(Vector2(0, -1), baseX + offset, baseY - offset, 'W', 'Arriba'));
    add(createButton(Vector2(0, 1), baseX + offset, baseY, 'S', 'Abajo'));
    add(createButton(Vector2(-1, 0), baseX, baseY, 'A', 'Izquierda'));
    add(createButton(Vector2(1, 0), baseX + offset + offset, baseY, 'D', 'Derecha'));
  }
}
