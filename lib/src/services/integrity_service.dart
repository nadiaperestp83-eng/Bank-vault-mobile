import 'dart:io';
import 'package:safe_device/safe_device.dart';
import 'package:flutter/foundation.dart';

class IntegrityService {
  /// Checks if the device is secure for financial operations.
  /// This includes checking for Root, Jailbreak, Emulators, and Developer Mode.
  static Future<Map<String, bool>> checkDeviceIntegrity() async {
    // If running in debug mode or on web, we might want to bypass some checks
    if (kDebugMode || kIsWeb) {
      return {
        'isRooted': false,
        'isRealDevice': true,
        'isSafe': true,
        'devMode': false,
      };
    }

    bool isRooted = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;
    bool isDevelopmentMode = await SafeDevice.isDevelopmentModeEnabled;
    
    // Some apps also check for external storage or mock locations
    bool isMockLocation = await SafeDevice.canMockLocation;

    bool isSafe = !isRooted && isRealDevice && !isMockLocation;

    return {
      'isRooted': isRooted,
      'isRealDevice': isRealDevice,
      'devMode': isDevelopmentMode,
      'isMockLocation': isMockLocation,
      'isSafe': isSafe,
    };
  }

  /// Specialized check for non-rooted devices.
  /// Note: Developer options being enabled is SEPARATE from being rooted.
  /// Rooted = System partition compromised (su binary present).
  /// Developer Options = ADB access enabled.
  static Future<bool> isRooted() async {
    return await SafeDevice.isJailBroken;
  }
}
