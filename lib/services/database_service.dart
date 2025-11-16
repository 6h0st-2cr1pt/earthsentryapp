import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weather_model.dart';
import '../models/earthquake_model.dart';
import '../models/location_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'geosentry.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Weather cache table
    await db.execute('''
      CREATE TABLE weather_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        temperature REAL,
        humidity REAL,
        wind_speed REAL,
        pressure REAL,
        weather_code TEXT,
        timestamp INTEGER,
        data TEXT
      )
    ''');

    // Earthquake cache table
    await db.execute('''
      CREATE TABLE earthquake_cache (
        id TEXT PRIMARY KEY,
        location_name TEXT,
        magnitude REAL,
        intensity REAL,
        depth REAL,
        latitude REAL,
        longitude REAL,
        time INTEGER,
        tsunami_warning TEXT,
        source TEXT,
        data TEXT
      )
    ''');

    // Favorite locations table
    await db.execute('''
      CREATE TABLE favorite_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        created_at INTEGER
      )
    ''');
  }

  // Weather cache methods
  Future<void> cacheWeather(WeatherModel weather) async {
    final db = await database;
    await db.insert(
      'weather_cache',
      {
        'latitude': weather.latitude,
        'longitude': weather.longitude,
        'location_name': weather.locationName,
        'temperature': weather.temperature,
        'humidity': weather.humidity,
        'wind_speed': weather.windSpeed,
        'pressure': weather.pressure,
        'weather_code': weather.weatherCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedWeather(
    double latitude,
    double longitude,
  ) async {
    final db = await database;
    final result = await db.query(
      'weather_cache',
      where: 'latitude = ? AND longitude = ?',
      whereArgs: [latitude, longitude],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    final timestamp = result.first['timestamp'] as int;
    final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    
    // Cache valid for 30 minutes
    if (cacheAge > 30 * 60 * 1000) {
      return null;
    }

    return result.first as Map<String, dynamic>;
  }

  // Earthquake cache methods
  Future<void> cacheEarthquakes(List<EarthquakeModel> earthquakes) async {
    final db = await database;
    final batch = db.batch();

    for (var eq in earthquakes) {
      batch.insert(
        'earthquake_cache',
        {
          'id': eq.id,
          'location_name': eq.locationName,
          'magnitude': eq.magnitude,
          'intensity': eq.intensity,
          'depth': eq.depth,
          'latitude': eq.latitude,
          'longitude': eq.longitude,
          'time': eq.time.millisecondsSinceEpoch,
          'tsunami_warning': eq.tsunamiWarning,
          'source': eq.source,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedEarthquakes() async {
    final db = await database;
    return await db.query(
      'earthquake_cache',
      orderBy: 'time DESC',
      limit: 100,
    );
  }

  // Favorite locations methods
  Future<void> addFavoriteLocation(LocationModel location) async {
    final db = await database;
    await db.insert(
      'favorite_locations',
      {
        'name': location.name,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getFavoriteLocations() async {
    final db = await database;
    return await db.query(
      'favorite_locations',
      orderBy: 'created_at DESC',
    );
  }

  Future<void> removeFavoriteLocation(int id) async {
    final db = await database;
    await db.delete(
      'favorite_locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

