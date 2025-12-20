import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_reading.dart';
import '../models/alert.dart';
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
    String path = join(await getDatabasesPath(), 'hydroponic.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sensor_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_id TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        status TEXT NOT NULL,
        min_value REAL NOT NULL,
        max_value REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE alerts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_id TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        acknowledged INTEGER NOT NULL DEFAULT 0,
        acknowledged_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE actuator_activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuator_id TEXT NOT NULL,
        action TEXT NOT NULL,
        value REAL,
        mode TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        user_id TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE scheduled_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_name TEXT NOT NULL,
        actuator_id TEXT NOT NULL,
        action TEXT NOT NULL,
        value REAL,
        schedule_type TEXT NOT NULL,
        schedule_time TEXT,
        week_days TEXT,
        scheduled_date INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        last_executed INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_sensor_readings_timestamp ON sensor_readings(timestamp)');
    await db.execute('CREATE INDEX idx_sensor_readings_sensor_id ON sensor_readings(sensor_id)');
    await db.execute('CREATE INDEX idx_alerts_timestamp ON alerts(timestamp)');
    await db.execute('CREATE INDEX idx_alerts_acknowledged ON alerts(acknowledged)');
    await db.execute('CREATE INDEX idx_actuator_activities_timestamp ON actuator_activities(timestamp)');
  }

  // Sensor Readings Operations
  Future<int> insertSensorReading(SensorReading reading) async {
    final db = await database;
    return await db.insert(
      'sensor_readings',
      {
        'sensor_id': reading.id,
        'value': reading.value,
        'unit': reading.unit,
        'status': reading.status,
        'min_value': reading.min,
        'max_value': reading.max,
        'timestamp': reading.timestamp.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SensorReading?> getLatestSensorReading(String sensorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      where: 'sensor_id = ?',
      whereArgs: [sensorId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return SensorReading(
      id: map['sensor_id'] as String,
      value: map['value'] as double,
      unit: map['unit'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: map['status'] as String,
      min: map['min_value'] as double,
      max: map['max_value'] as double,
    );
  }

  Future<List<SensorReading>> getSensorReadings(
    String sensorId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String where = 'sensor_id = ?';
    List<dynamic> whereArgs = [sensorId];

    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => SensorReading(
          id: map['sensor_id'] as String,
          value: map['value'] as double,
          unit: map['unit'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
          status: map['status'] as String,
          min: map['min_value'] as double,
          max: map['max_value'] as double,
        )).toList();
  }

  Future<int> deleteOldSensorReadings(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return await db.delete(
      'sensor_readings',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  // Alerts Operations
  Future<int> insertAlert(Alert alert) async {
    final db = await database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<Alert>> getAllAlerts({bool? unacknowledgedOnly, int? limit}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (unacknowledgedOnly == true) {
      where = 'acknowledged = ?';
      whereArgs = [0];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => Alert.fromMap(map)).toList();
  }

  Future<List<Alert>> getAlertsBySeverity(String severity) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'severity = ?',
      whereArgs: [severity],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => Alert.fromMap(map)).toList();
  }

  Future<int> acknowledgeAlert(int alertId) async {
    final db = await database;
    return await db.update(
      'alerts',
      {
        'acknowledged': 1,
        'acknowledged_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  Future<int> deleteOldAlerts(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return await db.delete(
      'alerts',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  // Actuator Activities Operations
  Future<int> insertActuatorActivity(ActuatorActivity activity) async {
    final db = await database;
    return await db.insert('actuator_activities', activity.toMap());
  }

  Future<List<ActuatorActivity>> getAllActuatorActivities({
    String? actuatorId,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (actuatorId != null) {
      where = 'actuator_id = ?';
      whereArgs = [actuatorId];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'actuator_activities',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => ActuatorActivity.fromMap(map)).toList();
  }

  Future<List<ActuatorActivity>> getActuatorActivitiesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'actuator_activities',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ActuatorActivity.fromMap(map)).toList();
  }

  // Scheduled Tasks Operations
  Future<int> insertScheduledTask(ScheduledTask task) async {
    final db = await database;
    return await db.insert('scheduled_tasks', task.toMap());
  }

  Future<List<ScheduledTask>> getAllScheduledTasks({bool? activeOnly}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (activeOnly == true) {
      where = 'is_active = ?';
      whereArgs = [1];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_tasks',
      where: where,
      whereArgs: whereArgs,
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

  Future<int> deleteScheduledTask(int taskId) async {
    final db = await database;
    return await db.delete(
      'scheduled_tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> markTaskExecuted(int taskId) async {
    final db = await database;
    return await db.update(
      'scheduled_tasks',
      {'last_executed': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}






