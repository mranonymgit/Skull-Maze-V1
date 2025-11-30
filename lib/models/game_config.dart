import 'package:flutter/foundation.dart';

// Tipos de control soportados
enum ControlType {
  keyboard,
  accelerometer,
  touchButtons,
  gamepad
}

// === MODELO (M) ===
// Almacena TODOS los datos y el estado de la aplicación.
class GameConfig extends ChangeNotifier {
  // -- Estado del Juego --
  ControlType _activeControl = ControlType.keyboard; 
  int _currentLevel = 1;
  int _currentSubMaze = 1;
  int _maxSubMazes = 2; 
  double _timeRemaining = 60.0;
  bool _isPaused = false; 

  // -- Configuración de Usuario --
  double _volume = 0.8;
  bool _notifications = true;
  bool _vibration = true;

  // Flag de hardware
  bool _hasAccelerometer = false;

  GameConfig() {
    _detectPlatformControl();
  }

  // Getters
  ControlType get activeControl => _activeControl;
  int get currentLevel => _currentLevel;
  int get currentSubMaze => _currentSubMaze;
  int get maxSubMazes => _maxSubMazes;
  double get timeRemaining => _timeRemaining;
  bool get isAccelerometerAvailable => _hasAccelerometer;
  bool get isPaused => _isPaused;
  
  // Getters Configuración
  double get volume => _volume;
  bool get notifications => _notifications;
  bool get vibration => _vibration;

  // Setters públicos
  set currentLevel(int value) {
    if (_currentLevel != value) {
      _currentLevel = value;
      notifyListeners();
    }
  }

  set currentSubMaze(int value) {
    if (_currentSubMaze != value) {
      _currentSubMaze = value;
      notifyListeners();
    }
  }

  set timeRemaining(double value) {
    if (_timeRemaining != value) {
      _timeRemaining = value;
      notifyListeners();
    }
  }

  // -- Lógica de Datos --

  void _detectPlatformControl() {
    if (kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS) {
        _activeControl = ControlType.touchButtons;
        _hasAccelerometer = false; 
      } else {
        _activeControl = ControlType.keyboard;
        _hasAccelerometer = false;
      }
    } else {
      if (defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS) {
        _activeControl = ControlType.touchButtons;
        _hasAccelerometer = true;
      } else {
        _activeControl = ControlType.keyboard;
        _hasAccelerometer = false;
      }
    }
  }

  void setActiveControl(ControlType newControl) {
    if (_activeControl != newControl) {
      _activeControl = newControl;
      notifyListeners();
    }
  }

  void setPaused(bool paused) {
    _isPaused = paused;
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value;
    notifyListeners();
  }

  void setNotifications(bool value) {
    _notifications = value;
    notifyListeners();
  }

  void setVibration(bool value) {
    _vibration = value;
    notifyListeners();
  }

  void updateTime(double dt) {
    if (!_isPaused) { 
      _timeRemaining -= dt;
      if (_timeRemaining < 0) _timeRemaining = 0;
      notifyListeners(); 
    }
  }

  // Método principal para avanzar el juego
  void advanceMaze() {
    _currentSubMaze++;
    
    // Si superamos el número de sub-niveles, pasamos al siguiente nivel principal
    if (_currentSubMaze > _maxSubMazes) {
      _currentLevel++;
      _currentSubMaze = 1;
      
      // Ajustar dificultad de subniveles
      _maxSubMazes = (_currentLevel == 1) ? 2 : 3;
    }
    
    // ASIGNACIÓN DE TIEMPO DINÁMICO SEGÚN NIVEL
    // Nivel 1: 30s
    // Nivel 2: 40s
    // Nivel 3: 50s
    // Nivel 4: 60s
    // Nivel 5+: +5s por nivel (65s, 70s...)
    if (_currentLevel == 1) {
      _timeRemaining = 30.0;
    } else if (_currentLevel <= 4) {
      // Base 40s en nivel 2, aumentando 10s por nivel hasta el 4
      // L2 -> 40s, L3 -> 50s, L4 -> 60s
      _timeRemaining = 40.0 + (_currentLevel - 2) * 10.0;
    } else {
      // Nivel 5 en adelante: Base 60s (del nivel 4) + 5s por cada nivel extra
      _timeRemaining = 60.0 + (_currentLevel - 4) * 5.0;
    }
    
    notifyListeners();
  }
}
