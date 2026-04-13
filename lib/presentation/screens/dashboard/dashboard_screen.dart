import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(currentWeekAnalyticsProvider);
    final todayAsync = ref.watch(todayAnalyticsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverSafeArea(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _DashboardHeader(),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spend hero
                  weeklyAsync.when(
                    data: (weekly) => SpendHeroCard(analytics: weekly),
                    loading: () => const ShimmerPlaceholder(height: 160),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                  ),
                  const SizedBox(height: 12),

                  // Quick stats row
                  weeklyAsync.when(
                    data: (weekly) => _QuickStatsRow(analytics: weekly),
                    loading: () => Row(
                      children: [
                        Expanded(child: ShimmerPlaceholder(height: 80)),
                        const SizedBox(width: 10),
                        Expanded(child: ShimmerPlaceholder(height: 80)),
                        const SizedBox(width: 10),
                        Expanded(child: ShimmerPlaceholder(height: 80)),
                      ],
                    ),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // Category breakdown
                  weeklyAsync.when(
                    data: (weekly) => _CategoryCard(analytics: weekly),
                    loading: () => const ShimmerPlaceholder(height: 200),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // AI Insights
                  weeklyAsync.when(
                    data: (weekly) => _InsightsCard(analytics: weekly),
                    loading: () => const ShimmerPlaceholder(height: 140),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // Recent transactions
                  todayAsync.when(
                    data: (today) => _RecentTransactions(analytics: today),
                    loading: () => const ShimmerPlaceholder(height: 200),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // Export CTA
                  _ExportCta(),

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

// ----------------------------------------------------------------
// Header
// ----------------------------------------------------------------

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppDateUtils.greeting(),
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondaryDark,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'P',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------
// Quick stats row
// ----------------------------------------------------------------

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final engagementPct = analytics.dailyBreakdown.isEmpty
        ? 0.0
        : analytics.dailyBreakdown
                .map((d) => d.interactionRate)
                .reduce((a, b) => a + b) /
            analytics.dailyBreakdown.length *
            100;

    return Row(
      children: [
        Expanded(
          child: _StatMini(
            label: 'Transactions',
            value: analytics.dailyBreakdown
                .expand((d) => d.transactions)
                .length
                .toString(),
            icon: '💳',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMini(
            label: 'Notifications',
            value: analytics.totalNotifications.toString(),
            icon: '🔔',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMini(
            label: 'Engagement',
            value: '${engagementPct.toStringAsFixed(0)}%',
            icon: '📈',
          ),
        ),
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
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

// ----------------------------------------------------------------
// Category breakdown
// ----------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    if (analytics.spendByCategory.isEmpty) return const SizedBox.shrink();

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.spendCategories,
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              _PeriodBadge(label: 'This week'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut
              CategoryDonut(
                categories: analytics.spendByCategory,
                size: 100,
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                child: Column(
                  children: analytics.spendByCategory.take(4).map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _catColor(cat.category),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _catLabel(cat.category),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimaryDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatCompact(cat.amount),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryDark,
                              fontFamily: 'DMmono',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _catColor(SmsCategory cat) {
    switch (cat) {
      case SmsCategory.spending:
        return AppColors.catFood;
      case SmsCategory.banking:
        return AppColors.catBanking;
      case SmsCategory.otp:
        return AppColors.catOtp;
      case SmsCategory.promotions:
        return AppColors.catPromo;
      case SmsCategory.work:
        return AppColors.catWork;
      case SmsCategory.social:
        return AppColors.secondary;
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
      case SmsCategory.promotions:
        return 'Promotions';
      case SmsCategory.work:
        return 'Work';
      default:
        return 'Other';
    }
  }
}

class _PeriodBadge extends StatelessWidget {
  const _PeriodBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ----------------------------------------------------------------
// AI Insights
// ----------------------------------------------------------------

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final insights = [
      ...analytics.behavioralInsights,
      ...analytics.recommendations,
    ];
    if (insights.isEmpty) return const SizedBox.shrink();

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.aiInsights,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          ...insights.take(3).map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InsightChip(text: insight),
                ),
              ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Recent Transactions
// ----------------------------------------------------------------

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.analytics});
  final DailyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final txns = analytics.transactions
        .where((t) => t.amount != null)
        .take(5)
        .toList();

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.recentTransactions,
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.spending),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.seeAll,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
                  (entry) => TransactionListItem(
                    entity: entry.value,
                    showDivider: entry.key < txns.length - 1,
                  ),
                ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Export CTA
// ----------------------------------------------------------------

class _ExportCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.export),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1260), Color(0xFF0B0C16)],
          ),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.downloadReport,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.downloadReportSub,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// Error card
// ----------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load: $message',
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
