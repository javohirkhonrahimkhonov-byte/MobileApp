class Student {
  final int id;
  final String fullName;
  final String hemisLogin;
  final String? groupNumber;
  final String? specialtyName;
  final String? facultyName;
  final String? semesterName;
  final String? imageUrl;
  final int missedHours;

  Student({
    required this.id,
    required this.fullName,
    required this.hemisLogin,
    this.groupNumber,
    this.specialtyName,
    this.facultyName,
    this.semesterName,
    this.imageUrl,
    this.missedHours = 0,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      fullName: json['full_name'],
      hemisLogin: json['hemis_login'],
      groupNumber: json['group_number'],
      specialtyName: json['specialty_name'],
      facultyName: json['faculty_name'],
      semesterName: json['semester_name'],
      imageUrl: json['image_url'],
      missedHours: json['missed_hours'] ?? 0,
    );
  }
}
