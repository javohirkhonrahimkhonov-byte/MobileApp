class Student {
  final int id;
  final String fullName;
  final String hemisLogin;
  final String? universityName;
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
    this.universityName,
    this.imageUrl,
    this.missedHours = 0,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // Helper to get nested name safely
    String? getName(String key) {
      if (json[key] is Map) {
        return json[key]['name']?.toString();
      }
      return null;
    }

    String fullName = "";
    if (json['firstname'] != null) fullName += "${json['firstname']} ";
    if (json['lastname'] != null) fullName += "${json['lastname']}";
    if (fullName.trim().isEmpty) fullName = json['full_name'] ?? "Talaba"; // Fallback for proxy data

    return Student(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: fullName.trim(),
      hemisLogin: json['login'] ?? json['hemis_login'] ?? '',
      groupNumber: getName('group') ?? json['group_number']?.toString(),
      specialtyName: getName('specialty') ?? json['specialty_name']?.toString(),
      facultyName: getName('faculty') ?? json['faculty_name']?.toString(),
      semesterName: getName('semester') ?? json['semester_name']?.toString(),
      universityName: getName('university'),
      imageUrl: json['image'] ?? json['image_url'],
      missedHours: json['missed_hours'] ?? 0,
    );
  }
}
