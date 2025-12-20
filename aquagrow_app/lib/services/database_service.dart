import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert_model.dart';
import '../models/sensor_activity.dart';
import '../models/actuator_activity.dart';
import '../models/scheduled_task.dart';
import '../models/resource_item.dart';
import '../models/emergency_contact.dart';
import '../models/network_device.dart';
import '../models/emergency_message.dart';

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

    // Resources table (BEACON)
    await db.execute('''
      CREATE TABLE resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider_id TEXT NOT NULL,
        provider_name TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        location TEXT,
        timestamp INTEGER NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        contact_info TEXT
      )
    ''');

    // Emergency contacts table (BEACON)
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        email TEXT,
        relationship TEXT NOT NULL,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Network devices table (BEACON)
    await db.execute('''
      CREATE TABLE network_devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL UNIQUE,
        device_name TEXT NOT NULL,
        endpoint_id TEXT,
        last_seen INTEGER NOT NULL,
        is_connected INTEGER NOT NULL DEFAULT 0,
        signal_strength INTEGER,
        metadata TEXT
      )
    ''');

    // Emergency messages table (BEACON)
    await db.execute('''
      CREATE TABLE emergency_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        recipient_id TEXT,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        metadata TEXT
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

  // ============== RESOURCES (BEACON) ==============

  Future<int> insertResource(ResourceItem resource) async {
    final db = await database;
    return await db.insert('resources', resource.toMap());
  }

  Future<List<ResourceItem>> getAllResources({bool? availableOnly}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'resources',
      where: availableOnly == true ? 'is_available = ?' : null,
      whereArgs: availableOnly == true ? [1] : null,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ResourceItem.fromMap(map)).toList();
  }

  Future<ResourceItem?> getResource(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'resources',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ResourceItem.fromMap(maps.first);
  }

  Future<int> updateResource(ResourceItem resource) async {
    final db = await database;
    return await db.update(
      'resources',
      resource.toMap(),
      where: 'id = ?',
      whereArgs: [resource.id],
    );
  }

  Future<int> deleteResource(int id) async {
    final db = await database;
    return await db.delete('resources', where: 'id = ?', whereArgs: [id]);
  }

  // ============== EMERGENCY CONTACTS (BEACON) ==============

  Future<int> insertEmergencyContact(EmergencyContact contact) async {
    final db = await database;
    return await db.insert('emergency_contacts', contact.toMap());
  }

  Future<List<EmergencyContact>> getAllEmergencyContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_contacts',
      orderBy: 'is_primary DESC, created_at DESC',
    );

    return maps.map((map) => EmergencyContact.fromMap(map)).toList();
  }

  Future<EmergencyContact?> getEmergencyContact(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_contacts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return EmergencyContact.fromMap(maps.first);
  }

  Future<int> updateEmergencyContact(EmergencyContact contact) async {
    final db = await database;
    return await db.update(
      'emergency_contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteEmergencyContact(int id) async {
    final db = await database;
    return await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ============== NETWORK DEVICES (BEACON) ==============

  Future<int> insertNetworkDevice(NetworkDevice device) async {
    final db = await database;
    return await db.insert(
      'network_devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NetworkDevice>> getAllNetworkDevices({bool? connectedOnly}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'network_devices',
      where: connectedOnly == true ? 'is_connected = ?' : null,
      whereArgs: connectedOnly == true ? [1] : null,
      orderBy: 'last_seen DESC',
    );

    return maps.map((map) => NetworkDevice.fromMap(map)).toList();
  }

  Future<int> updateNetworkDevice(NetworkDevice device) async {
    final db = await database;
    return await db.update(
      'network_devices',
      device.toMap(),
      where: 'device_id = ?',
      whereArgs: [device.deviceId],
    );
  }

  Future<int> deleteOldNetworkDevices(int daysOld) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;
    return await db.delete(
      'network_devices',
      where: 'last_seen < ?',
      whereArgs: [cutoff],
    );
  }

  // ============== EMERGENCY MESSAGES (BEACON) ==============

  Future<int> insertEmergencyMessage(EmergencyMessage message) async {
    final db = await database;
    return await db.insert('emergency_messages', message.toMap());
  }

  Future<List<EmergencyMessage>> getEmergencyMessages({
    String? senderId,
    String? recipientId,
    bool? unreadOnly,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (senderId != null) {
      where = 'sender_id = ?';
      whereArgs = [senderId];
    }
    if (recipientId != null) {
      if (where != null) {
        where += ' AND recipient_id = ?';
        whereArgs!.add(recipientId);
      } else {
        where = 'recipient_id = ?';
        whereArgs = [recipientId];
      }
    }
    if (unreadOnly == true) {
      if (where != null) {
        where += ' AND is_read = ?';
        whereArgs!.add(0);
      } else {
        where = 'is_read = ?';
        whereArgs = [0];
      }
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_messages',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => EmergencyMessage.fromMap(map)).toList();
  }

  Future<int> markMessageAsRead(int messageId) async {
    final db = await database;
    return await db.update(
      'emergency_messages',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<int> deleteOldMessages(int daysOld) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;
    return await db.delete(
      'emergency_messages',
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );
  }

  // ============== UTILITY ==============

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('alerts');
    await db.delete('sensor_activities');
    await db.delete('actuator_activities');
    await db.delete('scheduled_tasks');
    await db.delete('resources');
    await db.delete('emergency_contacts');
    await db.delete('network_devices');
    await db.delete('emergency_messages');
  }
}
