// ============================================================
// lib/domain/entities/sms_entity.dart
// ============================================================
import 'package:equatable/equatable.dart';

enum SmsCategory {
  spending,
  banking,
  otp,
  promotions,
  work,
  social,
  important,
  system,
  unknown,
}

enum TransactionType { debit, credit, otp, promo, unknown }

class SmsEntity extends Equatable {
  const SmsEntity({
    required this.id,
    required this.content,
    required this.sender,
    required this.category,
    required this.transactionType,
    required this.timestamp,
    this.amount,
    this.entityName,
    this.isRead = false,
  });

  final String id;
  final String content;
  final String sender;
  final double? amount;
  final String? entityName;
  final SmsCategory category;
  final TransactionType transactionType;
  final DateTime timestamp;
  final bool isRead;

  SmsEntity copyWith({
    String? id,
    String? content,
    String? sender,
    double? amount,
    String? entityName,
    SmsCategory? category,
    TransactionType? transactionType,
    DateTime? timestamp,
    bool? isRead,
  }) =>
      SmsEntity(
        id: id ?? this.id,
        content: content ?? this.content,
        sender: sender ?? this.sender,
        amount: amount ?? this.amount,
        entityName: entityName ?? this.entityName,
        category: category ?? this.category,
        transactionType: transactionType ?? this.transactionType,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
      );

  @override
  List<Object?> get props => [
        id,
        content,
        sender,
        amount,
        entityName,
        category,
        transactionType,
        timestamp,
        isRead,
      ];
}

// ============================================================
// lib/domain/entities/notification_entity.dart
// ============================================================

enum NotificationCategory {
  message,
  promotion,
  transaction,
  alert,
  social,
  work,
  system,
  unknown,
}

enum NotificationPriority { high, medium, low }

enum InteractionState { opened, dismissed, ignored }

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.content,
    required this.category,
    required this.priority,
    required this.interactionState,
    required this.timestamp,
    this.title,
  });

  final String id;
  final String appName;
  final String packageName;
  final String content;
  final String? title;
  final NotificationCategory category;
  final NotificationPriority priority;
  final InteractionState interactionState;
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, appName, packageName, content, timestamp];
}

// ============================================================
// lib/domain/entities/analytics_entity.dart
// ============================================================

class SpendByCategory extends Equatable {
  const SpendByCategory({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  final SmsCategory category;
  final double amount;
  final double percentage;
  final int transactionCount;

  @override
  List<Object?> get props => [category, amount];
}

class AppNotificationStats extends Equatable {
  const AppNotificationStats({
    required this.appName,
    required this.packageName,
    required this.count,
    required this.percentage,
    required this.openedCount,
  });

  final String appName;
  final String packageName;
  final int count;
  final double percentage;
  final int openedCount;

  @override
  List<Object?> get props => [appName, count];
}

class DailySpend extends Equatable {
  const DailySpend({
    required this.date,
    required this.amount,
  });

  final DateTime date;
  final double amount;

  @override
  List<Object?> get props => [date, amount];
}

class DailyAnalytics extends Equatable {
  const DailyAnalytics({
    required this.date,
    required this.totalSpend,
    required this.totalCredit,
    required this.spendByCategory,
    required this.totalNotifications,
    required this.notificationsByApp,
    required this.notificationsByCategory,
    required this.ignoredNotifications,
    required this.openedNotifications,
    required this.interactionRate,
    required this.peakHours,
    required this.transactions,
    required this.aiInsights,
  });

  final DateTime date;
  final double totalSpend;
  final double totalCredit;
  final List<SpendByCategory> spendByCategory;
  final int totalNotifications;
  final List<AppNotificationStats> notificationsByApp;
  final Map<NotificationCategory, int> notificationsByCategory;
  final int ignoredNotifications;
  final int openedNotifications;
  final double interactionRate;
  final List<int> peakHours;
  final List<SmsEntity> transactions;
  final List<String> aiInsights;

  @override
  List<Object?> get props => [date];
}

class WeeklyAnalytics extends Equatable {
  const WeeklyAnalytics({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpend,
    required this.previousWeekSpend,
    required this.spendDeltaPercent,
    required this.spendByCategory,
    required this.totalNotifications,
    required this.topApps,
    required this.dailySpend,
    required this.dailyBreakdown,
    required this.behavioralInsights,
    required this.recommendations,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalSpend;
  final double previousWeekSpend;
  final double spendDeltaPercent;
  final List<SpendByCategory> spendByCategory;
  final int totalNotifications;
  final List<AppNotificationStats> topApps;
  final List<DailySpend> dailySpend;
  final List<DailyAnalytics> dailyBreakdown;
  final List<String> behavioralInsights;
  final List<String> recommendations;

  @override
  List<Object?> get props => [weekStart, weekEnd];
}

class MonthlyAnalytics extends Equatable {
  const MonthlyAnalytics({
    required this.year,
    required this.month,
    required this.totalSpend,
    required this.previousMonthSpend,
    required this.spendDeltaPercent,
    required this.spendByCategory,
    required this.totalNotifications,
    required this.weeklySpend,
    required this.topApps,
    required this.aiInsights,
  });

  final int year;
  final int month;
  final double totalSpend;
  final double previousMonthSpend;
  final double spendDeltaPercent;
  final List<SpendByCategory> spendByCategory;
  final int totalNotifications;
  final List<DailySpend> weeklySpend;
  final List<AppNotificationStats> topApps;
  final List<String> aiInsights;

  @override
  List<Object?> get props => [year, month];
}
