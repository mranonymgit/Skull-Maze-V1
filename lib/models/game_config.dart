import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; 
import '../services/database_service.dart';
import '../services/firestore_service.dart'; // Importar FirestoreService
import 'level_data.dart';
import 'dart:async'; // Importar Timer

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
  double _levelTotalTime = 60.0; 
  bool _isPaused = false; 

  // -- Configuración de Usuario --
  double _volume = 0.8;
  bool _notifications = true;
  bool _vibration = true;
  
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  
  // Personaje seleccionado (por defecto Catty)
  String _selectedCharacter = 'Catty';
  
  // Nombre del jugador y Score
  String _playerName = 'Invitado';
  int _totalScore = 0;
  bool _isAdmin = false;

  // Flag de hardware
  bool _hasAccelerometer = false;

  // Niveles cargados desde BD
  List<LevelData> _levels = [];
  
  Timer? _autoSaveTimer; // Timer para guardado periódico

  GameConfig() {
    _detectPlatformControl();
    _loadData(); 
    _loadUserProfile(); 
    _startPeriodicSave(); // Iniciar timer de guardado
  }
  
  // Timer de autoguardado cada 5 segundos
  void _startPeriodicSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _autoSaveSettings();
    });
  }
  
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // Getters
  ControlType get activeControl => _activeControl;
  int get currentLevel => _currentLevel;
  int get currentSubMaze => _currentSubMaze;
  int get maxSubMazes => _maxSubMazes;
  double get timeRemaining => _timeRemaining;
  double get levelTotalTime => _levelTotalTime;
  bool get isAccelerometerAvailable => _hasAccelerometer;
  bool get isPaused => _isPaused;
  String get selectedCharacter => _selectedCharacter;
  String get playerName => _playerName;
  int get totalScore => _totalScore;
  bool get isAdmin => _isAdmin;
  
  // Getters Configuración
  double get volume => _volume;
  bool get notifications => _notifications;
  bool get vibration => _vibration;
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  
  List<LevelData> get levels => _levels;

  // Setters públicos con AUTOGUARDADO
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
  
  void setPlayerName(String name) {
    _playerName = name;
    notifyListeners();
    _autoSaveSettings(); 
  }

  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
    if (isAdmin) {
      _playerName = 'Admin';
      _totalScore = 99999;
      _updateScoreOnServer(99999);
      _unlockAllContent();
    }
    notifyListeners();
  }

  // --- AUTOGUARDADO INTELIGENTE ---
  Future<void> _autoSaveSettings() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      saveSettings();
      
      await FirestoreService().updateSettings(user.uid, {
        'volume': _volume,
        'notifications': _notifications,
        'vibration': _vibration,
        'musicEnabled': _musicEnabled,
        'sfxEnabled': _sfxEnabled,
        'character': _selectedCharacter,
      });
    }
  }

  // --- SETTERS CON GUARDADO AUTOMÁTICO ---

  void setSelectedCharacter(String name) {
    _selectedCharacter = name;
    notifyListeners();
    _autoSaveSettings(); 
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirestoreService().updateCharacter(user.uid, name);
    }
  }

  void setVolume(double value) {
    _volume = value;
    notifyListeners();
  }
  
  void setMusicEnabled(bool value) {
    _musicEnabled = value;
    notifyListeners();
    _autoSaveSettings();
  }
  
  void setSfxEnabled(bool value) {
    _sfxEnabled = value;
    notifyListeners();
    _autoSaveSettings();
  }

  void setNotifications(bool value) {
    _notifications = value;
    notifyListeners();
    _autoSaveSettings();
  }

  void setVibration(bool value) {
    _vibration = value;
    notifyListeners();
    _autoSaveSettings();
  }
  
  // Restablecer SOLO configuraciones
  void resetSettings() {
    _volume = 0.8;
    _notifications = true;
    _vibration = true;
    _musicEnabled = true;
    _sfxEnabled = true;
    _detectPlatformControl();
    notifyListeners();
    _autoSaveSettings(); 
  }

  // --- LÓGICA EXISTENTE ---

  Future<void> _unlockAllContent() async {
    for (int i = 1; i <= 10; i++) {
      await DatabaseService().unlockLevel(i);
    }
    _levels = await DatabaseService().getLevels();
    notifyListeners();
  }
  
  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // 1. Cargar niveles DESDE LA NUBE para asegurar sincronización tras borrado local
        // Si el usuario reinstala o borra datos, FirestoreService.getUserLevels traerá su progreso real
        List<LevelData> cloudLevels = await FirestoreService().getUserLevels(user.uid);
        
        // Sincronizar base de datos LOCAL con la NUBE
        // Actualizamos la BD local para que refleje lo que hay en la nube
        for (var cloudLevel in cloudLevels) {
           if (cloudLevel.isUnlocked) {
              await DatabaseService().unlockLevel(cloudLevel.levelNumber);
           }
           if (cloudLevel.stars > 0) {
              await DatabaseService().saveLevelProgress(cloudLevel.levelNumber, 0, cloudLevel.stars);
           }
        }
        
        // Recargar niveles locales actualizados
        _levels = await DatabaseService().getLevels();

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          _playerName = data['alias'] ?? 'Jugador';
          _totalScore = data['score'] ?? 0;
          
          if (_playerName == 'admin' || data['email'] == 'admin@skullmaze.com') {
             _isAdmin = true;
             _totalScore = 99999; 
             _updateScoreOnServer(99999); 
          }
          
          if (data['settings'] != null) {
             final s = data['settings'];
             if (s['volume'] != null) _volume = (s['volume'] as num).toDouble();
             if (s['notifications'] != null) _notifications = s['notifications'];
             if (s['vibration'] != null) _vibration = s['vibration'];
             if (s['musicEnabled'] != null) _musicEnabled = s['musicEnabled'];
             if (s['sfxEnabled'] != null) _sfxEnabled = s['sfxEnabled'];
             if (s['character'] != null) _selectedCharacter = s['character'];
          }
          
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error cargando perfil: $e");
      }
    } else {
       // Si no hay usuario (logout), cargar solo local
       _loadData();
    }
  }
  
  Future<void> _updateScoreOnServer(int newScore) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       try {
         try {
           final callable = FirebaseFunctions.instance.httpsCallable('updateRanking');
           await callable.call({'score': newScore});
         } catch (e) {
           await FirebaseFirestore.instance
               .collection('users')
               .doc(user.uid)
               .update({'score': newScore});
         }
       } catch (e) {
         debugPrint("Error actualizando score: $e");
       }
    }
  }

  Future<void> _loadData() async {
    try {
       _levels = await DatabaseService().getLevels();
       notifyListeners();
    } catch (e) {
       debugPrint("Error cargando datos: $e");
    }
  }
  
  Future<void> saveSettings() async {
    try {
      await DatabaseService().saveSetting('volume', _volume.toString());
      await DatabaseService().saveSetting('notifications', _notifications.toString());
      await DatabaseService().saveSetting('vibration', _vibration.toString());
      await DatabaseService().saveSetting('character', _selectedCharacter);
      
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().updateSettings(user.uid, {
          'volume': _volume,
          'notifications': _notifications,
          'vibration': _vibration,
          'musicEnabled': _musicEnabled,
          'sfxEnabled': _sfxEnabled,
          'character': _selectedCharacter,
        });
      }
    } catch (e) {
      debugPrint("Error guardando ajustes: $e");
    }
  }

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

  void updateTime(double dt) {
    if (!_isPaused) { 
      _timeRemaining -= dt;
      if (_timeRemaining < 0) _timeRemaining = 0;
      notifyListeners(); 
    }
  }

  void resetTimeForCurrentLevel() {
    double time = 60.0;
    if (_currentLevel == 1) {
      time = 30.0;
    } else if (_currentLevel <= 4) {
      time = 40.0 + (_currentLevel - 2) * 10.0;
    } else {
      time = 60.0 + (_currentLevel - 4) * 5.0;
    }
    _levelTotalTime = time;
    _timeRemaining = time;
  }

  void advanceMaze() {
    // Sumar puntos al completar el SUBNIVEL actual (antes de avanzar)
    int pointsPerSubLevel = (_currentLevel <= 4) ? 15 : 20;
    _addScore(pointsPerSubLevel);

    _currentSubMaze++;
    
    if (_currentSubMaze > _maxSubMazes) {
      // --- NIVEL COMPLETADO ---
      _saveLevelComplete(_currentLevel);
      
      _currentLevel++;
      _currentSubMaze = 1;
      
      _unlockNextLevel(_currentLevel);
      
      _maxSubMazes = (_currentLevel == 1) ? 2 : 3;
      resetTimeForCurrentLevel();
    }
    
    notifyListeners();
  }
  
  void _addScore(int points) {
     if (!_isAdmin) { // Admin tiene score fijo
       _totalScore += points;
       _updateScoreOnServer(_totalScore);
       notifyListeners();
     }
  }
  
  Future<void> _saveLevelComplete(int level) async {
    int stars = 1;
    if (_timeRemaining > _levelTotalTime * 0.5) stars = 3;
    else if (_timeRemaining > _levelTotalTime * 0.2) stars = 2;

    // Guardar progreso local
    await DatabaseService().saveLevelProgress(level, _timeRemaining, stars);
    
    // Guardar en nube con TIEMPO TOTAL del nivel para cálculo preciso
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       // Pasamos levelTotalTime para que FirestoreService calcule: Jugado = Total - Restante
       await FirestoreService().saveLevelProgress(
         user.uid, 
         level, 
         _timeRemaining, 
         stars,
         _levelTotalTime // Nuevo parámetro
       );
    }

    _levels = await DatabaseService().getLevels();
    notifyListeners();
  }
  
  Future<void> _unlockNextLevel(int nextLevel) async {
    await DatabaseService().unlockLevel(nextLevel);
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       await FirestoreService().unlockLevel(user.uid, nextLevel);
    }
    _levels = await DatabaseService().getLevels();
    notifyListeners();
  }
}
