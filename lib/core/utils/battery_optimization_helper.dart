import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationHelper {
  /// Check if app is battery optimized
  /// Note: This check is not 100% reliable on all devices.
  /// If granted = true, app is NOT optimized ✅
  /// If granted = false, app MAY BE optimized ⚠️
  static Future<bool> isBatteryOptimized() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      // If permission is granted, battery optimization is DISABLED (good!)
      // If not granted, battery optimization may still be ENABLED (bad!)
      return !status.isGranted;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      // On error, assume it might be optimized to show warning
      return true;
    }
  }

  static Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      // If granted after request, optimization was successfully disabled
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting battery optimization: $e');
      return false;
    }
  }

  static Future<DeviceManufacturer> getManufacturer() async {
    if (!Platform.isAndroid) return DeviceManufacturer.other;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      
      if (manufacturer.contains('xiaomi') || manufacturer.contains('redmi')) {
        return DeviceManufacturer.xiaomi;
      } else if (manufacturer.contains('oppo') || manufacturer.contains('realme')) {
        return DeviceManufacturer.oppo;
      } else if (manufacturer.contains('vivo')) {
        return DeviceManufacturer.vivo;
      } else if (manufacturer.contains('samsung')) {
        return DeviceManufacturer.samsung;
      } else if (manufacturer.contains('huawei') || manufacturer.contains('honor')) {
        return DeviceManufacturer.huawei;
      } else if (manufacturer.contains('oneplus')) {
        return DeviceManufacturer.oneplus;
      }
      
      return DeviceManufacturer.other;
    } catch (e) {
      debugPrint('Error getting manufacturer: $e');
      return DeviceManufacturer.other;
    }
  }

  static String getBatteryOptimizationGuide(DeviceManufacturer manufacturer) {
    switch (manufacturer) {
      case DeviceManufacturer.xiaomi:
        return '''
📱 Panduan Xiaomi/Redmi (MIUI):
1. Buka Settings → Apps → Manage apps
2. Cari "Quran App" → tap
3. Autostart → ON ✅
4. Battery saver → No restrictions ✅
5. Lock app di Recent apps (tekan icon gembok)
        ''';
      
      case DeviceManufacturer.oppo:
        return '''
📱 Panduan OPPO/Realme (ColorOS):
1. Settings → App Management → Quran App
2. Auto-start → ON ✅
3. Battery → Battery usage → Don't optimize ✅
4. Lock app di Recent apps (swipe down → tap gembok)
        ''';
      
      case DeviceManufacturer.vivo:
        return '''
📱 Panduan Vivo (Funtouch OS):
1. Settings → Battery → Background power consumption management
2. Cari "Quran App" → Allow high background battery consumption ✅
3. Settings → More settings → Applications → Autostart
4. Aktifkan Quran App ✅
        ''';
      
      case DeviceManufacturer.samsung:
        return '''
📱 Panduan Samsung (One UI):
1. Settings → Apps → Quran App
2. Battery → Optimize battery usage → OFF ✅
3. Put app to sleep → Remove from list ✅
4. Settings → Device care → Battery → Background usage limits → Never sleeping apps → Add Quran App
        ''';
      
      case DeviceManufacturer.huawei:
        return '''
📱 Panduan Huawei/Honor (EMUI):
1. Settings → Apps → Apps → Quran App
2. Battery → App launch → Manage manually ✅
3. Enable Auto-launch, Secondary launch, Run in background
4. Lock app di Recent apps
        ''';
      
      case DeviceManufacturer.oneplus:
        return '''
📱 Panduan OnePlus (OxygenOS):
1. Settings → Apps → Quran App
2. Battery usage → Don't optimize ✅
3. Settings → Battery → Battery optimization → Advanced optimization → OFF untuk Quran App
4. Lock app di Recent apps
        ''';
      
      case DeviceManufacturer.other:
        return '''
📱 Panduan Umum:
1. Settings → Apps → Quran App → Battery
2. Pilih "Unrestricted" atau "Don't optimize"
3. Jika ada opsi "Auto-start", aktifkan
4. Lock app di Recent apps (jika tersedia)
        ''';
    }
  }
}

enum DeviceManufacturer {
  xiaomi,
  oppo,
  vivo,
  samsung,
  huawei,
  oneplus,
  other,
}
