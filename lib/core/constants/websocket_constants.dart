class WebSocketConstants {
  static const String key = 'yc72xymnrafw0rkakvxp';
  
  // Reverb host and port
  // In development, if using Emulator, 'localhost' should be '10.0.2.2'
  // If using physical device, it should be the computer's IP
  static String get host {
    const fromEnv = String.fromEnvironment('WS_HOST');
    if (fromEnv.isNotEmpty) return fromEnv;
    
    // Default to localhost/emulator IP mapping logic similar to Endpoints
    return 'localhost';
  }

  static const int port = 8080;
  static const String scheme = 'http';
}
