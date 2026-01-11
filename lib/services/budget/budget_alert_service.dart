import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopple/services/budget/realtime_budget_service.dart';
import 'package:shopple/utils/app_logger.dart';

/// Service to monitor budget usage and trigger alerts when thresholds are reached.
class BudgetAlertService {
  BudgetAlertService._();
  static final BudgetAlertService instance = BudgetAlertService._();

  StreamSubscription? _budgetSub;
  final Set<String> _alertedBudgets = {}; // Prevents duplicate alerts per budget period

  /// Initialize budget alert monitoring
  void initialize() {
    _budgetSub = RealtimeBudgetService.instance.budgetStream.listen(_checkBudgetAlerts);
    AppLogger.d('BudgetAlertService: Initialized');
  }

  /// Check if any budgets have crossed their alert thresholds
  void _checkBudgetAlerts(RealtimeSpendingData data) {
    final utilization = data.utilization;
    final threshold = data.alertThreshold;

    // Skip if no budget set
    if (data.totalBudget <= 0) return;

    // Generate a unique key for this budget period
    final budgetKey = '${data.budgetId}_${DateTime.now().month}';

    // Check if already alerted for this budget this period
    if (_alertedBudgets.contains(budgetKey)) return;

    // Check threshold
    if (utilization >= threshold) {
      _alertedBudgets.add(budgetKey);
      _triggerBudgetAlert(data, utilization);
    }

    // Also check if over budget (100%)
    if (utilization >= 1.0) {
      final overBudgetKey = '${budgetKey}_over';
      if (!_alertedBudgets.contains(overBudgetKey)) {
        _alertedBudgets.add(overBudgetKey);
        _triggerOverBudgetAlert(data);
      }
    }
  }

  /// Trigger in-app toast alert for threshold
  void _triggerBudgetAlert(RealtimeSpendingData data, double utilization) {
    final percent = (utilization * 100).toInt();

    // Show in-app toast
    Fluttertoast.showToast(
      msg: "⚠️ Budget Alert: You've used $percent% of your budget!",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 14,
    );

    AppLogger.w('BudgetAlertService: Threshold alert triggered at $percent%');
  }

  /// Trigger alert when over budget
  void _triggerOverBudgetAlert(RealtimeSpendingData data) {
    final overBy = data.totalSpent - data.totalBudget;

    // Show in-app toast
    Fluttertoast.showToast(
      msg: "🚨 Over Budget! You've exceeded by Rs ${overBy.toStringAsFixed(0)}",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 14,
    );

    AppLogger.w('BudgetAlertService: Over budget alert triggered');
  }

  /// Reset alerts for a new budget period (call when budget is updated)
  void resetAlerts() {
    _alertedBudgets.clear();
    AppLogger.d('BudgetAlertService: Alerts reset');
  }

  /// Dispose resources
  void dispose() {
    _budgetSub?.cancel();
  }
}
