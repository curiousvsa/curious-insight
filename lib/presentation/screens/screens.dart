// ============================================================
// lib/presentation/screens/spending/spending_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/entities.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class SpendingScreen extends ConsumerStatefulWidget {
  const SpendingScreen({super.key});

  @override
  ConsumerState<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends ConsumerState<SpendingScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final weeklyAsync = ref.watch(weeklyAnalyticsProvider(monday));
    final todayAsync = ref.watch(todayAnalyticsProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  AppStrings.spending,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period tabs
                  PeriodTabs(
                    selected: _period,
                    onChanged: (p) => setState(() => _period = p),
                  ),
                  const SizedBox(height: 16),

                  // Spend total hero
                  weeklyAsync.when(
                    data: (w) => _SpendTotalCard(
                      total: w.totalSpend,
                      delta: w.spendDeltaPercent,
                    ),
                    loading: () => const ShimmerPlaceholder(height: 100),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // Bar chart
                  weeklyAsync.when(
                    data: (w) => PulseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.dailyBreakdown,
                            style: AppTypography.h4.copyWith(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BarChartWidget(dailySpend: w.dailySpend),
                        ],
                      ),
                    ),
                    loading: () => const ShimmerPlaceholder(height: 140),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // Top merchants
                  weeklyAsync.when(
                    data: (w) => _TopMerchantsCard(analytics: w),
                    loading: () => const ShimmerPlaceholder(height: 180),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // All transactions
                  todayAsync.when(
                    data: (today) => _TransactionsCard(analytics: today),
                    loading: () => const ShimmerPlaceholder(height: 240),
                    error: (e, _) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendTotalCard extends StatelessWidget {
  const _SpendTotalCard({required this.total, required this.delta});
  final double total;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final isUp = delta >= 0;
    return PulseCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A1260), Color(0xFF12132A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.totalSpendWeek,
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(total),
            style: AppTypography.display.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (isUp ? AppColors.error : AppColors.success)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  CurrencyFormatter.formatDelta(delta),
                  style: AppTypography.caption.copyWith(
                    color: isUp ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.vsLastWeek,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopMerchantsCard extends StatelessWidget {
  const _TopMerchantsCard({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final cats = analytics.spendByCategory;
    if (cats.isEmpty) return const SizedBox.shrink();
    final maxAmount = cats.map((c) => c.amount).reduce((a, b) => a > b ? a : b);

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.topMerchants,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 14),
          ...cats.take(5).map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MerchantRow(
                    category: cat,
                    maxAmount: maxAmount,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.category, required this.maxAmount});
  final SpendByCategory category;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAmount > 0 ? category.amount / maxAmount : 0.0;
    final color = _catColor(category.category);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _catLabel(category.category),
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimaryDark,
              ),
            ),
            Text(
              CurrencyFormatter.format(category.amount),
              style: AppTypography.mono.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.bgDark3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Color _catColor(SmsCategory cat) {
    switch (cat) {
      case SmsCategory.spending:
        return AppColors.chartPink;
      case SmsCategory.banking:
        return AppColors.chartBlue;
      case SmsCategory.otp:
        return AppColors.chartGold;
      case SmsCategory.work:
        return AppColors.chartPurple;
      default:
        return AppColors.catUnknown;
    }
  }

  String _catLabel(SmsCategory cat) {
    switch (cat) {
      case SmsCategory.spending:
        return 'Food & Shopping';
      case SmsCategory.banking:
        return 'Banking';
      case SmsCategory.otp:
        return 'OTP / Auth';
      case SmsCategory.work:
        return 'Work';
      default:
        return 'Other';
    }
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.analytics});
  final DailyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final txns = analytics.transactions
        .where((t) => t.amount != null)
        .toList();

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.allTransactions,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          if (txns.isEmpty)
            const EmptyState(
              emoji: '💸',
              title: AppStrings.noTransactions,
              subtitle: AppStrings.noTransactionsDesc,
              compact: true,
            )
          else
            ...txns.asMap().entries.map(
                  (e) => TransactionListItem(
                    entity: e.value,
                    showDivider: e.key < txns.length - 1,
                  ),
                ),
        ],
      ),
    );
  }
}

