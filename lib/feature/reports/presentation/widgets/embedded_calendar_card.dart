import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _startDate = widget.selectedStartDate;
    _endDate = widget.selectedEndDate;
  }

  @override
  void didUpdateWidget(covariant EmbeddedCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading) {
      _loadingAction = null;
    }
    if (oldWidget.selectedStartDate != widget.selectedStartDate ||
        oldWidget.selectedEndDate != widget.selectedEndDate) {
      setState(() {
        _startDate = widget.selectedStartDate;
        _endDate = widget.selectedEndDate;
      });
    }
  }

  void _applySelection() {
    if (_startDate != null) {
      setState(() {
        _loadingAction = 'apply';
      });
      widget.onDateRangeChanged(_startDate, _endDate ?? _startDate);
    }
  }

  void _clearSelection() {
    setState(() {
      _loadingAction = 'reset';
      _startDate = null;
      _endDate = null;
    });
    widget.onDateRangeChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.white;

    final hasSelection = _startDate != null;
    final bool isResetLoading = widget.isLoading && _loadingAction == 'reset';
    final bool isApplyLoading = widget.isLoading && _loadingAction == 'apply';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
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
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 10),

          // Footer Row: Selection Summary + Reset Button + Apply Button
          Row(
            children: [
              Expanded(
                child: Text(
                  (_startDate != null && _endDate != null)
                      ? '${DateFormat('MMM d').format(_startDate!)} – ${DateFormat('MMM d, yyyy').format(_endDate!)}'
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(64, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: (hasSelection && !widget.isLoading)
                    ? _applySelection
                    : null,
                child: isApplyLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
