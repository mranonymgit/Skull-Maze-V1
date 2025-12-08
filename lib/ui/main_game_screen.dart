import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/core/maze_game.dart';
import '../models/game_config.dart';
import '../controllers/game_ui_controller.dart';
import 'level_complete_menu.dart';
import 'hud_widget.dart'; // Importar el HUD

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  late MazeGame _game;
  late GameUIController _controller;

  @override
  void initState() {
    super.initState();
    _game = MazeGame();
    
    final config = Provider.of<GameConfig>(context, listen: false);
    _game.config = config;
    
    _controller = GameUIController(config: config, game: _game);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.loadMaze(config.currentLevel, config.currentSubMaze);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de volumen para actualizar la música del nivel en tiempo real
    final config = context.watch<GameConfig>();
    try {
       if (FlameAudio.bgm.isPlaying) {
          FlameAudio.bgm.audioPlayer.setVolume(config.volume);
       }
    } catch (e) {
       // Ignore errors
    }

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
        // --- COLUMNA IZQUIERDA (Menú) ---
        Container(
          width: 280,
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.all(20),
          child: Consumer<GameConfig>( 
            builder: (context, config, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OPCIONES', style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                
                _buildSectionTitle('Juego'),
                _buildMenuButton(
                  config.isPaused ? Icons.play_arrow : Icons.pause, 
                  config.isPaused ? 'Reanudar' : 'Pausar', 
                  _controller.togglePause, 
                  color: config.isPaused ? Colors.greenAccent : Colors.white
                ),
                
                const SizedBox(height: 20),
                _buildSectionTitle('Audio'),
                Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white70),
                    Expanded(
                      child: Slider(
                        value: config.volume, 
                        activeColor: Colors.cyan,
                        onChanged: _controller.updateVolume, 
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(config.volume * 100).round()}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionTitle('Sistema'),
                _buildSwitch('Notificaciones', config.notifications, _controller.toggleNotifications),
                _buildSwitch('Vibración', config.vibration, _controller.toggleVibration),

                const Spacer(),
                const Divider(color: Colors.white24),
                _buildMenuButton(Icons.exit_to_app, 'Salir al Menú', () => _controller.exitToMenuWithConfirmation(context), color: Colors.redAccent),
              ],
            ),
          ),
        ),

        // --- COLUMNA CENTRAL (Juego) ---
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(10), 
            child: ClipRect( 
              child: Stack(
                children: [
                  GameWidget(
                    game: _game,
                    overlayBuilderMap: {
                      'LevelCompleteMenu': (BuildContext context, MazeGame game) {
                        return LevelCompleteMenu(game: game);
                      },
                    },
                  ),
                  // Eliminado HUDWidget de aquí para versión Desktop/Web grande
                ],
              ),
            ),
          ),
        ),

        // --- COLUMNA DERECHA (HUD) ---
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
                builder: (context, config, _) {
                  // Lógica de color para el tiempo en Desktop
                  Color timeColor = config.timeRemaining <= 10 ? Colors.redAccent : Colors.greenAccent;
                  
                  return Column(
                    children: [
                      _buildStatCard('NIVEL', '${config.currentLevel}', Icons.layers),
                      const SizedBox(height: 15),
                      _buildStatCard('SUB-NIVEL', '${config.currentSubMaze} / ${config.maxSubMazes}', Icons.grid_4x4),
                      const SizedBox(height: 15),
                      _buildStatCard('TIEMPO', config.timeRemaining.toStringAsFixed(1), Icons.timer, valueColor: timeColor),
                    ],
                  );
                },
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
              'LevelCompleteMenu': (BuildContext context, MazeGame game) {
                return LevelCompleteMenu(game: game);
              },
            },
          ),
        ),
        
        // HUD UNIFICADO (Centro Superior) - Usando HUDWidget
        const HUDWidget(),

        // Botón de Pausa (Izquierda)
        Positioned(
          top: 10, left: 10,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white30)),
                  child: const Icon(Icons.pause, color: Colors.white),
                ),
                onPressed: () => _showMobilePauseMenu(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= MENÚ DE PAUSA MÓVIL =================
  void _showMobilePauseMenu(BuildContext context) {
    _controller.togglePause(); 
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Center(child: Text('PAUSA', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 18))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        content: SizedBox(
          width: 280, 
          child: Consumer<GameConfig>( 
            builder: (context, config, _) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('REANUDAR', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 40)),
                    onPressed: () {
                      _controller.togglePause(); 
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 15), const Divider(color: Colors.white12, height: 1), const SizedBox(height: 10),
                  
                  if (config.isAccelerometerAvailable)
                    _buildCompactSwitchTile(
                      'Control Táctil',
                      config.activeControl == ControlType.touchButtons,
                      (val) => _controller.setControlMode(val),
                    ),
                  
                  Row(
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white70, size: 18),
                      Expanded(
                        child: Slider(
                          value: config.volume,
                          activeColor: Colors.cyan,
                          onChanged: (val) {
                             // Actualizar volumen del config, esto desencadenará la actualización en MainGameScreen (build)
                             // y MazeGame (update) para ajustar la música en tiempo real
                             _controller.updateVolume(val);
                          },
                        ),
                      ),
                      SizedBox(width: 35, child: Text('${(config.volume * 100).round()}%', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.end)),
                    ],
                  ),
                  
                  _buildCompactSwitchTile('Notificaciones', config.notifications, _controller.toggleNotifications),
                  _buildCompactSwitchTile('Vibración', config.vibration, _controller.toggleVibration),
                  
                  const SizedBox(height: 15), const Divider(color: Colors.white12, height: 1), const SizedBox(height: 15),

                  TextButton.icon(
                    icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 18),
                    label: const Text('SALIR AL MENÚ', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () {
                      Navigator.pop(ctx); 
                      _controller.exitToMenuWithConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 30, child: Switch(value: value, activeColor: Colors.cyan, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)));
  
  Widget _buildMenuButton(IconData icon, String text, VoidCallback onPressed, {Color color = Colors.white}) => Container(
    margin: const EdgeInsets.symmetric(vertical: 5), width: double.infinity,
    child: ElevatedButton.icon(icon: Icon(icon, size: 18), label: Text(text), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.05), foregroundColor: color, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20)), onPressed: onPressed),
  );

  Widget _buildSwitch(String text, bool value, Function(bool) onChanged) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(text, style: const TextStyle(color: Colors.white70)), Switch(value: value, activeColor: Colors.cyan, onChanged: onChanged)]);

  Widget _buildStatCard(String label, String value, IconData icon, {Color valueColor = Colors.white}) => Container(
    padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
    child: Row(children: [Icon(icon, color: Colors.cyan, size: 30), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)), Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold))])]),
  );

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