// ============================================================
// lib/presentation/screens/notifications/notifications_screen.dart
// ============================================================

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weeklyAsync = ref.watch(weeklyAnalyticsProvider(monday));

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  AppStrings.notifications,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: weeklyAsync.when(
                data: (weekly) => _NotifBody(analytics: weekly),
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerPlaceholder(height: 140),
                    ),
                  ),
                ),
                error: (e, _) => EmptyState(
                  emoji: '⚠️',
                  title: 'Error',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifBody extends StatelessWidget {
  const _NotifBody({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary row
        _EngagementRow(analytics: analytics),
        const SizedBox(height: 12),

        // App distribution
        _AppDistributionCard(analytics: analytics),
        const SizedBox(height: 12),

        // Peak hours heatmap
        _PeakHoursCard(analytics: analytics),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final total = analytics.totalNotifications;
    final avgEngagement = analytics.dailyBreakdown.isEmpty
        ? 0.0
        : analytics.dailyBreakdown
                .map((d) => d.interactionRate)
                .reduce((a, b) => a + b) /
            analytics.dailyBreakdown.length;
    final opened = (total * avgEngagement).round();
    final ignored = total - opened;

    return Row(
      children: [
        Expanded(
          child: _NotifStat(
            label: 'Total',
            value: total.toString(),
            color: AppColors.chartBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NotifStat(
            label: 'Opened',
            value: opened.toString(),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NotifStat(
            label: 'Ignored',
            value: ignored.toString(),
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _NotifStat extends StatelessWidget {
  const _NotifStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.h2.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDistributionCard extends StatelessWidget {
  const _AppDistributionCard({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final apps = analytics.topApps;
    if (apps.isEmpty) return const SizedBox.shrink();

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.appDistribution,
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '${analytics.totalNotifications} total',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...apps.take(5).map(
                (app) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AppRow(app: app),
                ),
              ),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app});
  final AppNotificationStats app;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('📱', style: TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    app.appName,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${app.count} (${app.percentage.toStringAsFixed(1)}%)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: app.percentage / 100,
                  backgroundColor: AppColors.bgDark3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeakHoursCard extends StatelessWidget {
  const _PeakHoursCard({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    // Aggregate hourly data across all days
    final hourly = List.filled(24, 0);
    for (final day in analytics.dailyBreakdown) {
      for (final h in day.peakHours) {
        if (h >= 0 && h < 24) hourly[h]++;
      }
    }
    final maxVal = hourly.isEmpty
        ? 1
        : hourly.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.peakHours,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (i) {
                final frac = hourly[i] / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300 + i * 15),
                            height: frac * 48,
                            decoration: BoxDecoration(
                              color: frac > 0.6
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(
                                      0.2 + frac * 0.5,
                                    ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['12am', '6am', '12pm', '6pm', '11pm']
                .map(
                  (t) => Text(
                    t,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// lib/presentation/screens/settings/settings_screen.dart
// ============================================================

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  AppStrings.settings,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(label: AppStrings.appearance),
                  const SizedBox(height: 8),
                  PulseCard(
                    child: Column(
                      children: [
                        _ToggleRow(
                          title: AppStrings.darkMode,
                          value: themeMode == ThemeMode.dark,
                          onChanged: (v) => ref
                              .read(themeModeProvider.notifier)
                              .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SectionHeader(label: AppStrings.dataPrivacy),
                  const SizedBox(height: 8),
                  PulseCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          title: AppStrings.dataRetention,
                          value: '${settings.retentionDays} days',
                          onTap: () => _showRetentionDialog(context, ref),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          title: AppStrings.exportData,
                          value: 'JSON',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _DangerRow(
                          title: AppStrings.deleteAllData,
                          onTap: () => _confirmDelete(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SectionHeader(label: AppStrings.about),
                  const SizedBox(height: 8),
                  PulseCard(
                    child: Column(
                      children: [
                        _InfoRow(title: AppStrings.version, value: '1.0.0'),
                        const Divider(height: 1),
                        _InfoRow(
                          title: AppStrings.privacyPolicy,
                          value: '→',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          title: AppStrings.termsOfService,
                          value: '→',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'CuriousInSight v1.0.0 · All data processed on-device',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRetentionDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgDark2,
        title: const Text(AppStrings.dataRetention),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [30, 60, 90, 180, 365].map((days) {
            return ListTile(
              title: Text('$days days'),
              onTap: () {
                ref.read(settingsProvider.notifier).setRetentionDays(days);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgDark2,
        title: const Text(AppStrings.deleteAllData),
        content: const Text(AppStrings.deleteAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(settingsProvider.notifier).deleteAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data deleted.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.label.copyWith(color: AppColors.textTertiaryDark),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.body1.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value, this.onTap});
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimaryDark,
              ),
            ),
            Text(
              value,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.body1.copyWith(
                color: AppColors.error,
              ),
            ),
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
