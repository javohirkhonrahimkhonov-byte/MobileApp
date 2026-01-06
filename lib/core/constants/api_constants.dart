class ApiConstants {
  // Official HEMIS API for JMCU
  static const String baseUrl = 'https://student.jmcu.uz/rest/v1'; 
  
  // Auth
  static const String authLogin = '$baseUrl/auth/login';
  
  // Account
  static const String profile = '$baseUrl/account/me';
  
  // Data
  static const String gpaList = '$baseUrl/data/student-gpa-list';
  static const String taskList = '$baseUrl/data/subject-task-student-list';
  static const String documentList = '$baseUrl/data/student-certificate-list';
}
