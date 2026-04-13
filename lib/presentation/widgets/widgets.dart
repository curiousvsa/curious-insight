// ============================================================
// lib/presentation/widgets/pulse_card.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

class PulseCard extends StatelessWidget {
  const PulseCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? (isDark ? AppColors.bgDark2 : AppColors.bgLight2)
              : null,
          border: Border.all(
            color: isDark ? AppColors.bgDark4 : const Color(0xFFE0E0F0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

// ============================================================
// lib/presentation/widgets/spend_hero_card.dart
// ============================================================



class SpendHeroCard extends StatelessWidget {
  const SpendHeroCard({super.key, required this.analytics});
  final WeeklyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final isUp = analytics.spendDeltaPercent >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1260), Color(0xFF0B0C16)],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(20),
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
            CurrencyFormatter.format(analytics.totalSpend),
            style: AppTypography.display.copyWith(
              color: Colors.white,
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
                  CurrencyFormatter.formatDelta(analytics.spendDeltaPercent),
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
          const SizedBox(height: 16),

          // Sparkline
          SizedBox(
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: analytics.dailySpend.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.amount,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// lib/presentation/widgets/category_donut.dart
// ============================================================



class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.categories,
    this.size = 100,
  });

  final List<SpendByCategory> categories;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(0, (a, b) => a + b.amount);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.28,
              sections: categories.take(4).map((cat) {
                return PieChartSectionData(
                  value: cat.amount,
                  color: _catColor(cat.category),
                  title: '',
                  radius: size * 0.22,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.formatCompact(total),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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
        return AppColors.chartPink;
      case SmsCategory.banking:
        return AppColors.chartBlue;
      case SmsCategory.otp:
        return AppColors.chartGold;
      case SmsCategory.work:
        return AppColors.chartPurple;
      case SmsCategory.promotions:
        return AppColors.chartGreen;
      default:
        return AppColors.catUnknown;
    }
  }
}

// ============================================================
// lib/presentation/widgets/bar_chart_widget.dart
// ============================================================



class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key, required this.dailySpend});
  final List<DailySpend> dailySpend;

  @override
  Widget build(BuildContext context) {
    if (dailySpend.isEmpty) return const SizedBox(height: 80);

    final maxY = dailySpend.map((d) => d.amount).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 100,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.bgDark3,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = dailySpend[groupIndex];
                return BarTooltipItem(
                  '${AppDateUtils.formatDayOfWeek(day.date)}\n'
                  '${CurrencyFormatter.formatCompact(rod.toY)}',
                  AppTypography.caption.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dailySpend.length) {
                    return Text(
                      AppDateUtils.formatDayOfWeek(dailySpend[index].date),
                      style: AppTypography.label.copyWith(
                        color: AppColors.textTertiaryDark,
                        fontSize: 9,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.bgDark4,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailySpend.asMap().entries.map((e) {
            final isMax = e.value.amount == maxY;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.amount,
                  color: isMax
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.45),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================
// lib/presentation/widgets/transaction_list_item.dart
// ============================================================



class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.entity,
    this.showDivider = true,
  });

  final SmsEntity entity;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isCredit = entity.transactionType == TransactionType.credit;
    final amountColor = isCredit ? AppColors.success : AppColors.error;
    final amountSign = isCredit ? '+' : '−';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _catColor(entity.category).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _catEmoji(entity.category),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.entityName ?? entity.sender,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      AppDateUtils.relativeDate(entity.timestamp),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount + category
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountSign${CurrencyFormatter.format(entity.amount!)}',
                    style: AppTypography.body2.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMmono',
                    ),
                  ),
                  _CategoryPill(category: entity.category),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.bgDark4,
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
      default:
        return AppColors.catUnknown;
    }
  }

  String _catEmoji(SmsCategory cat) {
    switch (cat) {
      case SmsCategory.spending:
        return '🛒';
      case SmsCategory.banking:
        return '🏦';
      case SmsCategory.otp:
        return '🔑';
      case SmsCategory.promotions:
        return '🎁';
      case SmsCategory.work:
        return '💼';
      default:
        return '💬';
    }
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});
  final SmsCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label,
        style: AppTypography.label.copyWith(
          color: color,
          fontSize: 8,
        ),
      ),
    );
  }

  Color get _color {
    switch (category) {
      case SmsCategory.spending:
        return AppColors.chartPink;
      case SmsCategory.banking:
        return AppColors.chartBlue;
      case SmsCategory.otp:
        return AppColors.chartGold;
      default:
        return AppColors.catUnknown;
    }
  }

  String get _label {
    switch (category) {
      case SmsCategory.spending:
        return 'Shopping';
      case SmsCategory.banking:
        return 'Banking';
      case SmsCategory.otp:
        return 'OTP';
      case SmsCategory.promotions:
        return 'Promo';
      default:
        return 'Other';
    }
  }
}

// ============================================================
// lib/presentation/widgets/shimmer_placeholder.dart
// ============================================================



class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.bgDark3,
      highlightColor: AppColors.bgDark4,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.bgDark3,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
        ),
      ),
    );
  }
}

// ============================================================
// lib/presentation/widgets/empty_state.dart
// ============================================================



class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.compact = false,
    this.action,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool compact;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondaryDark,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// lib/presentation/widgets/period_tabs.dart
// ============================================================



class PeriodTabs extends StatelessWidget {
  const PeriodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgDark3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = selected == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _label(period),
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondaryDark,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(AnalyticsPeriod p) {
    switch (p) {
      case AnalyticsPeriod.day:
        return 'Day';
      case AnalyticsPeriod.week:
        return 'Week';
      case AnalyticsPeriod.month:
        return 'Month';
      case AnalyticsPeriod.year:
        return 'Year';
    }
  }
}

// ============================================================
// lib/presentation/widgets/insight_chip.dart
// ============================================================



class InsightChip extends StatelessWidget {
  const InsightChip({super.key, required this.text, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgDark3,
        border: Border.all(color: AppColors.bgDark4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimaryDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
