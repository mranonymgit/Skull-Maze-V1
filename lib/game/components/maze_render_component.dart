import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MazeRenderComponent extends PositionComponent {
  final List<List<bool>> walls;
  final double wallSize;
  final Color wallColor;
  
  // Cacheamos la imagen del laberinto para no redibujar rectángulos en cada frame
  Picture? _mazePicture;

  MazeRenderComponent({
    required this.walls,
    required this.wallSize,
    required this.wallColor,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Pre-renderizamos el laberinto
    _renderMazeToPicture();
  }

  void _renderMazeToPicture() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = wallColor..style = PaintingStyle.fill;
    
    int rows = walls.length;
    int cols = walls[0].length;
    
    // Optimizacion: Dibujar todos los rectángulos en un path o batch suele ser mejor
    // Pero en Flutter, drawRects es bastante eficiente si no son objetos separados.
    // Aún mejor: Crear un solo Path con todas las paredes.
    final path = Path();
    
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (walls[r][c]) {
          path.addRect(Rect.fromLTWH(c * wallSize, r * wallSize, wallSize, wallSize));
        }
      }
    }
    
    canvas.drawPath(path, paint);
    _mazePicture = recorder.endRecording();
    
    // Definimos el tamaño total del componente
    size = Vector2(cols * wallSize, rows * wallSize);
  }

  @override
  void render(Canvas canvas) {
    if (_mazePicture != null) {
      canvas.drawPicture(_mazePicture!);
    }
  }
}
