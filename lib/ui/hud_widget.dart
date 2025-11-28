import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_config.dart';

class HUDWidget extends StatelessWidget {
  const HUDWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<GameConfig>();

    // Formato del temporizador a minutos:segundos
    final timeFormatted = Duration(seconds: config.timeRemaining.toInt())
        .toString()
        .split('.')
        .first
        .substring(2);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Requisito: Temporizador Visible
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⏱️ Tiempo: $timeFormatted',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // Requisito: Contador de Progreso
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Laberinto ${config.currentSubMaze} de ${config.maxSubMazes}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}