class ApiConstants {
  // JMCU API (Japan Digital University / JMCU)
  static const String baseUrl = 'https://student.jmcu.uz/rest/v1'; 
  
  // Saved Admin/Client Token (Requested by User)
  static const String apiToken = 'LXjqwQE0Xemgq3E7LeB0tn2yMQWY0zXW';

  // Backend API (Talaba Hamkor)
  // FIXED: Using IP directly because Emulator DNS is failing to resolve 'tengdoshbozor.uz'
  static const String backendUrl = 'http://38.242.223.171/api/v1';
  
  // Auth (Proxy via our Bot Backend)
  static const String authLogin = '$backendUrl/auth/hemis';
  
  // Account
  // Account
  // FIXED: Point to our backend to get the enriched profile (with mapped Uni name & First Name)
  static const String profile = '$backendUrl/student/me';
  
  // Dashboard
  static const String dashboard = '$backendUrl/student/dashboard';
  
  // Data
  static const String gpaList = '$baseUrl/data/student-gpa-list';
  static const String taskList = '$baseUrl/data/subject-task-student-list';
  static const String documentList = '$baseUrl/data/student-certificate-list';
  static const String attendanceList = '$baseUrl/education/attendance';
  static const String scheduleList = '$baseUrl/education/schedule';

  // Extended Features (Backend)
  static const String activities = '$backendUrl/student/activities'; 
  static const String clubsMy = '$backendUrl/student/clubs/my';
  static const String feedback = '$backendUrl/student/feedback';
  static const String documents = '$backendUrl/student/documents';
}
