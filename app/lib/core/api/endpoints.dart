class Endpoints {
  // Nota: Cambiar por la URL real de Railway tras el deploy
  static const String baseUrl = 'https://iot-backend-v2.up.railway.app/api';
  static const String wsUrl = 'wss://iot-backend-v2.up.railway.app/ws';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Profiles
  static const String profiles = '/profiles';
  static String activateProfile(int id) => '/profiles/$id/activate';
  static String calibrateStart(int id) => '/profiles/$id/calibrate/start';
  static String calibrateFinish(int id) => '/profiles/$id/calibrate/finish';

  // Sessions
  static const String sessionStart = '/session/start';
  static const String sessionStop = '/session/stop';
  static const String sessionActive = '/session/active';

  // History
  static const String readings = '/readings';
}
