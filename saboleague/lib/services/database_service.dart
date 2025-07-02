import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/team.dart';
import '../models/player.dart';

/// Service qui gère la base de données locale SQLite
/// Permet de stocker et récupérer les équipes et joueurs favoris
class DatabaseService {
    /// Instance unique du service (Singleton)
    static final DatabaseService _instance = DatabaseService._internal();
    static Database? _database;

    /// Constructeur factory qui retourne l'instance unique
    factory DatabaseService() => _instance;

    /// Constructeur privé pour le pattern Singleton
    DatabaseService._internal();

    /// Getter pour accéder à la base de données
    /// Initialise la base si elle n'existe pas
    Future<Database> get database async {
        if (_database != null) return _database!;
        _database = await _initDatabase();
        return _database!;
    }

    /// Initialise la base de données
    /// Crée le fichier de base de données s'il n'existe pas
    Future<Database> _initDatabase() async {
        final path = join(await getDatabasesPath(), 'football_favorites.db');
        return await openDatabase(
            path,
            version: 1,
            onCreate: _onCreate,
        );
    }

    /// Crée les tables nécessaires dans la base de données
    /// [db] : Instance de la base de données
    /// [version] : Version de la base de données
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
                birthDate TEXT,
                nationality TEXT,
                photo TEXT,
                teamId INTEGER,
                teamName TEXT
            )
        ''');
    }

    /// Insère une équipe dans la base de données
    /// [team] : L'équipe à insérer
    Future<void> insertTeam(Team team) async {
        final db = await database;
        await db.insert(
            'teams',
            team.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
    }

    /// Insère un joueur dans la base de données
    /// [player] : Le joueur à insérer
    Future<void> insertPlayer(Player player) async {
        final db = await database;
        await db.insert(
            'players',
            player.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
    }

    /// Récupère toutes les équipes favorites
    /// Retourne une liste d'objets Team
    Future<List<Team>> getFavoriteTeams() async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query('teams');
        return List.generate(maps.length, (i) => Team.fromMap(maps[i]));
    }

    /// Récupère tous les joueurs favoris
    /// Retourne une liste d'objets Player
    Future<List<Player>> getFavoritePlayers() async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query('players');
        return List.generate(
            maps.length,
            (i) => Player.fromJson(maps[i], maps[i]['teamId'], maps[i]['teamName']),
        );
    }

    /// Supprime une équipe des favoris
    /// [id] : L'ID de l'équipe à supprimer
    Future<void> removeTeam(int id) async {
        final db = await database;
        await db.delete(
            'teams',
            where: 'id = ?',
            whereArgs: [id],
        );
    }

    /// Supprime un joueur des favoris
    /// [id] : L'ID du joueur à supprimer
    Future<void> removePlayer(int id) async {
        final db = await database;
        await db.delete(
            'players',
            where: 'id = ?',
            whereArgs: [id],
        );
    }
}
