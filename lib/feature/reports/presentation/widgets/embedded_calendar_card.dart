import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/widgets/custom_calendar_view.dart';
import 'package:intl/intl.dart';

class EmbeddedCalendarCard extends StatefulWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final Function(DateTime? start, DateTime? end) onDateRangeChanged;
  final bool isLoading;

  const EmbeddedCalendarCard({
    super.key,
    this.selectedStartDate,
    this.selectedEndDate,
    required this.onDateRangeChanged,
    this.isLoading = false,
  });

  @override
  State<EmbeddedCalendarCard> createState() => _EmbeddedCalendarCardState();
}

class _EmbeddedCalendarCardState extends State<EmbeddedCalendarCard> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _loadingAction; // 'apply' or 'reset'
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.selectedStartDate;
    _endDate = widget.selectedEndDate;
  }

  @override
  void didUpdateWidget(covariant EmbeddedCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && _isLocalLoading) {
      setState(() {
        _isLocalLoading = false;
        _loadingAction = null;
      });
    }
    if (oldWidget.selectedStartDate != widget.selectedStartDate ||
        oldWidget.selectedEndDate != widget.selectedEndDate) {
      setState(() {
        _startDate = widget.selectedStartDate;
        _endDate = widget.selectedEndDate;
        _isLocalLoading = false;
        _loadingAction = null;
      });
    }
  }

  void _applySelection() {
    if (_startDate != null) {
      setState(() {
        _loadingAction = 'apply';
        _isLocalLoading = true;
      });
      widget.onDateRangeChanged(_startDate, _endDate ?? _startDate);
    }
  }

  void _clearSelection() {
    setState(() {
      _loadingAction = 'reset';
      _isLocalLoading = true;
      _startDate = null;
      _endDate = null;
    });
    widget.onDateRangeChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = AppColors.primaryButton(context);
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final hasSelection = _startDate != null;
    final bool isResetLoading =
        (widget.isLoading || _isLocalLoading) && _loadingAction == 'reset';
    final bool isApplyLoading =
        (widget.isLoading || _isLocalLoading) && _loadingAction == 'apply';
    final bool isBusy = isResetLoading || isApplyLoading;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reusable Core Calendar View
          CustomCalendarView.range(
            selectedStartDate: _startDate,
            selectedEndDate: _endDate,
            onDateRangeSelected: (start, end) {
              setState(() {
                _startDate = start;
                _endDate = end;
              });
            },
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 0.8,
            color: borderColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),

          // Footer Row: Selection Summary + Reset Button + Apply Button
          Row(
            children: [
              Expanded(
                child: Text(
                  (_startDate != null && _endDate != null)
                      ? ((_startDate!.year == _endDate!.year &&
                                  _startDate!.month == _endDate!.month &&
                                  _startDate!.day == _endDate!.day)
                              ? DateFormat('MMM d, yyyy').format(_startDate!)
                              : '${DateFormat('MMM d').format(_startDate!)} – ${DateFormat('MMM d, yyyy').format(_endDate!)}')
                      : (_startDate != null
                            ? DateFormat('MMM d, yyyy').format(_startDate!)
                            : 'All Time Overview'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (hasSelection || widget.selectedStartDate != null) ...[
                TextButton(
                  onPressed: widget.isLoading ? null : _clearSelection,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(48, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isResetLoading
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF4F46E5),
                          ),
                        )
                      : Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                height: 34,
                decoration: BoxDecoration(
                  gradient: (hasSelection && !isBusy)
                      ? AppColors.primaryGradient(context)
                      : null,
                  color: (hasSelection && !isBusy)
                      ? null
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: (hasSelection && !isBusy)
                      ? [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.30),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: (hasSelection && !isBusy) ? _applySelection : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: isApplyLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: (hasSelection && !isBusy)
                                      ? Colors.white
                                      : (isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8)),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
