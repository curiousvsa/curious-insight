import '../../core/utils/logger.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database_helper.dart';
import '../../domain/entities/entities.dart';

/// Analytics repository — aggregates raw SMS/notification data
/// into structured daily, weekly, and monthly analytics objects.
class AnalyticsRepository {
  AnalyticsRepository._();

  static final AnalyticsRepository instance = AnalyticsRepository._();

  final _db = DatabaseHelper.instance;

  // ----------------------------------------------------------------
  // DAILY
  // ----------------------------------------------------------------

  Future<DailyAnalytics> getDailyAnalytics(DateTime date) async {
    final from = AppDateUtils.startOfDay(date);
    final to = AppDateUtils.endOfDay(date);

    AppLogger.debug('Computing daily analytics for ${AppDateUtils.formatDate(date)}');

    final transactions = await _db.getSmsInRange(from, to);
    final spend = await _db.getTotalSpendInRange(from, to);
    final credit = await _db.getTotalCreditInRange(from, to);
    final spendByCat = await _db.getSpendByCategoryInRange(from, to);
    final notifCount = await _db.getNotifCount(from, to);
    final notifByApp = await _db.getNotifCountByApp(from, to);
    final engagement = await _db.getEngagementStats(from, to);
    final hourlyDist = await _db.getHourlyNotifDistribution(from, to);

    final opened = engagement['opened'] ?? 0;
    final dismissed = engagement['dismissed'] ?? 0;
    final ignored = engagement['ignored'] ?? 0;
    final totalEngaged = opened + dismissed + ignored;
    final interactionRate = totalEngaged > 0 ? opened / totalEngaged : 0.0;

    // Peak hours = top 3 hours with most notifications
    final hourPairs = hourlyDist.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHours = hourPairs
        .where((e) => e.value > 0)
        .take(3)
        .map((e) => e.key)
        .toList()
      ..sort();

    // Build spend by category list
    final totalSpendForPct = spendByCat.values.fold(0.0, (a, b) => a + b);
    final spendByCategory = spendByCat.entries.map((e) {
      final cat = SmsCategory.values.firstWhere(
        (c) => c.name == e.key,
        orElse: () => SmsCategory.unknown,
      );
      final count = transactions
          .where((t) => t.category == cat && t.transactionType == TransactionType.debit)
          .length;
      return SpendByCategory(
        category: cat,
        amount: e.value,
        percentage: totalSpendForPct > 0 ? e.value / totalSpendForPct * 100 : 0,
        transactionCount: count,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Build app notification stats
    final notifTotal = notifByApp.values.fold(0, (a, b) => a + b);
    final notifByAppStats = notifByApp.entries.map((e) {
      return AppNotificationStats(
        appName: e.key,
        packageName: e.key.toLowerCase().replaceAll(' ', '.'),
        count: e.value,
        percentage: notifTotal > 0 ? e.value / notifTotal * 100 : 0,
        openedCount: 0,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final insights = _generateDailyInsights(
      spend: spend,
      spendByCategory: spendByCat,
      notifCount: notifCount,
      peakHours: peakHours,
      interactionRate: interactionRate,
    );

    return DailyAnalytics(
      date: date,
      totalSpend: spend,
      totalCredit: credit,
      spendByCategory: spendByCategory,
      totalNotifications: notifCount,
      notificationsByApp: notifByAppStats,
      notificationsByCategory: const {},
      ignoredNotifications: ignored,
      openedNotifications: opened,
      interactionRate: interactionRate,
      peakHours: peakHours,
      transactions: transactions,
      aiInsights: insights,
    );
  }

  // ----------------------------------------------------------------
  // WEEKLY
  // ----------------------------------------------------------------

  Future<WeeklyAnalytics> getWeeklyAnalytics(DateTime weekStart) async {
    final from = AppDateUtils.startOfDay(weekStart);
    final to = AppDateUtils.endOfDay(
      weekStart.add(const Duration(days: 6)),
    );
    final prevFrom = from.subtract(const Duration(days: 7));
    final prevTo = to.subtract(const Duration(days: 7));

    AppLogger.debug(
      'Computing weekly analytics: '
      '${AppDateUtils.formatDate(from)} – ${AppDateUtils.formatDate(to)}',
    );

    final totalSpend = await _db.getTotalSpendInRange(from, to);
    final prevSpend = await _db.getTotalSpendInRange(prevFrom, prevTo);
    final delta = prevSpend > 0
        ? ((totalSpend - prevSpend) / prevSpend * 100)
        : 0.0;

    final spendByCat = await _db.getSpendByCategoryInRange(from, to);
    final notifCount = await _db.getNotifCount(from, to);
    final notifByApp = await _db.getNotifCountByApp(from, to);

    // Build daily breakdowns for the week
    final days = AppDateUtils.daysInRange(from, to);
    final dailyBreakdown = <DailyAnalytics>[];
    final dailySpend = <DailySpend>[];

    for (final day in days) {
      final analytics = await getDailyAnalytics(day);
      dailyBreakdown.add(analytics);
      dailySpend.add(DailySpend(date: day, amount: analytics.totalSpend));
    }

    // Build spend by category
    final totalForPct = spendByCat.values.fold(0.0, (a, b) => a + b);
    final spendByCategory = spendByCat.entries.map((e) {
      final cat = SmsCategory.values.firstWhere(
        (c) => c.name == e.key,
        orElse: () => SmsCategory.unknown,
      );
      return SpendByCategory(
        category: cat,
        amount: e.value,
        percentage: totalForPct > 0 ? e.value / totalForPct * 100 : 0,
        transactionCount: 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Top apps
    final appTotal = notifByApp.values.fold(0, (a, b) => a + b);
    final topApps = notifByApp.entries.take(5).map((e) {
      return AppNotificationStats(
        appName: e.key,
        packageName: e.key.toLowerCase(),
        count: e.value,
        percentage: appTotal > 0 ? e.value / appTotal * 100 : 0,
        openedCount: 0,
      );
    }).toList();

    final insights = _generateWeeklyInsights(
      totalSpend: totalSpend,
      delta: delta,
      spendByCat: spendByCat,
      dailySpend: dailySpend,
    );

    return WeeklyAnalytics(
      weekStart: from,
      weekEnd: to,
      totalSpend: totalSpend,
      previousWeekSpend: prevSpend,
      spendDeltaPercent: delta,
      spendByCategory: spendByCategory,
      totalNotifications: notifCount,
      topApps: topApps,
      dailySpend: dailySpend,
      dailyBreakdown: dailyBreakdown,
      behavioralInsights: insights,
      recommendations: _generateRecommendations(spendByCat, delta),
    );
  }

  // ----------------------------------------------------------------
  // MONTHLY
  // ----------------------------------------------------------------

  Future<MonthlyAnalytics> getMonthlyAnalytics(int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));
    final prevFrom = DateTime(year, month - 1, 1);
    final prevTo = DateTime(year, month, 1).subtract(const Duration(seconds: 1));

    final totalSpend = await _db.getTotalSpendInRange(from, to);
    final prevSpend = await _db.getTotalSpendInRange(prevFrom, prevTo);
    final delta = prevSpend > 0
        ? ((totalSpend - prevSpend) / prevSpend * 100)
        : 0.0;

    final spendByCat = await _db.getSpendByCategoryInRange(from, to);
    final notifCount = await _db.getNotifCount(from, to);
    final notifByApp = await _db.getNotifCountByApp(from, to);

    // Weekly spend buckets
    final weeklySpend = <DailySpend>[];
    var weekStart = from;
    while (weekStart.isBefore(to)) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final effectiveEnd = weekEnd.isAfter(to) ? to : weekEnd;
      final ws = await _db.getTotalSpendInRange(weekStart, effectiveEnd);
      weeklySpend.add(DailySpend(date: weekStart, amount: ws));
      weekStart = weekStart.add(const Duration(days: 7));
    }

    final totalForPct = spendByCat.values.fold(0.0, (a, b) => a + b);
    final spendByCategory = spendByCat.entries.map((e) {
      final cat = SmsCategory.values.firstWhere(
        (c) => c.name == e.key,
        orElse: () => SmsCategory.unknown,
      );
      return SpendByCategory(
        category: cat,
        amount: e.value,
        percentage: totalForPct > 0 ? e.value / totalForPct * 100 : 0,
        transactionCount: 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final appTotal = notifByApp.values.fold(0, (a, b) => a + b);
    final topApps = notifByApp.entries.take(5).map((e) {
      return AppNotificationStats(
        appName: e.key,
        packageName: e.key.toLowerCase(),
        count: e.value,
        percentage: appTotal > 0 ? e.value / appTotal * 100 : 0,
        openedCount: 0,
      );
    }).toList();

    return MonthlyAnalytics(
      year: year,
      month: month,
      totalSpend: totalSpend,
      previousMonthSpend: prevSpend,
      spendDeltaPercent: delta,
      spendByCategory: spendByCategory,
      totalNotifications: notifCount,
      weeklySpend: weeklySpend,
      topApps: topApps,
      aiInsights: _generateWeeklyInsights(
        totalSpend: totalSpend,
        delta: delta,
        spendByCat: spendByCat,
        dailySpend: weeklySpend,
      ),
    );
  }

  // ----------------------------------------------------------------
  // INSIGHT GENERATORS
  // ----------------------------------------------------------------

  List<String> _generateDailyInsights({
    required double spend,
    required Map<String, double> spendByCategory,
    required int notifCount,
    required List<int> peakHours,
    required double interactionRate,
  }) {
    final insights = <String>[];

    if (spend > 5000) {
      insights.add(
        'High spending day — ${CurrencyFormatter.format(spend)} total',
      );
    }

    if (spendByCategory.isNotEmpty) {
      final top = spendByCategory.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add(
        'Highest category: ${_catLabel(top.key)} '
        '(${CurrencyFormatter.format(top.value)})',
      );
    }

    if (notifCount > 80) {
      insights.add('Heavy notification day ($notifCount total)');
    }

    if (peakHours.any((h) => h >= 22 || h <= 5)) {
      insights.add('Late-night activity detected');
    }

    if (interactionRate < 0.3 && notifCount > 20) {
      insights.add(
        '${((1 - interactionRate) * 100).toStringAsFixed(0)}% '
        'of notifications were ignored',
      );
    }

    return insights;
  }

  List<String> _generateWeeklyInsights({
    required double totalSpend,
    required double delta,
    required Map<String, double> spendByCat,
    required List<DailySpend> dailySpend,
  }) {
    final insights = <String>[];

    if (delta.abs() > 10) {
      final direction = delta > 0 ? 'up' : 'down';
      insights.add(
        'Spending ${direction} ${delta.abs().toStringAsFixed(1)}% '
        'compared to last week',
      );
    }

    if (spendByCat.isNotEmpty) {
      final top = spendByCat.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add(
        '${_catLabel(top.key)} was your top spend category '
        '(${CurrencyFormatter.format(top.value)})',
      );
    }

    // Highest spend day
    if (dailySpend.isNotEmpty) {
      final peak = dailySpend.reduce((a, b) => a.amount > b.amount ? a : b);
      if (peak.amount > 0) {
        insights.add(
          '${AppDateUtils.formatDayOfWeek(peak.date)} was your '
          'highest spend day (${CurrencyFormatter.format(peak.amount)})',
        );
      }
    }

    return insights;
  }

  List<String> _generateRecommendations(
    Map<String, double> spendByCat,
    double delta,
  ) {
    final recs = <String>[];

    if (delta > 20) {
      recs.add(
        'Your spending has increased significantly. '
        'Consider reviewing your discretionary expenses.',
      );
    }

    final foodSpend = spendByCat['spending'] ?? 0;
    if (foodSpend > 3000) {
      recs.add(
        'Food & dining spend is high. '
        'Cooking at home a few days a week could save significantly.',
      );
    }

    if (spendByCat.length > 4) {
      recs.add(
        'You have diverse spending across many categories. '
        'Consider creating a monthly budget for each.',
      );
    }

    return recs;
  }

  String _catLabel(String catName) {
    switch (catName) {
      case 'spending':
        return 'Food & Shopping';
      case 'banking':
        return 'Banking';
      case 'otp':
        return 'OTP / Auth';
      case 'promotions':
        return 'Promotions';
      case 'work':
        return 'Work';
      case 'social':
        return 'Social';
      case 'important':
        return 'Important';
      default:
        return 'Other';
    }
  }
}

// Inline import to avoid circular dep
class AppDateUtils {
  AppDateUtils._();
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} '
      '${[
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ][d.month - 1]} '
      '${d.year}';
  static String formatDayOfWeek(DateTime d) =>
      ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];

  static List<DateTime> daysInRange(DateTime from, DateTime to) {
    final days = <DateTime>[];
    var current = startOfDay(from);
    while (!current.isAfter(startOfDay(to))) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }
}
