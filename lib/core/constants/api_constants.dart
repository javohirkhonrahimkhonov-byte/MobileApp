class ApiConstants {
  // Official HEMIS API for JMCU
  static const String baseUrl = 'https://student.jmcu.uz/rest/v1'; 

  // Backend API (Talaba Hamkor)
  // Use 10.0.2.2 for Android Emulator to reach localhost
  static const String backendUrl = 'http://10.0.2.2:8000/api/v1';
  
  // Auth
  static const String authLogin = '$baseUrl/auth/login';
  
  // Account
  static const String profile = '$baseUrl/account/me';
  
  // Dashboard
  static const String dashboard = '$backendUrl/student/dashboard';
  
  // Data
  static const String gpaList = '$baseUrl/data/student-gpa-list';
  static const String taskList = '$baseUrl/data/subject-task-student-list';
  static const String documentList = '$baseUrl/data/student-certificate-list';

  // Extended Features (Backend)
  static const String activities = '$backendUrl/activities'; // List or POST
  static const String clubsMy = '$backendUrl/clubs/my';
  static const String feedback = '$backendUrl/feedback';
  static const String documents = '$backendUrl/documents';
}
