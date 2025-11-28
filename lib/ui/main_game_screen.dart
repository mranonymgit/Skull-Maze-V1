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

  // Estados locales para la UI
  double _volume = 0.8;
  bool _notifications = true;
  bool _vibration = true;

  // Estado para el botón dinámico de Pausa/Reanudar en escritorio
  bool _isGamePaused = false;

  @override
  void initState() {
    super.initState();
    _game = MazeGame();
    _game.config = Provider.of<GameConfig>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.loadMaze(_game.config.currentLevel, _game.config.currentSubMaze);
    });
  }

  void _togglePause() {
    setState(() {
      if (_game.paused) {
        _game.resumeEngine();
        _isGamePaused = false;
      } else {
        _game.pauseEngine();
        _isGamePaused = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: LayoutBuilder(
        builder: (context, constraints) {
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

  // ================= LAYOUT DE ESCRITORIO =================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // --- COLUMNA IZQUIERDA ---
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
              _buildMenuButton(
                _isGamePaused ? Icons.play_arrow : Icons.pause,
                _isGamePaused ? 'Reanudar' : 'Pausar',
                _togglePause,
                color: _isGamePaused ? Colors.greenAccent : Colors.white
              ),

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
              _buildMenuButton(Icons.exit_to_app, 'Salir al Menú', () {}, color: Colors.redAccent),
            ],
          ),
        ),

        // --- COLUMNA CENTRAL ---
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(10),
            child: ClipRect(
              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'LevelCompleteMenu': (context, MazeGame game) => LevelCompleteMenu(game: game),
                },
              ),
            ),
          ),
        ),

        // --- COLUMNA DERECHA ---
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

  // ================= LAYOUT MÓVIL =================
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Positioned.fill(
          child: GameWidget(
            game: _game,
            overlayBuilderMap: {
              'LevelCompleteMenu': (context, MazeGame game) => LevelCompleteMenu(game: game),
            },
          ),
        ),

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

        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: Consumer<GameConfig>(
                builder: (context, config, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        config.timeRemaining.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: Consumer<GameConfig>(
                builder: (context, config, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'NIVEL ${config.currentLevel}  •  SUB ${config.currentSubMaze}/${config.maxSubMazes}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= MENÚ DE PAUSA MÓVIL (CORREGIDO Y COMPACTO) =================
  void _showMobilePauseMenu(BuildContext context) {
    _game.pauseEngine();
    setState(() => _isGamePaused = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        // Título compacto
        title: const Center(child: Text('PAUSA', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 18))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        content: SizedBox(
          width: 280, // Ancho controlado para móviles pequeños
          child: SingleChildScrollView( // Evita overflow en pantallas muy pequeñas apaisadas
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Reanudar destacado
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('REANUDAR', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 40), // Altura compacta
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onPressed: () {
                    _game.resumeEngine();
                    setState(() => _isGamePaused = false);
                    Navigator.pop(ctx);
                  },
                ),

                const SizedBox(height: 15),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                // Toggle Controles (si aplica)
                Consumer<GameConfig>(
                  builder: (context, config, _) {
                    if (config.isAccelerometerAvailable) {
                      return _buildCompactSwitchTile(
                        'Control Táctil',
                        config.activeControl == ControlType.touchButtons,
                        (val) => config.setActiveControl(val ? ControlType.touchButtons : ControlType.accelerometer),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Opciones de Audio y Sistema (RECUPERADAS)
                StatefulBuilder(
                  builder: (context, setStateDialog) => Column(
                    children: [
                      // Slider de Volumen Compacto
                      Row(
                        children: [
                          const Icon(Icons.volume_up, color: Colors.white70, size: 18),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              ),
                              child: Slider(
                                value: _volume,
                                activeColor: Colors.cyan,
                                onChanged: (v) {
                                  setStateDialog(() => _volume = v);
                                  setState(() => _volume = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Switches recuperados y compactos
                      _buildCompactSwitchTile(
                        'Notificaciones',
                        _notifications,
                        (v) {
                           setStateDialog(() => _notifications = v);
                           setState(() => _notifications = v);
                        }
                      ),
                      _buildCompactSwitchTile(
                        'Vibración',
                        _vibration,
                        (v) {
                           setStateDialog(() => _vibration = v);
                           setState(() => _vibration = v);
                        }
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 15),

                // Botón Salir al Menú
                TextButton.icon(
                  icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 18),
                  label: const Text('SALIR AL MENÚ', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para switches compactos en el menú móvil
  Widget _buildCompactSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // Menos espacio vertical
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)), // Fuente más pequeña
          SizedBox(
            height: 30, // Altura forzada para reducir el switch
            child: Switch(
              value: value,
              activeColor: Colors.cyan,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce área táctil extra
            ),
          ),
        ],
      ),
    );
  }

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
