import 'package:flutter/foundation.dart';

// Tipos de control soportados
enum ControlType {
  keyboard,      // PC/Laptop, Web Desktop
  accelerometer, // Móvil (Opcional)
  touchButtons,  // Móvil, Web Móvil
  gamepad        // Consolas/Otros
}

// Clase para almacenar la configuración y el estado de la UI
class GameConfig extends ChangeNotifier {
  ControlType _activeControl = ControlType.keyboard; // Default temporal
  int _currentLevel = 1;
  int _currentSubMaze = 1;
  int _maxSubMazes = 2; // Nivel 1 tiene 2
  double _timeRemaining = 60.0; // 60 segundos por defecto

  GameConfig() {
    _detectPlatformControl();
  }

  ControlType get activeControl => _activeControl;
  int get currentLevel => _currentLevel;
  int get currentSubMaze => _currentSubMaze;
  int get maxSubMazes => _maxSubMazes;
  double get timeRemaining => _timeRemaining;

  // Detectar la plataforma y asignar el control por defecto
  void _detectPlatformControl() {
    if (kIsWeb) {
      // En Web, verificamos si es un navegador móvil por la plataforma target
      // defaultTargetPlatform en web devuelve la plataforma del SO subyacente si es posible,
      // o TargetPlatform.android / .iOS si se está simulando o accediendo desde móvil.
      if (defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS) {
        _activeControl = ControlType.touchButtons;
      } else {
        _activeControl = ControlType.keyboard;
      }
    } else {
      // Apps nativas
      if (defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS) {
        _activeControl = ControlType.touchButtons;
      } else {
        // Windows, Mac, Linux, Fuchsia
        _activeControl = ControlType.keyboard;
      }
    }
    // print('🐛 Debug: Plataforma detectada: $defaultTargetPlatform, Web: $kIsWeb -> Control inicial: $_activeControl'); // Print eliminado
  }

  // Método para actualizar el control activo manualmente
  void setActiveControl(ControlType newControl) {
    if (_activeControl != newControl) {
      _activeControl = newControl;
      // Requisito: Debug de Control de Entrada
      // print('🐛 Debug: Control de Entrada Activo: $_activeControl'); // Print eliminado
      notifyListeners();
    }
  }

  // Método para el temporizador
  void updateTime(double dt) {
    _timeRemaining -= dt;
    if (_timeRemaining < 0) _timeRemaining = 0;
    notifyListeners();
  }

  // Lógica para avanzar de laberinto/nivel (simplificada)
  void advanceMaze() {
    _currentSubMaze++;
    // Lógica para el siguiente nivel o laberinto
    if (_currentSubMaze > _maxSubMazes) {
      _currentLevel++;
      _currentSubMaze = 1;
      _maxSubMazes = (_currentLevel == 1) ? 2 : 3;
    }
    _timeRemaining = 60.0; // Resetear tiempo
    notifyListeners();
  }
}
