import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  /// Get or generate a unique device ID
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString(_deviceIdKey);

    if (storedDeviceId != null) {
      _cachedDeviceId = storedDeviceId;
      return storedDeviceId;
    }

    // Generate new device ID
    String deviceId = await _generateDeviceId();
    await prefs.setString(_deviceIdKey, deviceId);
    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// Generate a unique device ID based on device info
  static Future<String> _generateDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.model}_${androidInfo.id}_${androidInfo.fingerprint}'.hashCode.abs().toString();
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = '${iosInfo.model}_${iosInfo.identifierForVendor}_${iosInfo.systemVersion}'.hashCode.abs().toString();
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceId = '${windowsInfo.computerName}_${windowsInfo.userName}_${windowsInfo.systemMemoryInMegabytes}'.hashCode.abs().toString();
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        deviceId = '${linuxInfo.name}_${linuxInfo.id}_${linuxInfo.machineId}'.hashCode.abs().toString();
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
        deviceId = '${macInfo.model}_${macInfo.systemGUID}_${macInfo.kernelVersion}'.hashCode.abs().toString();
      } else {
        // Fallback for web or other platforms
        deviceId = _generateRandomId();
      }

      return 'device_$deviceId';
    } catch (e) {
      // Fallback to random ID if device info fails
      return 'device_${_generateRandomId()}';
    }
  }

  /// Generate a random ID as fallback
  static String _generateRandomId() {
    final random = Random();
    return List.generate(16, (index) => random.nextInt(16).toRadixString(16)).join();
  }

  /// Clear stored device ID (for testing purposes)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    _cachedDeviceId = null;
  }
}