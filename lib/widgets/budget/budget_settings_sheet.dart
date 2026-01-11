import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/models/budget/budget_goal_model.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Bottom sheet for setting or editing a budget goal.
class BudgetSettingsSheet extends StatefulWidget {
  const BudgetSettingsSheet({
    super.key,
    this.existingGoal,
    this.initialType = BudgetGoalType.global,
    this.targetId,
    this.targetName,
    this.suggestedAmount,
  });

  /// Existing goal to edit (null for new goal)
  final BudgetGoal? existingGoal;

  /// Initial budget type for new goals
  final BudgetGoalType initialType;

  /// Target ID (listId, category, etc.) for non-global budgets
  final String? targetId;

  /// Display name for the target
  final String? targetName;

  /// Suggested amount (from insights)
  final double? suggestedAmount;

  static Future<BudgetGoal?> show(
    BuildContext context, {
    BudgetGoal? existingGoal,
    BudgetGoalType initialType = BudgetGoalType.global,
    String? targetId,
    String? targetName,
    double? suggestedAmount,
  }) {
    return showModalBottomSheet<BudgetGoal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetSettingsSheet(
        existingGoal: existingGoal,
        initialType: initialType,
        targetId: targetId,
        targetName: targetName,
        suggestedAmount: suggestedAmount,
      ),
    );
  }

  @override
  State<BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends State<BudgetSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late BudgetGoalType _selectedType;
  late BudgetCadence _selectedCadence;
  double _alertThreshold = 0.8;
  bool _isLoading = false;

  bool get isEditing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      _selectedType = widget.existingGoal!.type;
      _selectedCadence = widget.existingGoal!.cadence;
      _amountController.text = widget.existingGoal!.amount.toStringAsFixed(0);
      _notesController.text = widget.existingGoal!.notes ?? '';
      _alertThreshold = widget.existingGoal!.alertThreshold;
    } else {
      _selectedType = widget.initialType;
      _selectedCadence = BudgetCadence.monthly;
      if (widget.suggestedAmount != null) {
        _amountController.text = widget.suggestedAmount!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return LiquidGlass(
      enableBlur: true,
      blurSigmaX: 12,
      blurSigmaY: 20,
      borderRadius: 24,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomPadding + 24,
      ),
      gradientColors: [
        const Color(0xFF1F2937).withValues(alpha: 0.95),
        const Color(0xFF111827).withValues(alpha: 0.98),
      ],
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildTypeSelector(theme),
              const SizedBox(height: 20),
              _buildAmountField(theme),
              const SizedBox(height: 20),
              _buildCadenceSelector(theme),
              const SizedBox(height: 20),
              _buildAlertThresholdSlider(theme),
              const SizedBox(height: 20),
              _buildNotesField(theme),
              const SizedBox(height: 24),
              _buildActionButtons(theme),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.add_chart_rounded,
            color: AppColors.primaryGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Budget' : 'Set Budget',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (widget.targetName != null)
                Text(
                  widget.targetName!,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    if (widget.targetId != null) {
      // Type is fixed for targeted budgets
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Type',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BudgetGoalType.values.map((type) {
            final isSelected = type == _selectedType;
            return ChoiceChip(
              label: Text(_typeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = type);
                }
              },
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: GoogleFonts.lato(
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryGreen.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Amount',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        LiquidTextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          prefixText: 'Rs ',
          hintText: '0.00',
        ),
        if (widget.suggestedAmount != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                _amountController.text = widget.suggestedAmount!.toStringAsFixed(0);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: Colors.amber[400],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Suggested: Rs ${widget.suggestedAmount!.toStringAsFixed(0)}',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.amber[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCadenceSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Period',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<BudgetCadence>(
          segments: const [
            ButtonSegment(
              value: BudgetCadence.weekly,
              label: Text('Weekly'),
              icon: Icon(Icons.calendar_view_week_rounded, size: 18),
            ),
            ButtonSegment(
              value: BudgetCadence.monthly,
              label: Text('Monthly'),
              icon: Icon(Icons.calendar_month_rounded, size: 18),
            ),
            ButtonSegment(
              value: BudgetCadence.oneTime,
              label: Text('One-time'),
              icon: Icon(Icons.event_rounded, size: 18),
            ),
          ],
          selected: {_selectedCadence},
          onSelectionChanged: (selected) {
            setState(() => _selectedCadence = selected.first);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryGreen.withValues(alpha: 0.2);
              }
              return Colors.white.withValues(alpha: 0.05);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryGreen;
              }
              return Colors.white70;
            }),
            side: WidgetStateProperty.all(BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertThresholdSlider(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alert Threshold',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            Text(
              '${(_alertThreshold * 100).toInt()}%',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryGreen,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: AppColors.primaryGreen,
            overlayColor: AppColors.primaryGreen.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: _alertThreshold,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() => _alertThreshold = value);
            },
          ),
        ),
        Text(
          'Get alerted when you reach ${(_alertThreshold * 100).toInt()}% of your budget',
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (optional)',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        LiquidTextField(
          controller: _notesController,
          maxLines: 2,
          hintText: 'Add a note...',
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        if (isEditing) ...[
          Expanded(
            child: LiquidGlassButton.text(
              onTap: _isLoading ? null : _deleteBudget,
              icon: Icons.delete_outline_rounded,
              text: 'Delete',
              isDestructive: true,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: isEditing ? 1 : 2,
          child: LiquidGlassGradientButton(
            onTap: _isLoading ? null : _saveBudget,
            gradientColors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
            padding: const EdgeInsets.symmetric(vertical: 14),
            customChild: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Update' : 'Create Budget',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final amount = double.parse(_amountController.text);
      final now = DateTime.now();

      final goal = BudgetGoal(
        id: widget.existingGoal?.id ?? '',
        userId: userId,
        type: _selectedType,
        targetId: widget.targetId ?? widget.existingGoal?.targetId,
        targetName: widget.targetName ?? widget.existingGoal?.targetName,
        amount: amount,
        cadence: _selectedCadence,
        alertThreshold: _alertThreshold,
        isActive: true,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        anchorDate: widget.existingGoal?.anchorDate ?? now,
        createdAt: widget.existingGoal?.createdAt ?? now,
      );

      final firestore = FirebaseFirestore.instance;
      final collection = firestore
          .collection('users')
          .doc(userId)
          .collection('budget_goals');

      if (isEditing) {
        await collection.doc(goal.id).update(goal.toFirestore());
        Fluttertoast.showToast(
          msg: "Budget updated successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        await collection.add(goal.toFirestore());
        Fluttertoast.showToast(
          msg: "Budget created! You'll be alerted at ${(_alertThreshold * 100).toInt()}% usage.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }

      if (mounted) {
        Navigator.pop(context, goal);
      }
    } catch (e) {
      AppLogger.e('BudgetSettingsSheet: Failed to save budget', error: e);
      Fluttertoast.showToast(
        msg: "Failed to save budget. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBudget() async {
    if (widget.existingGoal == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          LiquidGlassButton.text(
            onTap: () => Navigator.pop(context, false),
            text: 'Cancel',
          ),
          LiquidGlassButton.text(
            onTap: () => Navigator.pop(context, true),
            text: 'Delete',
            isDestructive: true,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('budget_goals')
          .doc(widget.existingGoal!.id)
          .delete();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('BudgetSettingsSheet: Failed to delete budget', error: e);
      if (mounted) {
        LiquidSnack.error(
          title: 'Error',
          message: 'Failed to delete budget: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _typeLabel(BudgetGoalType type) {
    switch (type) {
      case BudgetGoalType.global:
        return 'Overall';
      case BudgetGoalType.list:
        return 'List';
      case BudgetGoalType.category:
        return 'Category';
      case BudgetGoalType.item:
        return 'Item';
    }
  }
}
