import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert_model.dart';
import '../models/sensor_activity.dart';
import '../models/actuator_activity.dart';
import '../models/scheduled_task.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aquagrow.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        sensor_id TEXT NOT NULL,
        sensor_value REAL NOT NULL,
        unit TEXT NOT NULL,
        severity INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        is_acknowledged INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Sensor activities table
    await db.execute('''
      CREATE TABLE sensor_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_id TEXT NOT NULL,
        sensor_name TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Actuator activities table
    await db.execute('''
      CREATE TABLE actuator_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuator_id TEXT NOT NULL,
        actuator_name TEXT NOT NULL,
        is_on INTEGER NOT NULL,
        action_type INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        duration_seconds INTEGER
      )
    ''');

    // Scheduled tasks table
    await db.execute('''
      CREATE TABLE scheduled_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuator_id TEXT NOT NULL,
        actuator_name TEXT NOT NULL,
        schedule_type TEXT NOT NULL,
        interval_minutes INTEGER,
        start_time TEXT,
        end_time TEXT,
        duration_minutes INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        days_of_week TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute(
        'CREATE INDEX idx_alerts_timestamp ON alerts(timestamp DESC)');
    await db.execute(
        'CREATE INDEX idx_alerts_severity ON alerts(severity)');
    await db.execute(
        'CREATE INDEX idx_sensor_activities_timestamp ON sensor_activities(timestamp DESC)');
    await db.execute(
        'CREATE INDEX idx_actuator_activities_timestamp ON actuator_activities(timestamp DESC)');
  }

  // ============== ALERTS ==============

  Future<int> insertAlert(AlertModel alert) async {
    final db = await database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<AlertModel>> getAlerts({
    int limit = 50,
    AlertSeverity? severity,
    bool? acknowledged,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (severity != null) {
      whereClause = 'severity = ?';
      whereArgs.add(severity.index);
    }

    if (acknowledged != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_acknowledged = ?';
      whereArgs.add(acknowledged ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => AlertModel.fromMap(map)).toList();
  }

  Future<int> getUnacknowledgedAlertCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM alerts WHERE is_acknowledged = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> acknowledgeAlert(int id) async {
    final db = await database;
    return await db.update(
      'alerts',
      {'is_acknowledged': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> acknowledgeAllAlerts() async {
    final db = await database;
    return await db.update(
      'alerts',
      {'is_acknowledged': 1},
      where: 'is_acknowledged = 0',
    );
  }

  Future<int> deleteAlert(int id) async {
    final db = await database;
    return await db.delete('alerts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOldAlerts(int daysOld) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;
    return await db.delete(
      'alerts',
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );
  }

  // ============== SENSOR ACTIVITIES ==============

  Future<int> insertSensorActivity(SensorActivity activity) async {
    final db = await database;
    return await db.insert('sensor_activities', activity.toMap());
  }

  Future<List<SensorActivity>> getSensorActivities({
    String? sensorId,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (sensorId != null) {
      whereClause = 'sensor_id = ?';
      whereArgs.add(sensorId);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_activities',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => SensorActivity.fromMap(map)).toList();
  }

  Future<Map<String, double>> getSensorStats(
      String sensorId, int hoursBack) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(hours: hoursBack))
        .millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT 
        MIN(value) as min_val,
        MAX(value) as max_val,
        AVG(value) as avg_val
      FROM sensor_activities 
      WHERE sensor_id = ? AND timestamp >= ?
    ''', [sensorId, cutoff]);

    if (result.isNotEmpty && result.first['avg_val'] != null) {
      return {
        'min': result.first['min_val'] as double,
        'max': result.first['max_val'] as double,
        'avg': result.first['avg_val'] as double,
      };
    }
    return {'min': 0, 'max': 0, 'avg': 0};
  }

  // ============== ACTUATOR ACTIVITIES ==============

  Future<int> insertActuatorActivity(ActuatorActivity activity) async {
    final db = await database;
    return await db.insert('actuator_activities', activity.toMap());
  }

  Future<List<ActuatorActivity>> getActuatorActivities({
    String? actuatorId,
    int limit = 50,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'actuator_activities',
      where: actuatorId != null ? 'actuator_id = ?' : null,
      whereArgs: actuatorId != null ? [actuatorId] : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => ActuatorActivity.fromMap(map)).toList();
  }

  // ============== SCHEDULED TASKS ==============

  Future<int> insertScheduledTask(ScheduledTask task) async {
    final db = await database;
    return await db.insert('scheduled_tasks', task.toMap());
  }

  Future<List<ScheduledTask>> getScheduledTasks({
    String? actuatorId,
    bool? enabled,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (actuatorId != null) {
      whereClause = 'actuator_id = ?';
      whereArgs.add(actuatorId);
    }

    if (enabled != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_enabled = ?';
      whereArgs.add(enabled ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_tasks',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => ScheduledTask.fromMap(map)).toList();
  }

  Future<int> updateScheduledTask(ScheduledTask task) async {
    final db = await database;
    return await db.update(
      'scheduled_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> toggleScheduledTask(int id, bool enabled) async {
    final db = await database;
    return await db.update(
      'scheduled_tasks',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteScheduledTask(int id) async {
    final db = await database;
    return await db.delete('scheduled_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ============== UTILITY ==============

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('alerts');
    await db.delete('sensor_activities');
    await db.delete('actuator_activities');
    await db.delete('scheduled_tasks');
  }
}
