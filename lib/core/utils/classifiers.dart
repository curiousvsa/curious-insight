// ============================================================
// lib/core/utils/amount_parser.dart
// ============================================================

import 'dart:async';
import '../../domain/entities/entities.dart';

class AmountParser {
  AmountParser._();

  static final List<RegExp> _patterns = [
    // INR/Rs./₹ prefix
    RegExp(
      r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    // debited/credited for amount
    RegExp(
      r'(?:debited|credited|deducted|charged)\s+(?:by|for|with|of)?\s*'
      r'(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    // "amount" keyword
    RegExp(
      r'amount\s*:?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    // "spent" keyword
    RegExp(
      r'spent\s+(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    // "payment of" pattern
    RegExp(
      r'payment\s+of\s+(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
  ];

  /// Parse amount from SMS text. Returns null if none found.
  static double? parse(String text) {
    for (final pattern in _patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final raw = match.group(1)!.replaceAll(',', '');
        return double.tryParse(raw);
      }
    }
    return null;
  }
}

// ============================================================
// lib/core/utils/category_classifier.dart
// ============================================================


class CategoryClassifier {
  CategoryClassifier._();

  // Sender-based rules (highest priority)
  static final Map<RegExp, SmsCategory> _senderRules = {
    RegExp(
      r'(SBI|SBIINB|HDFC|HDFCBK|ICICI|ICICIB|AXIS|AXISBK|KOTAK|PNB|BOI|BOB|'
      r'CANARA|UNION|FEDERAL|YES|IDFC|INDUSIND)',
      caseSensitive: false,
    ): SmsCategory.banking,
    RegExp(
      r'(PAYTM|PHONEPE|GPAY|GOOGLEPAY|AMAZONPAY|FREECHARGE|MOBIKWIK)',
      caseSensitive: false,
    ): SmsCategory.spending,
    RegExp(
      r'(OTP|SECURE|VERIFY|AUTH|AUTHENTIFY)',
      caseSensitive: false,
    ): SmsCategory.otp,
  };

  // Content keyword rules — ordered by priority
  static final Map<SmsCategory, List<RegExp>> _contentRules = {
    SmsCategory.otp: [
      RegExp(
        r'\b(OTP|one.time.password|verification code|auth.?code|'
        r'passcode|pin.is|your.code)\b',
        caseSensitive: false,
      ),
    ],
    SmsCategory.banking: [
      RegExp(
        r'\b(account|A\/c|acc\b|balance|statement|IFSC|NEFT|RTGS|IMPS|'
        r'UPI|wire transfer|fund transfer|credit card|debit card)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(debited|credited|withdrawn|deposited|transferred)\b',
        caseSensitive: false,
      ),
    ],
    SmsCategory.spending: [
      RegExp(
        r'\b(spent|payment|paid|purchase|transaction|order|bill|'
        r'receipt|invoice|merchant|pos)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(Zomato|Swiggy|Uber|Ola|Amazon|Flipkart|Myntra|Blinkit|'
        r'Zepto|BigBasket|Nykaa|Meesho|Ajio|Tata|Reliance)\b',
        caseSensitive: false,
      ),
    ],
    SmsCategory.promotions: [
      RegExp(
        r'\b(offer|discount|sale|deal|cashback|coupon|voucher|promo|'
        r'off\b|limited.time|exclusive|hurry|expires|valid.till|'
        r'flash.sale|special.price)\b',
        caseSensitive: false,
      ),
    ],
    SmsCategory.work: [
      RegExp(
        r'\b(meeting|conference|deadline|task|project|report|'
        r'salary|payroll|payslip|hr|leave|attendance)\b',
        caseSensitive: false,
      ),
    ],
    SmsCategory.important: [
      RegExp(
        r'\b(urgent|important|action.required|reminder|alert|'
        r'notice|warning|due.date|overdue|final.notice)\b',
        caseSensitive: false,
      ),
    ],
    SmsCategory.system: [
      RegExp(
        r'\b(recharge|data.pack|tariff|plan|renewal|subscription|'
        r'activated|deactivated|network|sim|service)\b',
        caseSensitive: false,
      ),
    ],
  };

  static SmsCategory classifySms(String sender, String content) {
    final lowerContent = content.toLowerCase();

    // 1. OTP takes highest priority regardless of sender
    if (_contentRules[SmsCategory.otp]!
        .any((p) => p.hasMatch(lowerContent))) {
      return SmsCategory.otp;
    }

    // 2. Check sender rules
    for (final entry in _senderRules.entries) {
      if (entry.key.hasMatch(sender)) {
        return entry.value;
      }
    }

    // 3. Content-based matching
    const priority = [
      SmsCategory.banking,
      SmsCategory.spending,
      SmsCategory.important,
      SmsCategory.work,
      SmsCategory.promotions,
      SmsCategory.system,
    ];

    for (final category in priority) {
      final rules = _contentRules[category] ?? [];
      if (rules.any((p) => p.hasMatch(content))) {
        return category;
      }
    }

    return SmsCategory.unknown;
  }

  static TransactionType classifyTransaction(String content) {
    final lc = content.toLowerCase();
    if (RegExp(r'\b(debited|deducted|withdrawn|paid|spent|charged|debit)\b')
        .hasMatch(lc)) {
      return TransactionType.debit;
    }
    if (RegExp(
      r'\b(credited|received|added|refund|cashback|credit|reversal)\b',
    ).hasMatch(lc)) {
      return TransactionType.credit;
    }
    if (RegExp(r'\botp\b|\bone.time\b|\bverif|\bauth').hasMatch(lc)) {
      return TransactionType.otp;
    }
    if (RegExp(r'\b(offer|sale|discount|deal|promo)\b').hasMatch(lc)) {
      return TransactionType.promo;
    }
    return TransactionType.unknown;
  }

  static String? extractEntityName(String sender, String content) {
    // Clean sender (remove carrier prefix like VK-, AD-, etc.)
    final cleanedSender = sender.replaceAll(RegExp(r'^[A-Z]{2}-'), '').trim();
    if (cleanedSender.isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(cleanedSender) &&
        cleanedSender.length > 2) {
      return cleanedSender;
    }

    // Extract merchant from content
    final patterns = [
      RegExp(r'at\s+([A-Z][a-zA-Z0-9\s&\-\.]+?)(?:\s+on|\s+for|\s+via|\.)', ),
      RegExp(r'from\s+([A-Z][a-zA-Z0-9\s&\-\.]+?)(?:\s+on|\s+for|\.)'),
      RegExp(r'to\s+([A-Z][a-zA-Z0-9\s&\-\.]+?)(?:\s+on|\s+for|\.)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length > 2 && name.length < 40) {
          return name;
        }
      }
    }
    return null;
  }

  static NotificationCategory classifyNotification(
    String packageName,
    String content,
  ) {
    final pkg = packageName.toLowerCase();

    if (RegExp(
      r'(whatsapp|telegram|instagram|facebook|snapchat|twitter|signal|'
      r'viber|discord|line|skype)',
    ).hasMatch(pkg)) {
      return NotificationCategory.social;
    }

    if (RegExp(r'(gmail|outlook|slack|teams|zoom|meet|office)').hasMatch(pkg)) {
      return NotificationCategory.work;
    }

    if (RegExp(
      r'(amazon|flipkart|myntra|zomato|swiggy|blinkit|zepto|bigbasket|'
      r'nykaa|meesho)',
    ).hasMatch(pkg)) {
      if (RegExp(
        r'(offer|deal|discount|sale)',
        caseSensitive: false,
      ).hasMatch(content)) {
        return NotificationCategory.promotion;
      }
      return NotificationCategory.transaction;
    }

    if (RegExp(r'(sbi|hdfc|icici|axis|kotak|paytm|phonepe|gpay)').hasMatch(pkg)) {
      return NotificationCategory.transaction;
    }

    if (RegExp(
      r'(offer|deal|discount|sale|cashback)',
      caseSensitive: false,
    ).hasMatch(content)) {
      return NotificationCategory.promotion;
    }

    if (RegExp(
      r'(urgent|alert|warning|action.required)',
      caseSensitive: false,
    ).hasMatch(content)) {
      return NotificationCategory.alert;
    }

    return NotificationCategory.unknown;
  }

  static NotificationPriority classifyNotifPriority(
    NotificationCategory category,
    String content,
  ) {
    if (category == NotificationCategory.transaction ||
        category == NotificationCategory.alert ||
        RegExp(
          r'(urgent|action required|otp|debited|credited)',
          caseSensitive: false,
        ).hasMatch(content)) {
      return NotificationPriority.high;
    }
    if (category == NotificationCategory.message ||
        category == NotificationCategory.work) {
      return NotificationPriority.medium;
    }
    return NotificationPriority.low;
  }
}
