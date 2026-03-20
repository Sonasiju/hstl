import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Default base URL for production/physical device
  // Change this to your actual server IP or domain
  static const String _productionUrl = 'http://  10.99.169.90:5000';
  static const String _localUrl = 'http://  10.99.169.90:5000';
  static const String _androidEmulatorUrl = 'http://  10.99.169.90:5000';

  /// Returns the appropriate base URL based on the platform and environment
  static String getBaseUrl() {
    if (kIsWeb) {
      return _localUrl; // Web usually uses localhost during dev
    }

    if (kDebugMode) {
      // Android emulator uses 10.0.2.2 to reach host
      // Physical devices need the actual host IP
      if (Platform.isAndroid) {
        // We can't easily detect emulator vs physical device without a package
        // but 10.0.2.2 is the most common for emulator. 
        // If on a physical device, users should use setCustomUrl or update _productionUrl.
        return _androidEmulatorUrl; 
      } else if (Platform.isIOS) {
        return _localUrl; // iOS simulator uses localhost
      }
    }
    
    // Fallback to the host machine's network IP
    return _productionUrl;
  }

  /// Get the base URL with fallback handling
  static String get baseUrl => getBaseUrl();

  /// Change the base URL for testing/debugging
  /// Usage: ApiConfig.setCustomUrl('http://192.168.x.x:5000');
  static String? _customUrl;
  
  static void setCustomUrl(String url) {
    _customUrl = url;
  }

  static void resetCustomUrl() {
    _customUrl = null;
  }

  static String getConfiguredUrl() {
    return _customUrl ?? getBaseUrl();
  }
}
