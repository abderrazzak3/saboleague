import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/team.dart';
import '../models/player.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'football_favorites.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teams(
        id INTEGER PRIMARY KEY,
        name TEXT,
        shortName TEXT,
        logo TEXT,
        country TEXT,
        founded INTEGER,
        venue TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE players(
        id INTEGER PRIMARY KEY,
        name TEXT,
        position TEXT,
        birthDate TEXT,    -- ajout colonne birthDate
        nationality TEXT,
        photo TEXT,
        teamId INTEGER,
        teamName TEXT      -- ajout colonne teamName
      )
    ''');
  }

  Future<void> insertTeam(Team team) async {
    final db = await database;
    await db.insert(
      'teams',
      team.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertPlayer(Player player) async {
    final db = await database;
    await db.insert(
      'players',
      player.toMap(),  // birthDate et teamName inclus dans toMap()
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Team>> getFavoriteTeams() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('teams');
    return List.generate(maps.length, (i) => Team.fromMap(maps[i]));
  }


  Future<List<Player>> getFavoritePlayers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('players');
    return List.generate(
      maps.length,
          (i) => Player.fromJson(maps[i], maps[i]['teamId'], maps[i]['teamName']),
    );
  }

  Future<void> removeTeam(int id) async {
    final db = await database;
    await db.delete(
      'teams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removePlayer(int id) async {
    final db = await database;
    await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
