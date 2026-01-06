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

    // Helper to capitalize first letter
    String camelCase(String text) {
      if (text.isEmpty) return "";
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    String fullName = "";
    // Priority: Raw First/Last from HEMIS
    if (json['lastname'] != null && json['firstname'] != null) {
      fullName = "${camelCase(json['lastname'].toString())} ${camelCase(json['firstname'].toString())}";
    }
    // Fallback: full_name from Proxy or others
    else {
      String raw = json['full_name'] ?? "Talaba";
      // Try to fix ALL CAPS if stuck with raw string
      var parts = raw.split(' ');
      if (parts.length >= 2) {
        fullName = "${camelCase(parts[0])} ${camelCase(parts[1])}";
      } else {
        fullName = camelCase(raw);
      }
    }

    return Student(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: fullName.trim(),
      hemisLogin: json['login'] ?? json['hemis_login'] ?? '',
      groupNumber: getName('group') ?? json['group_number']?.toString(),
      specialtyName: getName('specialty') ?? json['specialty_name']?.toString(),
      facultyName: getName('faculty') ?? json['faculty_name']?.toString(),
      semesterName: getName('semester') ?? json['semester_name']?.toString(),
      universityName: getName('university') ?? "Jizzax davlat pedagogika universiteti", // Full Name Default
      imageUrl: json['image'] ?? json['image_url'],
      missedHours: json['missed_hours'] ?? 0,
    );
  }
}
