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
  bool _isPaused = false; // Nuevo: Estado de pausa en el modelo

  // -- Configuración de Usuario (NUEVO) --
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

  // Setters que notifican a la Vista (Provider)
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
    if (!_isPaused) { // El modelo controla si el tiempo corre
      _timeRemaining -= dt;
      if (_timeRemaining < 0) _timeRemaining = 0;
      // notifyListeners(); // Opcional: optimización para no redibujar todo a 60fps solo por el timer
    }
  }

  void advanceMaze() {
    _currentSubMaze++;
    if (_currentSubMaze > _maxSubMazes) {
      _currentLevel++;
      _currentSubMaze = 1;
      _maxSubMazes = (_currentLevel == 1) ? 2 : 3;
    }
    _timeRemaining = 60.0; 
    notifyListeners();
  }
}
