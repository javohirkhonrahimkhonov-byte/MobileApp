class ApiConstants {
  // Replace with your server IP or domain
  // For Emulator: 10.0.2.2
  // For Physical Device: Your LAN IP (e.g., 192.168.1.5)
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; 
  
  static const String authInit = '$baseUrl/auth/init';
  static const String authCheck = '$baseUrl/auth/check';
  
  static const String profile = '$baseUrl/student/me';
  static const String dashboard = '$baseUrl/student/dashboard';
  
  static const String activities = '$baseUrl/student/activities';
  static const String clubsMy = '$baseUrl/student/clubs/my';
  static const String clubsAll = '$baseUrl/student/clubs/all';
  
  static const String feedback = '$baseUrl/student/feedback';
  static const String documents = '$baseUrl/student/documents';
}
