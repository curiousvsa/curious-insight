import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../providers/providers.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _smsGranted = false;
  bool _notifGranted = false;
  bool _notifListenerGranted = false;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isCheckingPermissions = true);

    if (!Platform.isIOS) {
      final sms = await Permission.sms.status;
      setState(() => _smsGranted = sms.isGranted);
    }

    final notif = await Permission.notification.status;
    setState(() {
      _notifGranted = notif.isGranted;
      _isCheckingPermissions = false;
    });

    // Check notification listener (Android-specific via platform channel)
    if (Platform.isAndroid) {
      final enabled = await ref
          .read(notifIngestProvider.notifier)
          .checkListenerEnabled();
      setState(() => _notifListenerGranted = enabled);
    }
  }

  Future<void> _requestSms() async {
    final result = await Permission.sms.request();
    setState(() => _smsGranted = result.isGranted);
    if (result.isPermanentlyDenied) {
      _showPermanentlyDeniedSnack('SMS');
    }
  }

  Future<void> _requestNotification() async {
    final result = await Permission.notification.request();
    setState(() => _notifGranted = result.isGranted);
    if (result.isPermanentlyDenied) {
      _showPermanentlyDeniedSnack('Notification');
    }
  }

  Future<void> _openNotificationListenerSettings() async {
    await ref.read(notifIngestProvider.notifier).openSettings();
    // Re-check after returning from settings
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _checkPermissions();
  }

  void _showPermanentlyDeniedSnack(String permName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$permName permission denied. Enable in Settings.'),
        action: SnackBarAction(
          label: 'Open Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  bool get _canContinue => _smsGranted || _notifGranted;

  Future<void> _continue() async {
    // Start ingesting data
    if (_smsGranted && !Platform.isIOS) {
      await ref.read(smsIngestProvider.notifier).ingestHistorical();
      ref.read(smsIngestProvider.notifier).startRealtime();
    }
    if (_notifListenerGranted) {
      ref.read(notifIngestProvider.notifier).startListening();
    }
    if (mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + Header
                    const SizedBox(height: 16),
                    Text(
                      'Before we begin',
                      style: AppTypography.display.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PulseIQ needs a few permissions to analyse your '
                      'messages and notifications — processed privately on your device.',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textSecondaryDark,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // iOS note
                    if (Platform.isIOS) ...[
                      _IosNote(),
                      const SizedBox(height: 16),
                    ],

                    // SMS Permission (Android only)
                    if (!Platform.isIOS) ...[
                      _PermissionCard(
                        icon: '💬',
                        title: AppStrings.smsPermTitle,
                        description: AppStrings.smsPermDesc,
                        isGranted: _smsGranted,
                        isLoading: _isCheckingPermissions,
                        onRequest: _requestSms,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Notification Permission
                    _PermissionCard(
                      icon: '🔔',
                      title: AppStrings.notifPermTitle,
                      description: AppStrings.notifPermDesc,
                      isGranted: _notifGranted,
                      isLoading: _isCheckingPermissions,
                      onRequest: _requestNotification,
                    ),

                    // Notification Listener (Android only — requires Settings)
                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 12),
                      _PermissionCard(
                        icon: '📡',
                        title: 'Notification listener',
                        description:
                            'Required to track notification engagement. '
                            'Enable in Special App Access settings.',
                        isGranted: _notifListenerGranted,
                        isLoading: _isCheckingPermissions,
                        requiresSettings: true,
                        onRequest: _openNotificationListenerSettings,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Privacy box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark2,
                        border: Border.all(color: AppColors.bgDark4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.permPrivacyNote,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondaryDark,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 32),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canContinue ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.3),
                          disabledForegroundColor:
                              Colors.white.withOpacity(0.4),
                        ),
                        child: const Text('Continue to Dashboard'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Skip
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.dashboard),
                        child: Text(
                          'Skip for now',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textTertiaryDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------

extension on NotifIngestNotifier {
  Future<bool> checkListenerEnabled() async {
    // Delegated to NotificationPlatformChannel — returns false if not Android
    return false;
  }
}

// ----------------------------------------------------------------

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onRequest,
    this.isLoading = false,
    this.requiresSettings = false,
  });

  final String icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isLoading;
  final bool requiresSettings;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDark2,
        border: Border.all(
          color: isGranted
              ? AppColors.success.withOpacity(0.4)
              : AppColors.bgDark4,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (isGranted)
                _StatusBadge(
                  label: AppStrings.permGranted,
                  color: AppColors.success,
                )
              else
                _ActionButton(
                  label: requiresSettings
                      ? AppStrings.permOpenSettings
                      : AppStrings.permAllow,
                  onTap: onRequest,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _IosNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1200),
        border: Border.all(color: const Color(0xFF443300)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppStrings.iosPermNote,
        style: AppTypography.caption.copyWith(
          color: AppColors.warning,
          height: 1.6,
        ),
      ),
    );
  }
}
