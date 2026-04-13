import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';


import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/services.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.week;
  final Set<String> _sections = {
    'spending',
    'notifications',
    'transactions',
    'insights',
  };

  @override
  void initState() {
    super.initState();
    // Reset on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exportProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.exportReport,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.exportSubtitle,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
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
                  // Period selector
                  Text(
                    AppStrings.reportPeriod.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PeriodTabs(
                    selected: _period,
                    onChanged: (p) => setState(() => _period = p),
                  ),
                  const SizedBox(height: 20),

                  // Include sections
                  Text(
                    AppStrings.includeSections.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionSelector(
                    selected: _sections,
                    onToggle: (s) => setState(() {
                      if (_sections.contains(s)) {
                        _sections.remove(s);
                      } else {
                        _sections.add(s);
                      }
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Generate button
                  if (exportState.status == ExportStatus.idle ||
                      exportState.status == ExportStatus.error) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sections.isNotEmpty
                            ? () => ref.read(exportProvider.notifier).generateReport(
                                  period: _period,
                                  sections: _sections.toList(),
                                )
                            : null,
                        child: const Text(AppStrings.generatePdf),
                      ),
                    ),
                    if (exportState.status == ExportStatus.error)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Error: ${exportState.error}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],

                  // Progress
                  if (exportState.status == ExportStatus.generating)
                    _GeneratingCard(state: exportState),

                  // Ready
                  if (exportState.status == ExportStatus.ready &&
                      exportState.filePath != null)
                    _ReadyCard(
                      filePath: exportState.filePath!,
                      onRegenerate: () {
                        ref.read(exportProvider.notifier).reset();
                      },
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

// ----------------------------------------------------------------

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static const _options = [
    (key: 'spending', emoji: '💳', label: 'Spending overview',
        sub: 'Totals, categories, trends'),
    (key: 'notifications', emoji: '🔔', label: 'Notification analytics',
        sub: 'App breakdown, engagement'),
    (key: 'transactions', emoji: '📋', label: 'Transaction log',
        sub: 'Full itemized list'),
    (key: 'insights', emoji: '💡', label: 'AI insights',
        sub: 'Behavioral recommendations'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _options.map((opt) {
        final isSelected = selected.contains(opt.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onToggle(opt.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.08)
                    : AppColors.bgDark2,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.bgDark4,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bgDark3,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        opt.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt.label,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          opt.sub,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.bgDark4,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ----------------------------------------------------------------

class _GeneratingCard extends StatelessWidget {
  const _GeneratingCard({required this.state});
  final ExportState state;

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                  backgroundColor: AppColors.bgDark3,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.statusMessage,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              Text(
                '${(state.progress * 100).round()}%',
                style: AppTypography.mono.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppColors.bgDark3,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({
    required this.filePath,
    required this.onRegenerate,
  });

  final String filePath;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.split('/').last;
    final file = File(filePath);

    return Column(
      children: [
        // Success banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.05),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('📄', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.pdfReady,
                style: AppTypography.h3.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: 4),
              Text(
                fileName,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Share via label
        Text(
          AppStrings.shareVia.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: AppColors.textTertiaryDark,
          ),
        ),
        const SizedBox(height: 12),

        // Share action grid
        Row(
          children: [
            _ShareAction(
              emoji: '🔗',
              label: AppStrings.shareSheet,
              color: AppColors.primary,
              onTap: () => ShareService.shareFile(filePath),
            ),
            const SizedBox(width: 8),
            _ShareAction(
              emoji: '✉️',
              label: AppStrings.email,
              color: const Color(0xFF2196F3),
              onTap: () => _showEmailDialog(context, filePath),
            ),
            const SizedBox(width: 8),
            _ShareAction(
              emoji: '💾',
              label: AppStrings.saveToDevice,
              color: AppColors.success,
              onTap: () async {
                final saved = await ShareService.saveToDownloads(filePath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved to ${saved}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            _ShareAction(
              emoji: '🖨️',
              label: AppStrings.print,
              color: AppColors.warning,
              onTap: () => ShareService.printFile(filePath),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Open preview
        OutlinedButton.icon(
          onPressed: () => OpenFilex.open(filePath),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('Preview PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
        const SizedBox(height: 8),

        // Regenerate
        TextButton(
          onPressed: onRegenerate,
          child: Text(
            AppStrings.regeneratePdf,
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ),
      ],
    );
  }

  void _showEmailDialog(BuildContext context, String filePath) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgDark2,
        title: const Text('Send via Email'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Recipient Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ShareService.shareViaEmail(
                filePath: filePath,
                toEmail: emailCtrl.text.trim(),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTypography.label.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
