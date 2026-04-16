import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/landmark.dart';
import '../models/visit_history.dart';
import '../models/pending_visit.dart';

/// Local Database Service using SQLite (sqflite).
/// 3 tables: landmarks (cache), visit_history, pending_visits (offline queue)
class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_landmarks.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table 1: Cached landmarks from API
        await db.execute('''
          CREATE TABLE landmarks (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            image TEXT,
            score REAL NOT NULL,
            visitCount INTEGER DEFAULT 0,
            avgDistance REAL DEFAULT 0.0
          )
        ''');

        // Table 2: Visit history (local)
        await db.execute('''
          CREATE TABLE visit_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            landmarkId INTEGER NOT NULL,
            landmarkName TEXT NOT NULL,
            visitTime INTEGER NOT NULL,
            distance REAL NOT NULL,
            userLat REAL NOT NULL,
            userLon REAL NOT NULL
          )
        ''');

        // Table 3: Pending visits (offline queue)
        await db.execute('''
          CREATE TABLE pending_visits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            landmarkId INTEGER NOT NULL,
            landmarkName TEXT NOT NULL,
            userLat REAL NOT NULL,
            userLon REAL NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ==================== LANDMARKS (Cache) ====================

  Future<void> cacheLandmarks(List<Landmark> landmarks) async {
    final db = await database;
    await db.delete('landmarks'); // Clear old cache
    for (final landmark in landmarks) {
      await db.insert('landmarks', landmark.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Landmark>> getCachedLandmarks() async {
    final db = await database;
    final maps = await db.query('landmarks', orderBy: 'score DESC');
    return maps.map((map) => Landmark.fromMap(map)).toList();
  }

  // ==================== VISIT HISTORY ====================

  Future<void> insertVisitHistory(VisitHistory visit) async {
    final db = await database;
    await db.insert('visit_history', visit.toMap());
  }

  Future<List<VisitHistory>> getVisitHistory() async {
    final db = await database;
    final maps = await db.query('visit_history', orderBy: 'visitTime DESC');
    return maps.map((map) => VisitHistory.fromMap(map)).toList();
  }

  // ==================== PENDING VISITS (Offline Queue) ====================

  Future<void> insertPendingVisit(PendingVisit visit) async {
    final db = await database;
    await db.insert('pending_visits', visit.toMap());
  }

  Future<List<PendingVisit>> getPendingVisits() async {
    final db = await database;
    final maps = await db.query('pending_visits', orderBy: 'timestamp ASC');
    return maps.map((map) => PendingVisit.fromMap(map)).toList();
  }

  Future<void> deletePendingVisit(int id) async {
    final db = await database;
    await db.delete('pending_visits', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingVisitCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_visits');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
