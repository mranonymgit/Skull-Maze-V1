import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_config.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class HUDWidget extends StatefulWidget {
  const HUDWidget({super.key});

  @override
  State<HUDWidget> createState() => _HUDWidgetState();
}

class _HUDWidgetState extends State<HUDWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Shake animation: moves left and right
    _shakeAnimation = Tween<double>(begin: 0, end: 2).animate( // Reduced amplitude to 2
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<GameConfig>();

    // Formato del temporizador a minutos:segundos
    final timeFormatted = Duration(seconds: config.timeRemaining.toInt())
        .toString()
        .split('.')
        .first
        .substring(2);
    
    bool isCriticalTime = config.timeRemaining <= 10 && config.timeRemaining > 0;

    // Lógica de vibración y shake si el tiempo es crítico
    if (isCriticalTime) {
      // Detectar cambio de segundo para shake y vibración
      if ((config.timeRemaining * 10).toInt() % 10 == 0) { 
         // Vibrar solo si está habilitado
         if (config.vibration && !kIsWeb) {
             Vibration.vibrate(duration: 50, amplitude: 128); 
         }
         // Iniciar shake cada segundo
         if (!_shakeController.isAnimating) {
           _shakeController.forward(from: 0);
         }
      }
    } else {
      _shakeController.reset();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Requisito: Temporizador Visible con Shake y Color
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                // Shake muy mínimo (2.5px max amplitude)
                double offset = isCriticalTime 
                    ? sin(_shakeController.value * pi * 4) * 2.5 
                    : 0;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // Verde si > 10, Rojo si <= 10
                  color: isCriticalTime ? Colors.red.withOpacity(0.9) : Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: isCriticalTime ? Border.all(color: Colors.redAccent, width: 2) : null,
                  boxShadow: isCriticalTime ? [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
                child: Row(
                  children: [
                    if (isCriticalTime) 
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      ),
                    Text(
                      '⏱️ Tiempo: $timeFormatted',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
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
