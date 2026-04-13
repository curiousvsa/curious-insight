// ============================================================
// lib/data/datasources/platform/sms_platform_channel.dart
// ============================================================
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/classifiers.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/entities.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/classifiers.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/entities.dart';

class SmsPlatformChannel {
  SmsPlatformChannel._();

  static final SmsPlatformChannel instance = SmsPlatformChannel._();

  static const _channel = MethodChannel(AppConstants.kSmsChannel);
  static const _eventChannel = EventChannel(AppConstants.kSmsEventChannel);

  StreamSubscription<dynamic>? _subscription;
  final StreamController<SmsEntity> _smsController =
      StreamController<SmsEntity>.broadcast();

  Stream<SmsEntity> get incomingSmsStream => _smsController.stream;

  /// Fetch historical SMS from device (Android only).
  Future<List<SmsEntity>> fetchHistoricalSms({
    int limit = AppConstants.kSmsHistoryLimit,
  }) async {
    try {
      final List<dynamic> raw =
          await _channel.invokeMethod('fetchSms', {'limit': limit});
      AppLogger.info('Fetched ${raw.length} historical SMS');
      return raw
          .map((e) => _parseRaw(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PlatformException catch (e) {
      AppLogger.error('SMS fetch failed', e);
      return [];
    }
  }

  /// Start listening to new incoming SMS.
  void startListening() {
    _subscription ??= _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          final sms = _parseRaw(Map<String, dynamic>.from(event as Map));
          _smsController.add(sms);
        } catch (e) {
          AppLogger.warning('Failed to parse incoming SMS event', e);
        }
      },
      onError: (dynamic error) {
        AppLogger.error('SMS event stream error', error);
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _smsController.close();
  }

  SmsEntity _parseRaw(Map<String, dynamic> raw) {
    final content = (raw['body'] as String?) ?? '';
    final sender = (raw['address'] as String?) ?? 'Unknown';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (raw['date'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );

    final amount = AmountParser.parse(content);
    final category = CategoryClassifier.classifySms(sender, content);
    final txnType = CategoryClassifier.classifyTransaction(content);
    final entityName = CategoryClassifier.extractEntityName(sender, content);

    return SmsEntity(
      id: const Uuid().v5(Uuid.NAMESPACE_URL, '${sender}_$content'),
      content: content,
      sender: sender,
      amount: amount,
      entityName: entityName,
      category: category,
      transactionType: txnType,
      timestamp: timestamp,
    );
  }
}

// ============================================================
// lib/data/datasources/platform/notification_platform_channel.dart
// ============================================================


class NotificationPlatformChannel {
  NotificationPlatformChannel._();

  static final NotificationPlatformChannel instance =
      NotificationPlatformChannel._();

  static const _channel = MethodChannel(AppConstants.kNotifChannel);
  static const _eventChannel = EventChannel(AppConstants.kNotifEventChannel);

  StreamSubscription<dynamic>? _subscription;
  final StreamController<NotificationEntity> _notifController =
      StreamController<NotificationEntity>.broadcast();

  Stream<NotificationEntity> get notificationStream => _notifController.stream;

  Future<bool> checkListenerEnabled() async {
    try {
      final bool enabled =
          await _channel.invokeMethod('isNotificationListenerEnabled');
      return enabled;
    } on PlatformException catch (e) {
      AppLogger.error('Notification listener check failed', e);
      return false;
    }
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException catch (e) {
      AppLogger.error('Cannot open notification settings', e);
    }
  }

  void startListening() {
    _subscription ??= _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          final notif =
              _parseRaw(Map<String, dynamic>.from(event as Map));
          _notifController.add(notif);
        } catch (e) {
          AppLogger.warning('Failed to parse notification event', e);
        }
      },
      onError: (dynamic error) {
        AppLogger.error('Notification event stream error', error);
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _notifController.close();
  }

  NotificationEntity _parseRaw(Map<String, dynamic> raw) {
    final packageName = (raw['package_name'] as String?) ?? '';
    final appName = (raw['app_name'] as String?) ?? packageName;
    final content = (raw['text'] as String?) ?? '';
    final title = raw['title'] as String?;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (raw['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );

    final category = CategoryClassifier.classifyNotification(
      packageName,
      content,
    );
    final priority = CategoryClassifier.classifyNotifPriority(
      category,
      content,
    );

    return NotificationEntity(
      id: const Uuid().v5(
        Uuid.NAMESPACE_URL,
        '$packageName${timestamp.millisecondsSinceEpoch}',
      ),
      appName: appName,
      packageName: packageName,
      content: content,
      title: title,
      category: category,
      priority: priority,
      interactionState: InteractionState.ignored,
      timestamp: timestamp,
    );
  }
}
