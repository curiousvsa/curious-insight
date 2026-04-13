/// All string constants and app-wide constants
class AppStrings {
  AppStrings._();

  // App
  static const appName = 'CuriousInSight';
  static const appTagline = 'On-Device Intelligence';

  // Onboarding
  static const onboardingTitle1 = 'Your finances,\nintelligently tracked';
  static const onboardingSubtitle1 =
      'CuriousInSight reads your SMS and notifications to '
      'give you a complete picture of your spending — '
      'all processed privately on your device.';
  static const onboardingTitle2 = 'Smart categorization';
  static const onboardingSubtitle2 =
      'Automatically classify every transaction by '
      'merchant, category and amount. No manual entry needed.';
  static const onboardingTitle3 = 'Beautiful insights';
  static const onboardingSubtitle3 =
      'Daily, weekly and monthly reports with charts, '
      'trends, and AI-generated recommendations.';

  // Permissions
  static const smsPermTitle = 'Read SMS';
  static const smsPermDesc =
      'Detects bank transactions, OTPs and alerts '
      'from your messages. Raw messages are never stored.';
  static const notifPermTitle = 'Notifications access';
  static const notifPermDesc =
      'Tracks which apps notify you most and your '
      'engagement patterns. Content is anonymized locally.';
  static const permGranted = 'Granted';
  static const permAllow = 'Allow';
  static const permOpenSettings = 'Open Settings';
  static const permPrivacyNote =
      'All data stays on your device. Nothing is '
      'shared without your explicit consent. You can '
      'delete all data at any time from Settings.';
  static const iosPermNote =
      '⚠️ iOS: SMS access is not permitted on iOS by '
      'Apple. Notification analytics are available with '
      'limited scope via the Notification Service Extension.';

  // Navigation
  static const navHome = 'Home';
  static const navSpending = 'Spend';
  static const navNotifications = 'Alerts';
  static const navExport = 'Export';
  static const navSettings = 'Settings';

  // Dashboard
  static const dashboardGreetingMorning = 'Good morning';
  static const dashboardGreetingAfternoon = 'Good afternoon';
  static const dashboardGreetingEvening = 'Good evening';
  static const totalSpendWeek = 'Total spend this week';
  static const vsLastWeek = 'vs last week';
  static const spendCategories = 'Spend categories';
  static const recentTransactions = 'Recent transactions';
  static const seeAll = 'See all';
  static const aiInsights = 'AI Insights';
  static const downloadReport = 'Download Weekly Report';
  static const downloadReportSub = 'PDF · Share via Email, WhatsApp';

  // Spending
  static const spending = 'Spending';
  static const dailyBreakdown = 'Daily breakdown';
  static const topMerchants = 'Top merchants';
  static const allTransactions = 'All transactions';
  static const noTransactions = 'No transactions found';
  static const noTransactionsDesc =
      'Transactions will appear here once SMS access is granted.';

  // Notifications
  static const notifications = 'Notifications';
  static const appDistribution = 'App distribution';
  static const engagementBreakdown = 'Engagement breakdown';
  static const peakHours = 'Peak hours';
  static const importantMissed = 'Important missed';
  static const opened = 'Opened';
  static const dismissed = 'Dismissed';
  static const ignored = 'Ignored';

  // Export
  static const exportReport = 'Export Report';
  static const exportSubtitle = 'Generate a PDF and share via any platform';
  static const reportPeriod = 'Report period';
  static const includeSections = 'Include sections';
  static const generatePdf = 'Generate PDF Report';
  static const regeneratePdf = 'Regenerate PDF';
  static const generating = 'Generating...';
  static const pdfReady = 'PDF ready!';
  static const shareVia = 'Share via';
  static const shareSheet = 'Share';
  static const email = 'Email';
  static const whatsApp = 'WhatsApp';
  static const saveToDevice = 'Save';
  static const print = 'Print';
  static const cancel = 'Cancel';

  // Settings
  static const settings = 'Settings';
  static const dataPrivacy = 'Data & Privacy';
  static const deleteAllData = 'Delete All Data';
  static const deleteAllDataConfirm =
      'Are you sure? This will permanently delete all '
      'your SMS data, notification history, and analytics. '
      'This action cannot be undone.';
  static const exportData = 'Export My Data';
  static const dataRetention = 'Data Retention';
  static const retentionDesc = 'Delete data older than:';
  static const appearance = 'Appearance';
  static const darkMode = 'Dark Mode';
  static const about = 'About';
  static const version = 'Version';
  static const privacyPolicy = 'Privacy Policy';
  static const termsOfService = 'Terms of Service';

  // Periods
  static const day = 'Day';
  static const week = 'Week';
  static const month = 'Month';
  static const year = 'Year';

  // Categories
  static const catSpending = 'Spending';
  static const catBanking = 'Banking';
  static const catOtp = 'OTP / Auth';
  static const catPromo = 'Promotions';
  static const catWork = 'Work';
  static const catSocial = 'Social';
  static const catImportant = 'Important';
  static const catSystem = 'System';
  static const catUnknown = 'Other';

  // Error messages
  static const genericError = 'Something went wrong. Please try again.';
  static const permissionDenied = 'Permission denied.';
  static const permissionPermanentlyDenied =
      'Permission permanently denied. Please enable it in Settings.';
  static const noDataYet = 'No data yet';
  static const noDataYetDesc =
      'Grant SMS and notification permissions to start '
      'seeing your analytics here.';
}

/// App-wide constant values
class AppConstants {
  AppConstants._();

  // WorkManager task names
  static const kAnalyticsTask = 'curiousinsight.analytics.aggregate';
  static const kCleanupTask = 'curiousinsight.data.cleanup';

  // SharedPreferences keys
  static const kHasSeenOnboarding = 'has_seen_onboarding';
  static const kUserName = 'user_name';
  static const kThemeMode = 'theme_mode';
  static const kDataRetentionDays = 'data_retention_days';

  // Platform channel names
  static const kSmsChannel = 'com.curiousinsight.app/sms';
  static const kSmsEventChannel = 'com.curiousinsight.app/sms_stream';
  static const kNotifChannel = 'com.curiousinsight.app/notifications';
  static const kNotifEventChannel = 'com.curiousinsight.app/notif_stream';
  static const kSecurityChannel = 'com.curiousinsight.app/security';

  // Database
  static const kDbName = 'curiousinsight.db';
  static const kDbVersion = 1;

  // Default values
  static const kDefaultRetentionDays = 90;
  static const kMaxPdfTransactions = 50;
  static const kSmsHistoryLimit = 1000;

  // PDF
  static const kPdfFilenamePrefix = 'Curiousinsight_Report';

  // Currency
  static const kCurrencySymbol = '₹';
  static const kCurrencyLocale = 'en_IN';
}
