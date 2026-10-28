import 'transaction.dart';

/// Supported spending periods for Spend Controls
enum SpendPeriod {
  daily,
  weekly,
  monthly,
}

extension SpendPeriodExtension on SpendPeriod {
  String get displayName {
    switch (this) {
      case SpendPeriod.daily:
        return 'Daily';
      case SpendPeriod.weekly:
        return 'Weekly';
      case SpendPeriod.monthly:
        return 'Monthly';
    }
  }

  String get shortName {
    switch (this) {
      case SpendPeriod.daily:
        return 'Day';
      case SpendPeriod.weekly:
        return 'Week';
      case SpendPeriod.monthly:
        return 'Month';
    }
  }

  String get description {
    switch (this) {
      case SpendPeriod.daily:
        return 'Today\'s spending against daily target';
      case SpendPeriod.weekly:
        return 'Current week\'s spending against weekly target';
      case SpendPeriod.monthly:
        return 'Current month\'s spending against monthly target';
    }
  }
}

/// Alert item generated when spending crosses configured thresholds
class SpendAlert {
  final String id;
  final String title;
  final String message;
  final double percentage;
  final String severity; // 'info', 'warning', 'danger'
  final DateTime timestamp;

  SpendAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.percentage,
    required this.severity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'percentage': percentage,
        'severity': severity,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SpendAlert.fromJson(Map<String, dynamic> json) => SpendAlert(
        id: json['id'] as String? ?? 'alert',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        severity: json['severity'] as String? ?? 'info',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Spend limit configuration and in-app preferences model
class SpendLimitModel {
  final double dailyLimit;
  final double weeklyLimit;
  final double monthlyLimit;
  final Map<String, double> categoryLimits;
  final bool alertAt50;
  final bool alertAt80;
  final bool alertAt100;
  final List<String> acknowledgedAlertIds;
  final DateTime? lastCycleReset;

  // In-app tracking preferences (Level 1 in-app controls, not issuer-level bank blocks)
  final bool inAppCardLock;
  final bool trackTapToPay;
  final bool trackInternational;

  SpendLimitModel({
    this.dailyLimit = 5000.0,
    this.weeklyLimit = 25000.0,
    this.monthlyLimit = 75000.0,
    Map<String, double>? categoryLimits,
    this.alertAt50 = true,
    this.alertAt80 = true,
    this.alertAt100 = true,
    List<String>? acknowledgedAlertIds,
    this.lastCycleReset,
    this.inAppCardLock = false,
    this.trackTapToPay = true,
    this.trackInternational = false,
  })  : categoryLimits = categoryLimits ?? {},
        acknowledgedAlertIds = acknowledgedAlertIds ?? [];

  double limitForPeriod(SpendPeriod period) {
    switch (period) {
      case SpendPeriod.daily:
        return dailyLimit;
      case SpendPeriod.weekly:
        return weeklyLimit;
      case SpendPeriod.monthly:
        return monthlyLimit;
    }
  }

  SpendLimitModel copyWith({
    double? dailyLimit,
    double? weeklyLimit,
    double? monthlyLimit,
    Map<String, double>? categoryLimits,
    bool? alertAt50,
    bool? alertAt80,
    bool? alertAt100,
    List<String>? acknowledgedAlertIds,
    DateTime? lastCycleReset,
    bool? inAppCardLock,
    bool? trackTapToPay,
    bool? trackInternational,
  }) {
    return SpendLimitModel(
      dailyLimit: dailyLimit ?? this.dailyLimit,
      weeklyLimit: weeklyLimit ?? this.weeklyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      categoryLimits: categoryLimits ?? Map.from(this.categoryLimits),
      alertAt50: alertAt50 ?? this.alertAt50,
      alertAt80: alertAt80 ?? this.alertAt80,
      alertAt100: alertAt100 ?? this.alertAt100,
      acknowledgedAlertIds:
          acknowledgedAlertIds ?? List.from(this.acknowledgedAlertIds),
      lastCycleReset: lastCycleReset ?? this.lastCycleReset,
      inAppCardLock: inAppCardLock ?? this.inAppCardLock,
      trackTapToPay: trackTapToPay ?? this.trackTapToPay,
      trackInternational: trackInternational ?? this.trackInternational,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyLimit': dailyLimit,
      'weeklyLimit': weeklyLimit,
      'monthlyLimit': monthlyLimit,
      'categoryLimits': categoryLimits,
      'alertAt50': alertAt50,
      'alertAt80': alertAt80,
      'alertAt100': alertAt100,
      'acknowledgedAlertIds': acknowledgedAlertIds,
      if (lastCycleReset != null)
        'lastCycleReset': lastCycleReset!.toIso8601String(),
      'inAppCardLock': inAppCardLock,
      'trackTapToPay': trackTapToPay,
      'trackInternational': trackInternational,
    };
  }

  factory SpendLimitModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> parsedCatLimits = {};
    if (json['categoryLimits'] is Map) {
      final raw = json['categoryLimits'] as Map;
      raw.forEach((k, v) {
        if (v is num) {
          parsedCatLimits[k.toString()] = v.toDouble();
        } else if (v != null) {
          parsedCatLimits[k.toString()] =
              double.tryParse(v.toString()) ?? 0.0;
        }
      });
    }

    List<String> parsedAckAlerts = [];
    if (json['acknowledgedAlertIds'] is List) {
      parsedAckAlerts = (json['acknowledgedAlertIds'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return SpendLimitModel(
      dailyLimit: (json['dailyLimit'] is num)
          ? (json['dailyLimit'] as num).toDouble()
          : (double.tryParse(json['dailyLimit']?.toString() ?? '5000') ??
              5000.0),
      weeklyLimit: (json['weeklyLimit'] is num)
          ? (json['weeklyLimit'] as num).toDouble()
          : (double.tryParse(json['weeklyLimit']?.toString() ?? '25000') ??
              25000.0),
      monthlyLimit: (json['monthlyLimit'] is num)
          ? (json['monthlyLimit'] as num).toDouble()
          : (double.tryParse(json['monthlyLimit']?.toString() ?? '75000') ??
              75000.0),
      categoryLimits: parsedCatLimits,
      alertAt50: json['alertAt50'] != false,
      alertAt80: json['alertAt80'] != false,
      alertAt100: json['alertAt100'] != false,
      acknowledgedAlertIds: parsedAckAlerts,
      lastCycleReset: json['lastCycleReset'] != null
          ? DateTime.tryParse(json['lastCycleReset'].toString())
          : null,
      inAppCardLock: json['inAppCardLock'] == true,
      trackTapToPay: json['trackTapToPay'] != false,
      trackInternational: json['trackInternational'] == true,
    );
  }
}

/// Aggregated spending calculation summary based on actual transactions
class SpendingSummary {
  final SpendPeriod period;
  final double totalSpent;
  final double limitAmount;
  final double remainingBudget;
  final double spendPercentage;
  final Map<String, double> categoryBreakdown;
  final List<SpendAlert> activeAlerts;
  final int transactionCount;

  SpendingSummary({
    required this.period,
    required this.totalSpent,
    required this.limitAmount,
    required this.remainingBudget,
    required this.spendPercentage,
    required this.categoryBreakdown,
    required this.activeAlerts,
    required this.transactionCount,
  });

  bool get isOverBudget => limitAmount > 0 && totalSpent > limitAmount;
  bool get isNearLimit =>
      limitAmount > 0 && spendPercentage >= 0.8 && !isOverBudget;
  bool get isHealthy => !isOverBudget && !isNearLimit;

  /// Pure deterministic calculator for spend controls against actual transaction list
  static SpendingSummary calculate({
    required List<TransactionModel> transactions,
    required SpendPeriod period,
    required SpendLimitModel limits,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    // 1. Filter transactions to strictly valid expense records in the selected period
    final List<TransactionModel> periodExpenses = transactions.where((tx) {
      if (tx.type.toLowerCase() != 'expense') return false;

      final txDate = tx.date;
      switch (period) {
        case SpendPeriod.daily:
          return txDate.year == now.year &&
              txDate.month == now.month &&
              txDate.day == now.day;
        case SpendPeriod.weekly:
          // Standard week: Monday 00:00:00 to Sunday 23:59:59
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          final endOfWeek =
              startOfWeek.add(const Duration(days: 7, microseconds: -1));
          return !txDate.isBefore(startOfWeek) && !txDate.isAfter(endOfWeek);
        case SpendPeriod.monthly:
          return txDate.year == now.year && txDate.month == now.month;
      }
    }).toList();

    // 2. Calculate total spend and category breakdown
    double total = 0.0;
    final Map<String, double> catMap = {};

    for (final tx in periodExpenses) {
      total += tx.amount;
      final cat = (tx.category != null && tx.category!.trim().isNotEmpty)
          ? tx.category!.trim()
          : 'Other';
      catMap[cat] = (catMap[cat] ?? 0.0) + tx.amount;
    }

    final limit = limits.limitForPeriod(period);
    final remaining = (limit - total).clamp(0.0, limit > 0 ? limit : 0.0);
    final pct = limit > 0 ? (total / limit) : 0.0;

    // 3. Generate threshold alerts based on configured triggers
    final List<SpendAlert> alerts = [];

    // Period prefix identifier for alert deduplication (e.g. monthly_2026_10)
    final cycleKey = '${period.name}_${now.year}_${now.month}_${period == SpendPeriod.daily ? now.day : period == SpendPeriod.weekly ? (now.day ~/ 7) : 0}';

    if (limit > 0) {
      if (pct >= 1.0 && limits.alertAt100) {
        final alertId = 'alert_100_$cycleKey';
        if (!limits.acknowledgedAlertIds.contains(alertId)) {
          alerts.add(SpendAlert(
            id: alertId,
            title: '${period.displayName} Spend Limit Exceeded!',
            message:
                'You have spent ${(pct * 100).toStringAsFixed(0)}% of your ${period.displayName.toLowerCase()} budget. Limit is ${limit.toStringAsFixed(0)}.',
            percentage: pct,
            severity: 'danger',
          ));
        }
      } else if (pct >= 0.8 && limits.alertAt80) {
        final alertId = 'alert_80_$cycleKey';
        if (!limits.acknowledgedAlertIds.contains(alertId)) {
          alerts.add(SpendAlert(
            id: alertId,
            title: '${period.displayName} Spend Alert (80% Reached)',
            message:
                'You have used ${(pct * 100).toStringAsFixed(0)}% of your ${period.displayName.toLowerCase()} target.',
            percentage: pct,
            severity: 'warning',
          ));
        }
      } else if (pct >= 0.5 && limits.alertAt50) {
        final alertId = 'alert_50_$cycleKey';
        if (!limits.acknowledgedAlertIds.contains(alertId)) {
          alerts.add(SpendAlert(
            id: alertId,
            title: '${period.displayName} Budget Update (50% Reached)',
            message:
                'Half of your ${period.displayName.toLowerCase()} spending limit has been reached.',
            percentage: pct,
            severity: 'info',
          ));
        }
      }
    }

    // Category-specific alerts
    limits.categoryLimits.forEach((category, catLimit) {
      if (catLimit > 0) {
        final catSpent = catMap[category] ?? 0.0;
        if (catSpent >= catLimit) {
          final catAlertId = 'alert_cat_${category}_$cycleKey';
          if (!limits.acknowledgedAlertIds.contains(catAlertId)) {
            alerts.add(SpendAlert(
              id: catAlertId,
              title: '$category Limit Exceeded',
              message:
                  'Spent ${catSpent.toStringAsFixed(0)} on $category (Limit: ${catLimit.toStringAsFixed(0)}).',
              percentage: catSpent / catLimit,
              severity: 'danger',
            ));
          }
        }
      }
    });

    return SpendingSummary(
      period: period,
      totalSpent: total,
      limitAmount: limit,
      remainingBudget: remaining,
      spendPercentage: pct,
      categoryBreakdown: catMap,
      activeAlerts: alerts,
      transactionCount: periodExpenses.length,
    );
  }
}
