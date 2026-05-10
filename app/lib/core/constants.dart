class ApiConstants {
  static const String baseUrl =
      'https://centro-productividad-iot-production.up.railway.app';
  static const String wsUrl =
      'wss://centro-productividad-iot-production.up.railway.app/ws';
  static const String profiles = '/api/profiles';
  static const String activeProfile = '/api/profiles/active';
  static String activateProfile(int id) => '/api/profiles/$id/activate';
  static String calibrateProfile(int id) => '/api/profiles/$id/calibrate';
}
