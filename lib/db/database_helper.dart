import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../models/product.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'coordinate_database.db'),
      onCreate: (db, version) async {
        await _createScansTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createScansTable(db);
        }
      },
      version: 2,
    );
  }

  Future<void> _createScansTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT,
        name TEXT,
        eco_grade TEXT,
        eco_score INTEGER,
        nutri_grade TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT
      )
    ''');
  }

  Future<void> insertScan(Product product,
      {double? latitude, double? longitude}) async {
    final db = await database;
    await db.insert('scans', {
      'barcode': product.barcode,
      'name': product.name,
      'eco_grade': product.ecoGrade,
      'eco_score': product.ecoScore,
      'nutri_grade': product.nutriGrade,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getScans() async {
    final db = await database;
    return await db.query('scans');
  }

  Future<void> updateScan(int id, String newName) async {
    final db = await database;
    await db.update(
      'scans',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<GameStats> computeGameStats() async {
    final scanRows = await getScans();
    final scanTimestamps = <DateTime>[];
    var sustainable = 0;
    for (final row in scanRows) {
      final ms = int.tryParse(row['timestamp']?.toString() ?? '');
      if (ms != null) {
        scanTimestamps.add(DateTime.fromMillisecondsSinceEpoch(ms));
      }
      final grade = (row['eco_grade'] ?? '').toString().toLowerCase();
      if (grade == 'a' || grade == 'b') sustainable++;
    }
    final prefs = await SharedPreferences.getInstance();
    final persisted =
        prefs.getStringList('unlocked_badges')?.toSet() ?? <String>{};
    return GameStats.fromScans(
      scanTimestamps,
      sustainableScans: sustainable,
      persistedBadges: persisted,
    );
  }

  Future<Set<String>> awardBadges(GameStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final persisted =
        prefs.getStringList('unlocked_badges')?.toSet() ?? <String>{};
    // drop unknown badge ids
    final clean = stats.badges.intersection(GameStats.badgeLabels.keys.toSet());
    final newly = clean.difference(persisted);
    if (newly.isNotEmpty) {
      await prefs.setStringList('unlocked_badges', clean.toList());
    }
    return newly;
  }
}
