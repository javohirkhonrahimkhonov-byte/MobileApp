import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class LocalDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('talabahamkor.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';

    // 1. Dashboard Cache
    await db.execute('''
      CREATE TABLE dashboard (
        id $idType,
        student_id $intType,
        data $textType,
        updated_at $textType
      )
    ''');

    // 2. Attendance Cache
    await db.execute('''
      CREATE TABLE attendance (
        id $idType,
        student_id $intType,
        semester_code $textType,
        data $textType,
        updated_at $textType
      )
    ''');

    // 3. Subjects Cache
    await db.execute('''
      CREATE TABLE subjects (
        id $idType,
        student_id $intType,
        semester_code $textType,
        data $textType,
        updated_at $textType
      )
    ''');
    
    // 4. Schedule Cache
    await db.execute('''
      CREATE TABLE schedule (
        id $idType,
        student_id $intType,
        semester_code $textType,
        data $textType,
        updated_at $textType
      )
    ''');
    
    // Create indices
    await db.execute('CREATE INDEX idx_dashboard_student ON dashboard (student_id)');
    await db.execute('CREATE INDEX idx_attendance_student ON attendance (student_id, semester_code)');
    await db.execute('CREATE INDEX idx_subjects_student ON subjects (student_id, semester_code)');
    await db.execute('CREATE INDEX idx_schedule_student ON schedule (student_id, semester_code)');
  }

  // --- Helper Methods ---

  Future<void> saveCache(String table, int studentId, Map<String, dynamic> data, {String? semesterCode}) async {
    final db = await database;
    final jsonStr = jsonEncode(data);
    final now = DateTime.now().toIso8601String();

    await db.insert(
      table,
      {
        'student_id': studentId,
        'semester_code': semesterCode ?? 'all',
        'data': jsonStr,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCache(String table, int studentId, {String? semesterCode}) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: 'student_id = ? AND semester_code = ?',
      whereArgs: [studentId, semesterCode ?? 'all'],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['data'] as String) as Map<String, dynamic>;
    }
    return null;
  }
  
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('dashboard');
    await db.delete('attendance');
    await db.delete('subjects');
    await db.delete('schedule');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
