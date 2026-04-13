import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/entities.dart';

/// Sqflite database helper — single-instance access pattern.
/// No code generation needed. All queries are hand-written
/// for full control and easy auditing.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    _database ??= await _initDatabase();
    AppLogger.info('Database initialized');
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.kDbName);

    return openDatabase(
      path,
      version: AppConstants.kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Enable WAL mode for better performance
        //await db.execute('PRAGMA journal_mode=WAL');
        await db.rawQuery('PRAGMA journal_mode=WAL');
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys=ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating database tables v$version');

    await db.execute('''
      CREATE TABLE sms_messages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        sender TEXT NOT NULL,
        amount REAL,
        entity_name TEXT,
        category TEXT NOT NULL DEFAULT 'unknown',
        transaction_type TEXT NOT NULL DEFAULT 'unknown',
        timestamp INTEGER NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        app_name TEXT NOT NULL,
        package_name TEXT NOT NULL,
        content TEXT NOT NULL,
        title TEXT,
        category TEXT NOT NULL DEFAULT 'unknown',
        priority TEXT NOT NULL DEFAULT 'low',
        interaction_state TEXT NOT NULL DEFAULT 'ignored',
        timestamp INTEGER NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_metrics_cache (
        date_key TEXT PRIMARY KEY,
        total_spend REAL NOT NULL DEFAULT 0,
        total_credit REAL NOT NULL DEFAULT 0,
        spend_by_category TEXT NOT NULL DEFAULT '{}',
        total_notifications INTEGER NOT NULL DEFAULT 0,
        notifications_by_app TEXT NOT NULL DEFAULT '{}',
        interaction_rate REAL NOT NULL DEFAULT 0,
        peak_hours TEXT NOT NULL DEFAULT '[]',
        insights TEXT NOT NULL DEFAULT '[]',
        updated_at INTEGER NOT NULL
      )
    ''');

    // Indexes for fast queries
    await db.execute(
      'CREATE INDEX idx_sms_timestamp ON sms_messages (timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_sms_category ON sms_messages (category)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_timestamp ON notifications (timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_package ON notifications (package_name)',
    );

    AppLogger.info('Database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading DB from v$oldVersion to v$newVersion');
    // Future migrations go here
  }

  // ----------------------------------------------------------------
  // SMS OPERATIONS
  // ----------------------------------------------------------------

  Future<void> insertSms(SmsEntity sms) async {
    final db = await database;
    await db.insert(
      'sms_messages',
      _smsToMap(sms),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> insertSmsBatch(List<SmsEntity> smsList) async {
    final db = await database;
    final batch = db.batch();
    for (final sms in smsList) {
      batch.insert(
        'sms_messages',
        _smsToMap(sms),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SmsEntity>> getSmsInRange(
    DateTime from,
    DateTime to, {
    int? limit,
    int? offset,
    SmsCategory? category,
    TransactionType? transactionType,
  }) async {
    final db = await database;
    String where = 'timestamp >= ? AND timestamp <= ?';
    final whereArgs = <dynamic>[
      from.millisecondsSinceEpoch,
      to.millisecondsSinceEpoch,
    ];

    if (category != null) {
      where += ' AND category = ?';
      whereArgs.add(category.name);
    }
    if (transactionType != null) {
      where += ' AND transaction_type = ?';
      whereArgs.add(transactionType.name);
    }

    final rows = await db.query(
      'sms_messages',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_smsFromMap).toList();
  }

  Future<double> getTotalSpendInRange(DateTime from, DateTime to) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM sms_messages 
      WHERE timestamp >= ? AND timestamp <= ? 
        AND transaction_type = 'debit'
        AND amount IS NOT NULL
      ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalCreditInRange(DateTime from, DateTime to) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM sms_messages 
      WHERE timestamp >= ? AND timestamp <= ? 
        AND transaction_type = 'credit'
        AND amount IS NOT NULL
      ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getSpendByCategoryInRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT category, COALESCE(SUM(amount), 0) as total
      FROM sms_messages
      WHERE timestamp >= ? AND timestamp <= ?
        AND transaction_type = 'debit'
        AND amount IS NOT NULL
      GROUP BY category
      ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return Map.fromEntries(
      rows.map((r) => MapEntry(
            r['category'] as String,
            (r['total'] as num).toDouble(),
          )),
    );
  }

  // ----------------------------------------------------------------
  // NOTIFICATION OPERATIONS
  // ----------------------------------------------------------------

  Future<void> insertNotification(NotificationEntity notif) async {
    final db = await database;
    await db.insert(
      'notifications',
      _notifToMap(notif),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<NotificationEntity>> getNotificationsInRange(
    DateTime from,
    DateTime to, {
    int? limit,
  }) async {
    final db = await database;
    final rows = await db.query(
      'notifications',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(_notifFromMap).toList();
  }

  Future<Map<String, int>> getNotifCountByApp(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT app_name, COUNT(*) as count
      FROM notifications
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY app_name
      ORDER BY count DESC
      LIMIT 10
      ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return Map.fromEntries(
      rows.map((r) => MapEntry(r['app_name'] as String, r['count'] as int)),
    );
  }

  Future<int> getNotifCount(DateTime from, DateTime to) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM notifications WHERE timestamp >= ? AND timestamp <= ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return result.first['cnt'] as int? ?? 0;
  }

  Future<Map<String, int>> getEngagementStats(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT interaction_state, COUNT(*) as count
      FROM notifications
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY interaction_state
      ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return Map.fromEntries(
      rows.map((r) => MapEntry(
            r['interaction_state'] as String,
            r['count'] as int,
          )),
    );
  }

  /// Returns a list of 24 ints — count per hour
  Future<List<int>> getHourlyNotifDistribution(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT 
        (timestamp / 3600000) % 24 as hour,
        COUNT(*) as count
      FROM notifications
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY hour
      ORDER BY hour ASC
      ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );

    final distribution = List.filled(24, 0);
    for (final row in rows) {
      final hour = (row['hour'] as int?) ?? 0;
      if (hour >= 0 && hour < 24) {
        distribution[hour] = row['count'] as int? ?? 0;
      }
    }
    return distribution;
  }

  // ----------------------------------------------------------------
  // CACHE OPERATIONS
  // ----------------------------------------------------------------

  Future<Map<String, dynamic>?> getCachedMetrics(String dateKey) async {
    final db = await database;
    final rows = await db.query(
      'daily_metrics_cache',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> upsertMetricsCache(
    String dateKey,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    await db.insert(
      'daily_metrics_cache',
      {
        'date_key': dateKey,
        ...data,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ----------------------------------------------------------------
  // MAINTENANCE
  // ----------------------------------------------------------------

  Future<void> deleteOlderThan(DateTime cutoff) async {
    final db = await database;
    final ts = cutoff.millisecondsSinceEpoch;
    await db.delete(
      'sms_messages',
      where: 'timestamp < ?',
      whereArgs: [ts],
    );
    await db.delete(
      'notifications',
      where: 'timestamp < ?',
      whereArgs: [ts],
    );
    AppLogger.info('Deleted data older than ${cutoff.toIso8601String()}');
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('sms_messages');
    await db.delete('notifications');
    await db.delete('daily_metrics_cache');
    AppLogger.info('All user data deleted');
  }

  Future<Map<String, int>> getDataCounts() async {
    final db = await database;
    final smsResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM sms_messages',
    );
    final notifResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM notifications',
    );
    return {
      'sms': smsResult.first['cnt'] as int? ?? 0,
      'notifications': notifResult.first['cnt'] as int? ?? 0,
    };
  }

  // ----------------------------------------------------------------
  // MAPPERS
  // ----------------------------------------------------------------

  Map<String, dynamic> _smsToMap(SmsEntity sms) => {
        'id': sms.id,
        'content': sms.content,
        'sender': sms.sender,
        'amount': sms.amount,
        'entity_name': sms.entityName,
        'category': sms.category.name,
        'transaction_type': sms.transactionType.name,
        'timestamp': sms.timestamp.millisecondsSinceEpoch,
        'is_read': sms.isRead ? 1 : 0,
      };

  SmsEntity _smsFromMap(Map<String, dynamic> map) => SmsEntity(
        id: map['id'] as String,
        content: map['content'] as String,
        sender: map['sender'] as String,
        amount: (map['amount'] as num?)?.toDouble(),
        entityName: map['entity_name'] as String?,
        category: SmsCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => SmsCategory.unknown,
        ),
        transactionType: TransactionType.values.firstWhere(
          (t) => t.name == map['transaction_type'],
          orElse: () => TransactionType.unknown,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        isRead: (map['is_read'] as int?) == 1,
      );

  Map<String, dynamic> _notifToMap(NotificationEntity n) => {
        'id': n.id,
        'app_name': n.appName,
        'package_name': n.packageName,
        'content': n.content,
        'title': n.title,
        'category': n.category.name,
        'priority': n.priority.name,
        'interaction_state': n.interactionState.name,
        'timestamp': n.timestamp.millisecondsSinceEpoch,
      };

  NotificationEntity _notifFromMap(Map<String, dynamic> map) =>
      NotificationEntity(
        id: map['id'] as String,
        appName: map['app_name'] as String,
        packageName: map['package_name'] as String,
        content: map['content'] as String,
        title: map['title'] as String?,
        category: NotificationCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => NotificationCategory.unknown,
        ),
        priority: NotificationPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => NotificationPriority.low,
        ),
        interactionState: InteractionState.values.firstWhere(
          (s) => s.name == map['interaction_state'],
          orElse: () => InteractionState.ignored,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
}
