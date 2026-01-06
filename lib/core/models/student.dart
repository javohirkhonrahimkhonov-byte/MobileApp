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
    // Helper to capitalize first letter (Sentence case)
    String sentenceCase(String text) {
      if (text.isEmpty) return "";
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    String fullName = "";
    if (json['lastname'] != null && json['firstname'] != null) {
      fullName = "${sentenceCase(json['lastname'].toString())} ${sentenceCase(json['firstname'].toString())}";
    } else {
      String raw = json['full_name'] ?? "Talaba";
      var parts = raw.split(' ');
      if (parts.length >= 2) {
        fullName = "${sentenceCase(parts[0])} ${sentenceCase(parts[1])}";
      } else {
        fullName = sentenceCase(raw);
      }
    }

    // Helper to extract and prettify
    String? getPrettyName(String key) {
      String? val = getName(key); // getName extracts from map
      if (val != null) return sentenceCase(val);
      // Try direct key fallback
      var direct = json["${key}_name"] ?? json[key];
      if (direct != null) return sentenceCase(direct.toString());
      return null;
    }

    return Student(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: fullName.trim(),
      hemisLogin: json['login'] ?? json['hemis_login'] ?? '',
      groupNumber: (getName('group') != null) 
          ? getName('group')! // Keep group code upper/mixed? Usually "315-21 Axborot..." -> "315-21 axborot..."
          // User said "Bosh xarfi katta". If starts with number, it's tricky.
          // Let's rely on sentenceCase. "315-21 AXBOROT..." -> "315-21 axborot..." (First char is 3).
          // Wait, if first char is number, the rest becomes lowercase?
          // "315-21 AXBOROT".substring(1) -> "15-21 axborot".
          // Result: "315-21 axborot..." -> looks weird if "Axborot" should be cap.
          // But user said "bosh xarfi katta, keyingilari kichkina".
          // I will use sentenceCase.
          : json['group_number']?.toString(),
      specialtyName: getPrettyName('specialty'),
      facultyName: getPrettyName('faculty'),
      semesterName: getPrettyName('semester'),
      universityName: getPrettyName('university') ?? "Jizzax davlat pedagogika universiteti",
      imageUrl: json['image'] ?? json['image_url'],
      missedHours: json['missed_hours'] ?? 0,
    );
  }
}
