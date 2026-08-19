import 'dart:convert';
import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/models/alert.dart';
import 'package:airsentine1/models/heatmap_point.dart';
import 'package:airsentine1/models/personal_telemetry.dart';
import 'package:airsentine1/models/reading.dart';
import 'package:airsentine1/models/station.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static final LocalDb instance = LocalDb._internal();
  static Database? _database;

  LocalDb._internal();

  factory LocalDb() => instance;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database?> _initDb() async {
    if (kIsWeb) return null;
    try {
      final dbPath = await getDatabasesPath();
      final pathStr = join(dbPath, 'airsentine1_local.db');

      return await openDatabase(
        pathStr,
        version: 1,
        onCreate: _createTables,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // 1. local_readings
    await db.execute('''
      CREATE TABLE local_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT,
        aqi INTEGER,
        pm25 REAL,
        humidity REAL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        recorded_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 2. local_community_reports
    await db.execute('''
      CREATE TABLE local_community_reports (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        site_id TEXT,
        lat REAL,
        lng REAL,
        note TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 3. cached_sites
    await db.execute('''
      CREATE TABLE cached_sites (
        id TEXT PRIMARY KEY,
        name TEXT,
        lat REAL,
        lng REAL,
        official_device_id TEXT,
        status TEXT,
        last_aqi INTEGER,
        updated_at TEXT
      )
    ''');

    // 4. cached_heatmap
    await db.execute('''
      CREATE TABLE cached_heatmap (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        aqi REAL NOT NULL,
        weight REAL NOT NULL,
        fetched_at TEXT
      )
    ''');

    // 5. received_alerts
    await db.execute('''
      CREATE TABLE received_alerts (
        id TEXT PRIMARY KEY,
        site_id TEXT,
        type TEXT,
        severity INTEGER,
        evidence_json TEXT,
        received_at TEXT
      )
    ''');
  }

  // --- CRUD METHODS ---

  /// Insert a reading into local_readings
  Future<int> insertLocalReading(Reading reading, {bool isSynced = false}) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      'local_readings',
      {
        if (reading.deviceId != null) 'device_id': reading.deviceId,
        if (reading.aqi != null) 'aqi': reading.aqi,
        if (reading.pm25 != null) 'pm25': reading.pm25,
        if (reading.humidity != null) 'humidity': reading.humidity,
        'lat': reading.lat,
        'lng': reading.lng,
        'recorded_at': (reading.recordedAt ?? DateTime.now()).toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Query all un-synced readings
  Future<List<Map<String, dynamic>>> getUnsyncedReadingsData() async {
    final db = await database;
    if (db == null) return [];
    return await db.query(
      'local_readings',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );
  }

  /// Get list of un-synced Reading objects
  Future<List<Reading>> getUnsyncedReadings() async {
    final rows = await getUnsyncedReadingsData();
    return rows.map((row) {
      return Reading(
        id: row['id'] as int?,
        deviceId: row['device_id'] as String?,
        aqi: row['aqi'] as int?,
        pm25: (row['pm25'] as num?)?.toDouble(),
        humidity: (row['humidity'] as num?)?.toDouble(),
        lat: (row['lat'] as num).toDouble(),
        lng: (row['lng'] as num).toDouble(),
        recordedAt: row['recorded_at'] != null ? DateTime.parse(row['recorded_at'] as String) : null,
      );
    }).toList();
  }

  /// Mark readings as synced by IDs
  Future<void> markReadingsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    if (db == null) return;
    final idListStr = ids.join(',');
    await db.rawUpdate(
      'UPDATE local_readings SET is_synced = 1 WHERE id IN ($idListStr)',
    );
  }

  /// Count un-synced readings
  Future<int> getPendingSyncCount() async {
    final db = await database;
    if (db == null) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM local_readings WHERE is_synced = 0',
    );
    if (result.isNotEmpty) {
      return Sqflite.firstIntValue(result) ?? 0;
    }
    return 0;
  }

  /// Cache heatmap points
  Future<void> saveCachedHeatmap(List<HeatmapPoint> points) async {
    final db = await database;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('cached_heatmap');
      final nowStr = DateTime.now().toIso8601String();
      for (final p in points) {
        await txn.insert('cached_heatmap', {
          'lat': p.lat,
          'lng': p.lng,
          'aqi': p.aqi,
          'weight': p.weight,
          'fetched_at': nowStr,
        });
      }
    });
  }

  /// Retrieve cached heatmap points
  Future<List<HeatmapPoint>> getCachedHeatmap() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('cached_heatmap');
    return rows.map((row) => HeatmapPoint.fromJson(row)).toList();
  }

  /// Cache sites
  Future<void> saveCachedSites(List<MonitoringStation> stationsList) async {
    final db = await database;
    if (db == null) return;
    await db.transaction((txn) async {
      final nowStr = DateTime.now().toIso8601String();
      for (final s in stationsList) {
        await txn.insert(
          'cached_sites',
          {
            'id': s.id,
            'name': s.name,
            'lat': s.location.latitude,
            'lng': s.location.longitude,
            'last_aqi': s.aqi,
            'updated_at': nowStr,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Retrieve cached monitoring stations
  Future<List<MonitoringStation>> getCachedSites() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('cached_sites');
    if (rows.isEmpty) return [];

    final cachedList = <MonitoringStation>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final name = row['name'] as String? ?? id;
      final lastAqi = row['last_aqi'] as int? ?? 100;
      final orig = stations.firstWhere(
        (s) => s.id == id,
        orElse: () => stations.first,
      );

      cachedList.add(
        MonitoringStation(
          id: id,
          name: name,
          area: orig.area,
          aqi: lastAqi,
          primaryPollutant: orig.primaryPollutant,
          summary: orig.summary,
          weather: orig.weather,
          pollutants: orig.pollutants,
          forecast: orig.forecast,
          history: orig.history,
          advice: orig.advice,
          location: orig.location,
          isOutdoor: orig.isOutdoor,
        ),
      );
    }
    return cachedList;
  }

  /// Insert received alert into local SQLite DB
  Future<void> insertReceivedAlert(AppAlert alert) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'received_alerts',
      {
        'id': alert.id,
        'site_id': alert.siteId,
        'type': alert.type,
        'severity': alert.severity,
        'evidence_json': alert.evidence != null ? jsonEncode(alert.evidence) : null,
        'received_at': (alert.receivedAt ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 6. personal_telemetry
  Future<void> _createPersonalTelemetryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS personal_telemetry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        device_id TEXT,
        device_name TEXT,
        aqi INTEGER,
        pm25 REAL,
        pm10 REAL,
        temperature REAL,
        humidity REAL,
        heart_rate INTEGER,
        lat REAL,
        lng REAL,
        timestamp TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  /// Query received alerts for site from local DB
  Future<List<AppAlert>> getReceivedAlertsForSite(String? siteId) async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> rows;
    if (siteId != null) {
      rows = await db.query(
        'received_alerts',
        where: 'site_id = ?',
        whereArgs: [siteId],
        orderBy: 'received_at DESC',
      );
    } else {
      rows = await db.query(
        'received_alerts',
        orderBy: 'received_at DESC',
      );
    }

    return rows.map((row) {
      Map<String, dynamic>? evidence;
      if (row['evidence_json'] != null) {
        try {
          evidence = jsonDecode(row['evidence_json'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }

      return AppAlert(
        id: row['id'] as String,
        siteId: row['site_id'] as String?,
        type: row['type'] as String?,
        severity: row['severity'] as int?,
        evidence: evidence,
        receivedAt: row['received_at'] != null ? DateTime.parse(row['received_at'] as String) : null,
      );
    }).toList();
  }

  // --- PERSONAL TELEMETRY METHODS ---

  Future<int> insertPersonalTelemetry(PersonalTelemetry telemetry) async {
    final db = await database;
    if (db == null) return 0;
    await _createPersonalTelemetryTable(db);
    return await db.insert(
      'personal_telemetry',
      telemetry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PersonalTelemetry>> getUnsyncedPersonalTelemetry() async {
    final db = await database;
    if (db == null) return [];
    await _createPersonalTelemetryTable(db);
    final rows = await db.query(
      'personal_telemetry',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );
    return rows.map((r) => PersonalTelemetry.fromJson(r)).toList();
  }

  Future<void> markPersonalTelemetrySynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    if (db == null) return;
    final idListStr = ids.join(',');
    await db.rawUpdate(
      'UPDATE personal_telemetry SET is_synced = 1 WHERE id IN ($idListStr)',
    );
  }

  Future<List<PersonalTelemetry>> getPersonalTelemetryHistory({int limit = 50}) async {
    final db = await database;
    if (db == null) return [];
    await _createPersonalTelemetryTable(db);
    final rows = await db.query(
      'personal_telemetry',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map((r) => PersonalTelemetry.fromJson(r)).toList();
  }
}
