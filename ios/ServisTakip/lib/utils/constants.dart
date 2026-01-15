class AppConstants {
  // API Configuration - Android emulator için 10.0.2.2 (host localhost)
  static const String apiBaseUrl = 'http://10.0.2.2:5000/api';
  static const String apiTimeout = '30'; // seconds
  
  // Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  
  
  // SignalR
  static const String signalRHubUrl = 'http://10.0.2.2:5000/hubs/location';
  
  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';
  static const String keyFcmToken = 'fcm_token';
  
  // App Info
  static const String appName = 'Servis Takip';
  static const String appVersion = '1.0.0';
  
  // Defaults
  static const int defaultServiceCapacity = 20;
  static const double defaultMapZoom = 15.0;
  static const double defaultLocationUpdateInterval = 10.0; // seconds
  
  // Colors (Theme'de kullanılacak)
  static const int primaryColor = 0xFF2196F3;
  static const int accentColor = 0xFF4CAF50;
  static const int errorColor = 0xFFF44336;
  static const int warningColor = 0xFFFF9800;
  static const int successColor = 0xFF4CAF50;
}
