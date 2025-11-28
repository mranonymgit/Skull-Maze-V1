import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../models/game_config.dart';

class InputDetector {
  static ControlType detectInitialControl(BuildContext context) {
    final isMobileOS = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (kIsWeb) {
      // Detección Web: Simplificado a Teclado si no se usa un detector de dispositivo móvil más avanzado.
      return ControlType.keyboard;
    } else if (isMobileOS) {
      // Por defecto en iOS/Android, iniciamos con Botones Táctiles.
      return ControlType.touchButtons;
    }
    // Windows, macOS, Linux, Web Desktop por defecto
    return ControlType.keyboard;
  }
}