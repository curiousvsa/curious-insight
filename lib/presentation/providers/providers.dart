import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/services.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';
import '../../data/database/database_helper.dart';
import '../../data/datasources/platform/platform_channels.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../domain/entities/entities.dart';

// ================================================================
// THEME PROVIDER
// ================================================================

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.kThemeMode);
    if (stored == 'light') {
      state = ThemeMode.light;
    } else if (stored == 'system') {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.dark;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kThemeMode, mode.name);
  }
}

// ================================================================
// ANALYTICS PROVIDERS
// ================================================================

final selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final selectedPeriodProvider = StateProvider<AnalyticsPeriod>(
  (ref) => AnalyticsPeriod.week,
);

enum AnalyticsPeriod { day, week, month, year }

final dailyAnalyticsProvider =
    FutureProvider.family<DailyAnalytics, DateTime>((ref, date) async {
  return AnalyticsRepository.instance.getDailyAnalytics(date);
});

final weeklyAnalyticsProvider =
    FutureProvider.family<WeeklyAnalytics, DateTime>((ref, weekStart) async {
  return AnalyticsRepository.instance.getWeeklyAnalytics(weekStart);
});

final monthlyAnalyticsProvider =
    FutureProvider.family<MonthlyAnalytics, ({int year, int month})>(
  (ref, params) async {
    return AnalyticsRepository.instance.getMonthlyAnalytics(
      params.year,
      params.month,
    );
  },
);

/// Current week analytics — most commonly used
final currentWeekAnalyticsProvider = FutureProvider<WeeklyAnalytics>((ref) {
  final now = DateTime.now();
  final weekStart =
      now.subtract(Duration(days: now.weekday - 1));
  final monday = DateTime(weekStart.year, weekStart.month, weekStart.day);
  return AnalyticsRepository.instance.getWeeklyAnalytics(monday);
});

/// Today's analytics
final todayAnalyticsProvider = FutureProvider<DailyAnalytics>((ref) {
  return AnalyticsRepository.instance.getDailyAnalytics(DateTime.now());
});

// ================================================================
// SMS PROVIDER
// ================================================================

final smsIngestProvider = StateNotifierProvider<SmsIngestNotifier, SmsIngestState>(
  (ref) => SmsIngestNotifier(),
);

class SmsIngestState {
  const SmsIngestState({
    this.isLoading = false,
    this.processedCount = 0,
    this.error,
  });

  final bool isLoading;
  final int processedCount;
  final String? error;

  SmsIngestState copyWith({
    bool? isLoading,
    int? processedCount,
    String? error,
  }) =>
      SmsIngestState(
        isLoading: isLoading ?? this.isLoading,
        processedCount: processedCount ?? this.processedCount,
        error: error ?? this.error,
      );
}

class SmsIngestNotifier extends StateNotifier<SmsIngestState> {
  SmsIngestNotifier() : super(const SmsIngestState());

  final _channel = SmsPlatformChannel.instance;
  final _db = DatabaseHelper.instance;

  Future<void> ingestHistorical() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final smsList = await _channel.fetchHistoricalSms();
      await _db.insertSmsBatch(smsList);
      state = state.copyWith(
        isLoading: false,
        processedCount: smsList.length,
      );
      AppLogger.info('Ingested ${smsList.length} historical SMS');
    } catch (e, st) {
      AppLogger.error('SMS ingest failed', e, st);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startRealtime() {
    _channel.startListening();
    _channel.incomingSmsStream.listen((sms) async {
      await _db.insertSms(sms);
      state = state.copyWith(processedCount: state.processedCount + 1);
    });
  }
}

// ================================================================
// NOTIFICATION PROVIDER
// ================================================================

final notifIngestProvider =
    StateNotifierProvider<NotifIngestNotifier, NotifIngestState>(
  (ref) => NotifIngestNotifier(),
);

class NotifIngestState {
  const NotifIngestState({
    this.listenerEnabled = false,
    this.processedCount = 0,
  });

  final bool listenerEnabled;
  final int processedCount;
}

class NotifIngestNotifier extends StateNotifier<NotifIngestState> {
  NotifIngestNotifier() : super(const NotifIngestState()) {
    _checkListener();
  }

