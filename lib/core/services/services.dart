// ============================================================
// lib/core/services/pdf_export_service.dart
// ============================================================
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/app_strings.dart';
import '../../domain/entities/entities.dart';
import '../../presentation/providers/providers.dart';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  static final _currencyFmt = NumberFormat.currency(
    locale: AppConstants.kCurrencyLocale,
    symbol: AppConstants.kCurrencySymbol,
    decimalDigits: 0,
  );
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _filenameFmt = DateFormat('yyyyMMdd_HHmm');

  // Brand colors as PDF colors
  static const _primaryColor = PdfColor.fromInt(0xFF7C6FFF);
  static const _successColor = PdfColor.fromInt(0xFF52FF8E);
  static const _errorColor = PdfColor.fromInt(0xFFFF5252);
  static const _bgDark = PdfColor.fromInt(0xFF0B0C16);
  static const _bgDark2 = PdfColor.fromInt(0xFF12132A);
  static const _bgDark3 = PdfColor.fromInt(0xFF1A1B35);
  static const _textPrimary = PdfColors.white;
  static const _textSecondary = PdfColor.fromInt(0xFF888899);
  static const _border = PdfColor.fromInt(0xFF252540);

  Future<File> generateReport({
    required String userName,
    required AnalyticsPeriod period,
    required List<DailyAnalytics> dailyData,
    WeeklyAnalytics? weeklyData,
    required List<String> sections,
  }) async {
    final pdf = pw.Document(
      title: 'CuriousInSight Analytics Report',
      author: 'CuriousInSight',
      creator: 'CuriousInSight App v1.0',
    );

    final now = DateTime.now();
    final periodLabel = _periodLabel(period);

    DateTime periodStart = now;
    DateTime periodEnd = now;
    if (weeklyData != null) {
      periodStart = weeklyData.weekStart;
      periodEnd = weeklyData.weekEnd;
    }

    final totalSpend = dailyData.fold<double>(0, (s, d) => s + d.totalSpend);
    final totalNotif = dailyData.fold<int>(0, (s, d) => s + d.totalNotifications);

    // ---- Cover page ----
    pdf.addPage(_buildCoverPage(
      userName: userName,
      periodLabel: periodLabel,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalSpend: totalSpend,
      totalNotifications: totalNotif,
    ));

    // ---- Spending overview ----
    if (sections.contains('spending') && weeklyData != null) {
      pdf.addPage(_buildSpendingPage(weekly: weeklyData, dailyData: dailyData));
    }

    // ---- Notification analytics ----
    if (sections.contains('notifications') && weeklyData != null) {
      pdf.addPage(_buildNotificationsPage(weekly: weeklyData));
    }

    // ---- Transaction log ----
    if (sections.contains('transactions')) {
      final allTxns = dailyData
          .expand((d) => d.transactions)
          .where((t) => t.amount != null)
          .take(AppConstants.kMaxPdfTransactions)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (allTxns.isNotEmpty) {
        pdf.addPage(_buildTransactionsPage(transactions: allTxns));
      }
    }

    // ---- Insights ----
    if (sections.contains('insights') && weeklyData != null) {
      pdf.addPage(_buildInsightsPage(weekly: weeklyData));
    }

    // Write to file
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        '${AppConstants.kPdfFilenamePrefix}_${periodLabel}_${_filenameFmt.format(now)}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ---- Cover page ----

  pw.Page _buildCoverPage({
    required String userName,
    required String periodLabel,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double totalSpend,
    required int totalNotifications,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        color: _bgDark,
        padding: const pw.EdgeInsets.all(48),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CURIOUSINSIGHT',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                        letterSpacing: 4,
                      ),
                    ),
                    pw.Text(
                      'Analytics Intelligence',
                      style: const pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _primaryColor),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    periodLabel.toUpperCase(),
                    style: const pw.TextStyle(
                      color: _primaryColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 72),

            pw.Text(
              '$periodLabel Report',
              style: pw.TextStyle(
                fontSize: 42,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '${_dateFmt.format(periodStart)} — ${_dateFmt.format(periodEnd)}',
              style: const pw.TextStyle(color: _textSecondary, fontSize: 15),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Prepared for $userName',
              style: const pw.TextStyle(color: _primaryColor, fontSize: 13),
            ),

            pw.SizedBox(height: 64),

            // Key metrics
            pw.Row(
              children: [
                _metricBox(
                  label: 'Total Spend',
                  value: _currencyFmt.format(totalSpend),
                  color: _successColor,
                ),
                pw.SizedBox(width: 20),
                _metricBox(
                  label: 'Notifications',
                  value: totalNotifications.toString(),
                  color: _primaryColor,
                ),
              ],
            ),

            pw.Spacer(),

            pw.Divider(color: _border),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by CuriousInSight — All data processed on-device',
                  style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                  style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _metricBox({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color),
          borderRadius: pw.BorderRadius.circular(8),
          color: _bgDark2,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(color: _textSecondary, fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Spending page ----

  pw.Page _buildSpendingPage({
    required WeeklyAnalytics weekly,
    required List<DailyAnalytics> dailyData,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        color: _bgDark,
        padding: const pw.EdgeInsets.all(48),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('Spending Overview'),
            pw.SizedBox(height: 28),

            // Total hero
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _bgDark2,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Total Period Spend',
                    style: const pw.TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    _currencyFmt.format(weekly.totalSpend),
                    style: pw.TextStyle(
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                      color: _successColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _formatDelta(weekly.spendDeltaPercent),
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: weekly.spendDeltaPercent >= 0
                          ? _errorColor
                          : _successColor,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 28),

            // Category table
            pw.Text(
              'Spend by Category',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
                fontSize: 15,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                _tableHeader(['Category', 'Amount', 'Share']),
                ...weekly.spendByCategory.map(
                  (cat) => _tableRow([
                    _catLabel(cat.category),
                    _currencyFmt.format(cat.amount),
                    '${cat.percentage.toStringAsFixed(1)}%',
                  ]),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Daily breakdown mini bar chart (text-based)
            pw.Text(
              'Daily Spend',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
                fontSize: 15,
              ),
            ),
            pw.SizedBox(height: 12),
            _textBarChart(weekly.dailySpend),
          ],
        ),
      ),
    );
  }

  // ---- Notifications page ----

  pw.Page _buildNotificationsPage({required WeeklyAnalytics weekly}) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        color: _bgDark,
        padding: const pw.EdgeInsets.all(48),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('Notification Analytics'),
            pw.SizedBox(height: 28),

            pw.Row(
              children: [
                _smallMetric('Total', weekly.totalNotifications.toString(), _primaryColor),
                pw.SizedBox(width: 16),
                _smallMetric('Top App', weekly.topApps.isNotEmpty ? weekly.topApps.first.appName : '—', _successColor),
              ],
            ),
            pw.SizedBox(height: 24),

            pw.Text(
              'Top Apps by Volume',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
                fontSize: 15,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                _tableHeader(['App', 'Count', 'Share']),
                ...weekly.topApps.map(
                  (app) => _tableRow([
                    app.appName,
                    app.count.toString(),
                    '${app.percentage.toStringAsFixed(1)}%',
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Transactions page ----

  pw.Page _buildTransactionsPage({required List<SmsEntity> transactions}) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        color: _bgDark,
        padding: const pw.EdgeInsets.all(48),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('Transaction Log'),
            pw.SizedBox(height: 28),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                _tableHeader(['Date & Time', 'Merchant', 'Amount', 'Type']),
                ...transactions.map(
                  (txn) => _tableRow([
                    DateFormat('dd MMM, HH:mm').format(txn.timestamp),
                    txn.entityName ?? txn.sender,
                    _currencyFmt.format(txn.amount!),
                    txn.transactionType.name,
                  ], amountColor: txn.transactionType == TransactionType.credit
                      ? _successColor
                      : _errorColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Insights page ----

  pw.Page _buildInsightsPage({required WeeklyAnalytics weekly}) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        color: _bgDark,
        padding: const pw.EdgeInsets.all(48),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('Insights & Recommendations'),
            pw.SizedBox(height: 28),
            if (weekly.behavioralInsights.isNotEmpty) ...[
              pw.Text(
                'Behavioral Insights',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _textPrimary, fontSize: 15),
              ),
              pw.SizedBox(height: 12),
              ...weekly.behavioralInsights.map(
                (i) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: _bulletItem(i, _primaryColor),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            if (weekly.recommendations.isNotEmpty) ...[
              pw.Text(
                'Recommendations',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _textPrimary, fontSize: 15),
              ),
              pw.SizedBox(height: 12),
              ...weekly.recommendations.map(
                (r) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: _bulletItem(r, _successColor),
                ),
              ),
            ],
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _bgDark2,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Text(
                'All data in this report was processed entirely on-device. '
                'CuriousInSight does not share your personal financial or '
                'communication data with any third parties.',
                style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Helpers ----

  pw.Widget _pageHeader(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(width: 40, height: 3, color: _primaryColor),
        ],
      );

  pw.TableRow _tableHeader(List<String> headers) => pw.TableRow(
        decoration: const pw.BoxDecoration(color: _bgDark3),
        children: headers.map((h) => _tableCell(h, isHeader: true)).toList(),
      );

  pw.TableRow _tableRow(List<String> cells, {PdfColor? amountColor}) =>
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _border)),
        ),
        children: cells.asMap().entries.map((e) {
          final isAmount = amountColor != null && e.key == 2;
          return _tableCell(e.value, color: isAmount ? amountColor : null);
        }).toList(),
      );

  pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: isHeader ? pw.FontWeight.bold : null,
            color: color ?? (isHeader ? _textSecondary : _textPrimary),
            fontSize: isHeader ? 10 : 11,
          ),
        ),
      );

  pw.Widget _smallMetric(String label, String value, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: _bgDark2,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(color: _textSecondary, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: _textPrimary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );

  pw.Widget _textBarChart(List<DailySpend> data) {
    if (data.isEmpty) return pw.SizedBox();
    final maxAmt = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);

    return pw.Column(
      children: data.map((d) {
        final frac = maxAmt > 0 ? d.amount / maxAmt : 0.0;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 32,
                child: pw.Text(
                  DateFormat('EEE').format(d.date),
                  style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  height: 10,
                  child: pw.SizedBox(
                    width: frac,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: _primaryColor,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _currencyFmt.format(d.amount),
                style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _bulletItem(String text, PdfColor color) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 6,
            height: 6,
            margin: const pw.EdgeInsets.only(top: 4, right: 10),
            decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(color: _textPrimary, fontSize: 12)),
          ),
        ],
      );

  String _periodLabel(AnalyticsPeriod p) {
    switch (p) {
      case AnalyticsPeriod.day:
        return 'Daily';
      case AnalyticsPeriod.week:
        return 'Weekly';
      case AnalyticsPeriod.month:
        return 'Monthly';
      case AnalyticsPeriod.year:
        return 'Yearly';
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

  String _formatDelta(double pct) {
    final sign = pct >= 0 ? '▲' : '▼';
    return '$sign ${pct.abs().toStringAsFixed(1)}% vs last period';
  }
}

// ============================================================
// lib/core/services/share_service.dart
// ============================================================



class ShareService {
  ShareService._();

  /// System share sheet — WhatsApp, Gmail, Telegram, Drive, etc.
  static Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/pdf')],
      subject: subject ?? 'CuriousInSight Analytics Report',
      text: 'Your CuriousInSight analytics report is attached.',
    );
  }

  /// Email with attachment
  static Future<void> shareViaEmail({
    required String filePath,
    required String toEmail,
    String? subject,
    String? body,
  }) async {
    final email = Email(
      body: body ?? 'Please find your CuriousInSight analytics report attached.',
      subject: subject ?? 'CuriousInSight Analytics Report',
      recipients: [toEmail],
      attachmentPaths: [filePath],
      isHTML: false,
    );
    await FlutterEmailSender.send(email);
  }

  /// Save to device Downloads (or Documents on iOS)
  static Future<String> saveToDownloads(String filePath) async {
    final source = File(filePath);
    final fileName = filePath.split('/').last;

    Directory? destDir;
    if (Platform.isAndroid) {
      destDir = Directory('/storage/emulated/0/Download');
      if (!await destDir.exists()) {
        destDir = await getExternalStorageDirectory();
      }
    } else {
      destDir = await getApplicationDocumentsDirectory();
    }

    destDir ??= await getApplicationDocumentsDirectory();
    final destPath = '${destDir.path}/$fileName';
    await source.copy(destPath);
    return destPath;
  }

  /// System print dialog
  static Future<void> printFile(String filePath) async {
    final file = File(filePath);
    await Printing.layoutPdf(
      onLayout: (_) => file.readAsBytes(),
      name: filePath.split('/').last,
    );
  }
}
