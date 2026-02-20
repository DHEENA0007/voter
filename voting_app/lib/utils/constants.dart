/// Application-wide constants
class AppConstants {
  // API Base URL - change this to your server IP/domain
  static const String baseUrl = 'http://localhost:8000/api';
  static const String mediaBaseUrl = 'http://localhost:8000'; // Base for images

  // App Info
  static const String appName = 'Secure Voting';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Vote, Your Voice';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String roleKey = 'user_role';
  static const String voterIdKey = 'voter_id';
  static const String userDataKey = 'user_data';
}
