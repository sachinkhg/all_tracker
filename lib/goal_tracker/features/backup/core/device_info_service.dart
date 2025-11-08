import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for obtaining device information for backup metadata.
class DeviceInfoService {
  static const String _deviceIdStorageKey = 'backup_device_id';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get a persistent device identifier.
  /// 
  /// The device ID is unique per device and persists across app reinstalls
  /// (until the device is factory reset). It is stored in flutter_secure_storage.
  /// 
  /// Returns a device ID in the format: "platform-xxxx".
  Future<String> getDeviceId() async {
    final existingId = await _secureStorage.read(key: _deviceIdStorageKey);
    if (existingId != null) {
      return existingId;
    }

    // Generate a new device ID based on platform and unique device identifier
    String newId;
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      // Use AndroidId as the base identifier
      newId = 'android-${info.id}';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      // Use identifierForVendor as the base identifier
      newId = 'ios-${info.identifierForVendor ?? 'unknown'}';
    } else {
      // Fallback for other platforms
      newId = 'device-${DateTime.now().millisecondsSinceEpoch}';
    }

    await _secureStorage.write(key: _deviceIdStorageKey, value: newId);
    return newId;
  }

  /// Get a human-readable device description.
  /// 
  /// Returns a string describing the device, e.g., "iPhone 14 Pro" or "Samsung Galaxy S21".
  Future<String> getDeviceDescription() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return '${info.manufacturer} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return '${info.name} (${info.model})';
    } else {
      return 'Unknown Device';
    }
  }
}

