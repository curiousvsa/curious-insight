import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';
import 'core/utils/logger.dart';
import 'data/database/database_helper.dart';

/// Background task dispatcher — runs in a separate isolate.
/// Must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case AppConstants.kAnalyticsTask:
        AppLogger.info('Running background analytics task');
        // TODO: Run analytics aggregation in isolate
        break;
      case AppConstants.kCleanupTask:
        AppLogger.info('Running cleanup task');
        await DatabaseHelper.instance.deleteOlderThan(
          DateTime.now().subtract(const Duration(days: 90)),
        );
        break;
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0C16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize DB
  await DatabaseHelper.instance.init();

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Schedule periodic background tasks
  await Workmanager().registerPeriodicTask(
    AppConstants.kAnalyticsTask,
    AppConstants.kAnalyticsTask,
    frequency: const Duration(hours: 6),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  runApp(
    const ProviderScope(
      child: CuriousinsightApp(),
    ),
  );
}
