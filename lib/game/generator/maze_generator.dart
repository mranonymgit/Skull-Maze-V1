import 'dart:math';

// Clase para un único laberinto
class Maze {
  final int rows;
  final int cols;
  final int seed;
  final List<List<bool>> walls; // true = Pared, false = Camino

  Maze(this.rows, this.cols, this.seed, this.walls);
}

class MazeGenerator {
  static Maze generate(int level, int subMazeIndex) {
    int rows, cols;
    
    // 1. Definición de tamaño
    // RESTAURADO: Tamaño grande (45) para que las paredes se vean pequeñas y detalladas.
    // Gracias a la optimización de renderizado, esto ya no causa lag.
    int baseSize = 15;
    int increment = 5;

    rows = baseSize + (level - 1) * increment;
    cols = baseSize + (level - 1) * increment;

    if (rows % 2 == 0) rows++;
    if (cols % 2 == 0) cols++;

    final combinedSeed = level * 1000 + subMazeIndex;
    final Random random = Random(combinedSeed);

    final List<List<bool>> grid = List.generate(rows, (_) => List.filled(cols, true));

    void recursiveBacktracker(int r, int c) {
      grid[r][c] = false;

      final directions = [
        [0, -2], [0, 2], [-2, 0], [2, 0]
      ];
      directions.shuffle(random);

      for (final dir in directions) {
        final nr = r + dir[0];
        final nc = c + dir[1];

        if (nr > 0 && nr < rows - 1 && nc > 0 && nc < cols - 1 && grid[nr][nc]) {
          final wallR = r + dir[0] ~/ 2;
          final wallC = c + dir[1] ~/ 2;
          grid[wallR][wallC] = false;

          recursiveBacktracker(nr, nc);
        }
      }
    }

    recursiveBacktracker(1, 1);
    
    // Braiding (bucles)
    int extraPaths = (rows * cols) ~/ 20; 
    for (int i = 0; i < extraPaths; i++) {
      int r = 1 + random.nextInt(rows - 2);
      int c = 1 + random.nextInt(cols - 2);
      if (grid[r][c]) { 
         grid[r][c] = false;
      }
    }

    // REFUERZO DE MUROS PERIMETRALES
    for (int c = 0; c < cols; c++) {
      grid[0][c] = true;          
      grid[rows - 1][c] = true;   
    }
    for (int r = 0; r < rows; r++) {
      grid[r][0] = true;          
      grid[r][cols - 1] = true;   
    }

    // Definir Entrada
    grid[1][1] = false; 
    
    // Definir Salida (Meta)
    final exitR = rows - 2;
    final exitC = cols - 2;
    
    grid[exitR][exitC] = false; 
    
    if (exitR - 1 > 0) grid[exitR - 1][exitC] = false; // Arriba
    if (exitC - 1 > 0) grid[exitR][exitC - 1] = false; // Izquierda
    
    if (exitR - 1 > 0 && exitC - 1 > 0) grid[exitR - 1][exitC - 1] = false;

    return Maze(rows, cols, combinedSeed, grid);
  }
}