  final _channel = NotificationPlatformChannel.instance;
  final _db = DatabaseHelper.instance;

  Future<void> _checkListener() async {
    final enabled = await _channel.checkListenerEnabled();
    state = NotifIngestState(listenerEnabled: enabled);
    if (enabled) startListening();
  }

  void startListening() {
    _channel.startListening();
    _channel.notificationStream.listen((notif) async {
      await _db.insertNotification(notif);
      state = NotifIngestState(
        listenerEnabled: true,
        processedCount: state.processedCount + 1,
      );
    });
  }

  Future<void> openSettings() =>
      _channel.openNotificationListenerSettings();
}

// ================================================================
// EXPORT PROVIDER
// ================================================================

enum ExportStatus { idle, generating, ready, error }

class ExportState {
  const ExportState({
    this.status = ExportStatus.idle,
    this.filePath,
    this.error,
    this.progress = 0.0,
    this.statusMessage = '',
  });

  final ExportStatus status;
  final String? filePath;
  final String? error;
  final double progress;
  final String statusMessage;

  ExportState copyWith({
    ExportStatus? status,
    String? filePath,
    String? error,
    double? progress,
    String? statusMessage,
  }) =>
      ExportState(
        status: status ?? this.status,
        filePath: filePath ?? this.filePath,
        error: error ?? this.error,
        progress: progress ?? this.progress,
        statusMessage: statusMessage ?? this.statusMessage,
      );
}

final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>(
  (ref) => ExportNotifier(ref),
);

class ExportNotifier extends StateNotifier<ExportState> {
  ExportNotifier(this._ref) : super(const ExportState());

  final Ref _ref;

  Future<void> generateReport({
    required AnalyticsPeriod period,
    required List<String> sections,
  }) async {
    state = const ExportState(
      status: ExportStatus.generating,
      progress: 0.05,
      statusMessage: 'Loading your data...',
    );

    try {
      // Load data
      state = state.copyWith(progress: 0.2, statusMessage: 'Processing transactions...');
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monday = DateTime(weekStart.year, weekStart.month, weekStart.day);

      WeeklyAnalytics? weekly;
      List<DailyAnalytics> daily = [];

      if (period == AnalyticsPeriod.week) {
        weekly = await AnalyticsRepository.instance.getWeeklyAnalytics(monday);
        daily = weekly.dailyBreakdown;
      } else {
        final d = await AnalyticsRepository.instance.getDailyAnalytics(now);
        daily = [d];
      }

      state = state.copyWith(progress: 0.5, statusMessage: 'Building charts...');

      // Generate PDF
      state = state.copyWith(progress: 0.7, statusMessage: 'Generating PDF...');

      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(AppConstants.kUserName) ?? 'User';

      final file = await PdfExportService.instance.generateReport(
        userName: userName,
        period: period,
        dailyData: daily,
        weeklyData: weekly,
        sections: sections,
      );

      state = state.copyWith(progress: 1.0, statusMessage: 'Done!');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      state = ExportState(
        status: ExportStatus.ready,
        filePath: file.path,
        progress: 1.0,
      );
    } catch (e, st) {
      AppLogger.error('PDF export failed', e, st);
      state = ExportState(
        status: ExportStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const ExportState();
}

// ================================================================
// SETTINGS PROVIDER
// ================================================================

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsState {
  const SettingsState({
    this.retentionDays = AppConstants.kDefaultRetentionDays,
    this.userName = '',
  });

  final int retentionDays;
  final String userName;

  SettingsState copyWith({int? retentionDays, String? userName}) =>
      SettingsState(
        retentionDays: retentionDays ?? this.retentionDays,
        userName: userName ?? this.userName,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      retentionDays: prefs.getInt(AppConstants.kDataRetentionDays) ??
          AppConstants.kDefaultRetentionDays,
      userName: prefs.getString(AppConstants.kUserName) ?? '',
    );
  }

  Future<void> setRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.kDataRetentionDays, days);
    state = state.copyWith(retentionDays: days);
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kUserName, name);
    state = state.copyWith(userName: name);
  }

  Future<void> deleteAllData() async {
    await DatabaseHelper.instance.deleteAllData();
    AppLogger.info('User data wiped from Settings');
  }
}
