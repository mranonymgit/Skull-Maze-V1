import 'dart:math';

// Clase para un único laberinto
class Maze {
  final int rows;
  final int cols;
  final int seed;
  final List<List<bool>> walls; // true = Pared, false = Camino
  
  // Nuevos campos para posiciones dinámicas
  final int startRow;
  final int startCol;
  final int goalRow;
  final int goalCol;

  Maze(this.rows, this.cols, this.seed, this.walls, this.startRow, this.startCol, this.goalRow, this.goalCol);
}

class MazeGenerator {
  static Maze generate(int level, int subMazeIndex) {
    int rows, cols;
    
    // 1. LÓGICA DE TAMAÑO Y DIFICULTAD POR NIVELES
    if (level < 5) {
      // Niveles 1-4: Crecimiento progresivo normal (15 -> 30)
      int baseSize = 15;
      int increment = 5;
      rows = baseSize + (level - 1) * increment;
      cols = baseSize + (level - 1) * increment;
    } else if (level < 10) {
      // Niveles 5-9: Tamaño fijo a 31
      rows = 31;
      cols = 31;
    } else {
      // Nivel 10+: Aumento masivo de tamaño (61+)
      // Al tener muchas más celdas, el zoom "Fit" hará que todo se vea más pequeño.
      rows = 61 + (level - 10) * 10;
      cols = 61 + (level - 10) * 10;
    }

    // Asegurar impares
    if (rows % 2 == 0) rows++;
    if (cols % 2 == 0) cols++;

    final combinedSeed = level * 1000 + subMazeIndex;
    final Random random = Random(combinedSeed);

    final List<List<bool>> grid = List.generate(rows, (_) => List.filled(cols, true));

    // Algoritmo Recursive Backtracker
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

    // Generamos estructura base
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
      grid[0][c] = true; grid[rows - 1][c] = true;   
    }
    for (int r = 0; r < rows; r++) {
      grid[r][0] = true; grid[r][cols - 1] = true;   
    }

    // 2. LÓGICA DE POSICIONES (JUGADOR Y META)
    int sR, sC, gR, gC;

    if (level < 5) {
      // Niveles 1-4: Clásico (Inicio Arriba-Izq, Meta Abajo-Der)
      sR = 1; sC = 1;
      gR = rows - 2; gC = cols - 2;
    } else {
      // Nivel 5+: Invertir o rotar posiciones para aumentar dificultad
      // Usamos el random seed para decidir la configuración de este subnivel
      bool configA = random.nextBool();
      
      if (configA) {
        // Invertido: Inicio Abajo-Der, Meta Arriba-Izq
        sR = rows - 2; sC = cols - 2;
        gR = 1; gC = 1;
      } else {
        // Cruzado: Inicio Abajo-Izq, Meta Arriba-Der
        sR = rows - 2; sC = 1;
        gR = 1; gC = cols - 2;
      }
    }

    // 3. APLICAR Y LIMPIAR ZONAS
    grid[sR][sC] = false; // Inicio
    grid[gR][gC] = false; // Meta

    // Helper para limpiar alrededor de un punto (sin romper perímetro)
    void clearAround(int r, int c) {
      if (r - 1 > 0) grid[r - 1][c] = false; 
      if (r + 1 < rows - 1) grid[r + 1][c] = false; 
      if (c - 1 > 0) grid[r][c - 1] = false; 
      if (c + 1 < cols - 1) grid[r][c + 1] = false;
    }

    clearAround(gR, gC); // Limpiar meta
    clearAround(sR, sC); // Limpiar inicio (para que el jugador no empiece atascado)

    return Maze(rows, cols, combinedSeed, grid, sR, sC, gR, gC);
  }
}
