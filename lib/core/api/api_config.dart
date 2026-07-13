class ApiConfig {
  // Base URL unique pour toutes les requetes API.
  // static const = valeur compilee, accessible sans instance: ApiConfig.baseUrl
  static const baseUrl = 'https://mumoagent-api.onrender.com/api';
  // Timeouts reseau pour eviter les appels qui bloquent trop longtemps.
  // Duration(...) est une classe Dart, pas un int, pour eviter les erreurs d'unite.
  static const connectTimeout = Duration(seconds: 45);
  static const receiveTimeout = Duration(seconds: 45);
}