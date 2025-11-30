import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_config.dart';
import 'level_selector_screen.dart';

class ConfigMenu extends StatelessWidget {
  const ConfigMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<GameConfig>();
    final isMobileOS = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 100.0, left: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: "btn_levels",
              mini: true,
              backgroundColor: Colors.grey.shade800,
              child: const Icon(Icons.map, color: Colors.white),
              onPressed: () async {
                final selectedLevel = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LevelSelectorScreen(),
                  ),
                );
                
                if (selectedLevel != null && selectedLevel is int) {
                  // Aquí se podría añadir lógica para cargar el nivel seleccionado
                  config.currentLevel = selectedLevel;
                  config.currentSubMaze = 1; // Resetear sub-nivel al cambiar de nivel principal
                  // Reiniciar el juego sería necesario, pero eso depende de GameUIController
                }
              },
            ),
            const SizedBox(height: 10),
            if (isMobileOS || config.activeControl != ControlType.keyboard)
              FloatingActionButton(
                heroTag: "btn_settings",
                mini: true,
                backgroundColor: Colors.grey.shade800,
                child: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  _showControlSettings(context, config);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showControlSettings(BuildContext context, GameConfig config) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Modo de Control Móvil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opción 1: Botones Táctiles
              RadioListTile<ControlType>(
                title: const Text('Botones Táctiles'),
                value: ControlType.touchButtons,
                groupValue: config.activeControl,
                onChanged: (ControlType? value) {
                  if (value != null) {
                    config.setActiveControl(value);
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),

              // Opción 2: Acelerómetro
              RadioListTile<ControlType>(
                title: const Text('Acelerómetro (Inclinación)'),
                value: ControlType.accelerometer,
                groupValue: config.activeControl,
                onChanged: (ControlType? value) {
                  if (value != null) {
                    config.setActiveControl(value);
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
