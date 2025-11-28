import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/core/maze_game.dart';
import '../models/game_config.dart';
import 'level_complete_menu.dart';

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  late MazeGame _game;
  
  // Estados locales para la UI (Sliders, Toggles)
  double _volume = 0.8;
  bool _notifications = true;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    _game = MazeGame();
    _game.config = Provider.of<GameConfig>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.loadMaze(_game.config.currentLevel, _game.config.currentSubMaze);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo oscuro general
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Umbral para Desktop/Web vs Móvil
          bool isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // ================= LAYOUT DE ESCRITORIO (3 COLUMNAS) =================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // --- COLUMNA IZQUIERDA: MENÚ DE USUARIO ---
        Container(
          width: 280,
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OPCIONES', style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              
              _buildSectionTitle('Juego'),
              _buildMenuButton(Icons.pause, 'Pausar', () => _game.pauseEngine()),
              _buildMenuButton(Icons.play_arrow, 'Reanudar', () => _game.resumeEngine()),
              
              const SizedBox(height: 20),
              _buildSectionTitle('Audio'),
              Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      activeColor: Colors.cyan,
                      onChanged: (v) => setState(() => _volume = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Sistema'),
              _buildSwitch('Notificaciones', _notifications, (v) => setState(() => _notifications = v)),
              _buildSwitch('Vibración', _vibration, (v) => setState(() => _vibration = v)),

              const Spacer(),
              const Divider(color: Colors.white24),
              _buildMenuButton(Icons.exit_to_app, 'Salir al Menú', () {
                // Lógica de salida
              }, color: Colors.redAccent),
            ],
          ),
        ),

        // --- COLUMNA CENTRAL: ÁREA DE JUEGO ---
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(10), // Pequeño padding estético
            child: ClipRect( // IMPRESCINDIBLE: Evita que el juego pinte fuera de su caja
              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'LevelCompleteMenu': (context, MazeGame game) => LevelCompleteMenu(game: game),
                },
              ),
            ),
          ),
        ),

        // --- COLUMNA DERECHA: HUD / INFO ---
        Container(
          width: 280,
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ESTADÍSTICAS', style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              
              Consumer<GameConfig>(
                builder: (context, config, _) => Column(
                  children: [
                    _buildStatCard('NIVEL', '${config.currentLevel}', Icons.layers),
                    const SizedBox(height: 15),
                    _buildStatCard('SUB-NIVEL', '${config.currentSubMaze} / ${config.maxSubMazes}', Icons.grid_4x4),
                    const SizedBox(height: 15),
                    _buildStatCard('TIEMPO', config.timeRemaining.toStringAsFixed(1), Icons.timer, valueColor: Colors.greenAccent),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              const Text('RANKING GLOBAL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildRankItem(1, 'Astronixx', '9999'),
                    _buildRankItem(2, 'PlayerOne', '8500'),
                    _buildRankItem(3, 'MazeRunner', '7200'),
                  ],
                ),
              ),
              
              const Divider(color: Colors.white24),
              const Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.cyan, radius: 15, child: Icon(Icons.person, size: 20, color: Colors.black)),
                  SizedBox(width: 10),
                  Text('Usuario: Invitado', style: TextStyle(color: Colors.white)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  // ================= LAYOUT MÓVIL (FULLSCREEN) =================
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Capa 1: Juego (Fondo completo)
        Positioned.fill(
          child: GameWidget(
            game: _game,
            overlayBuilderMap: {
              'LevelCompleteMenu': (context, MazeGame game) => LevelCompleteMenu(game: game),
            },
          ),
        ),

        // Capa 2: Botón de Pausa (Esquina superior izquierda)
        Positioned(
          top: 10,
          left: 10,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(Icons.pause, color: Colors.white),
                ),
                onPressed: () => _showMobilePauseMenu(context),
              ),
            ),
          ),
        ),
        
        // Nota: Los controles táctiles (HUD) ya son gestionados por Flame dentro del juego
        // y añadidos al viewport, así que se verán automáticamente.
      ],
    );
  }

  // ================= MENÚ DE PAUSA MÓVIL (POP-UP) =================
  void _showMobilePauseMenu(BuildContext context) {
    _game.pauseEngine();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('PAUSA', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reanudar
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('REANUDAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  _game.resumeEngine();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 20),
              
              // Toggle Controles (Ejemplo: Touch vs Acelerómetro)
              Consumer<GameConfig>(
                builder: (context, config, _) {
                  bool isTouch = config.activeControl == ControlType.touchButtons;
                  return SwitchListTile(
                    title: const Text('Controles Táctiles', style: TextStyle(color: Colors.white, fontSize: 14)),
                    activeColor: Colors.cyan,
                    value: isTouch,
                    onChanged: (val) {
                      config.setActiveControl(val ? ControlType.touchButtons : ControlType.accelerometer);
                    },
                  );
                },
              ),
              
              // Opciones
              const Divider(color: Colors.white24),
              StatefulBuilder( // Para actualizar sliders dentro del diálogo
                builder: (context, setStateDialog) => Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volume_up, color: Colors.white70, size: 20),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            activeColor: Colors.cyan,
                            onChanged: (v) {
                              setStateDialog(() => _volume = v);
                              setState(() => _volume = v); // Actualizar estado principal
                            },
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: _notifications,
                      activeColor: Colors.cyan,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) { 
                         setStateDialog(() => _notifications = v);
                         setState(() => _notifications = v);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Vibración', style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: _vibration,
                      activeColor: Colors.cyan,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setStateDialog(() => _vibration = v);
                        setState(() => _vibration = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGETS AUXILIARES (ESTILO) =================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
    );
  }

  Widget _buildMenuButton(IconData icon, String text, VoidCallback onPressed, {Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          foregroundColor: color,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSwitch(String text, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(color: Colors.white70)),
        Switch(
          value: value,
          activeColor: Colors.cyan,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color valueColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRankItem(int rank, String name, String score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('#$rank', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          Text(name, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(score, style: const TextStyle(color: Colors.amber)),
        ],
      ),
    );
  }
}
