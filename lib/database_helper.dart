import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fall_detection.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        emergency_contact TEXT NOT NULL,
        address TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Fall events table
    await db.execute('''
      CREATE TABLE fall_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        total_accel REAL NOT NULL,
        total_gyro REAL NOT NULL,
        alarm_triggered INTEGER DEFAULT 0,
        user_responded INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fall event operations
  Future<int> insertFallEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.insert('fall_events', event);
  }

  Future<List<Map<String, dynamic>>> getFallEventsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'fall_events',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> updateFallEvent(int id, Map<String, dynamic> event) async {
    final db = await database;
    return await db.update(
      'fall_events',
      event,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get fall events count for user
  Future<int> getFallEventsCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM fall_events WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int;
  }
  Future<void> updateFallEventAlarm(int fallEventId, {required bool triggered}) async {
    final db = await database;
    await db.update(
      'fall_events',
      {'alarm_triggered': triggered ? 1 : 0},
      where: 'id = ?',
      whereArgs: [fallEventId],
    );
  }

  // Delete all data (for testing)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('fall_events');
    await db.delete('users');
  }
}