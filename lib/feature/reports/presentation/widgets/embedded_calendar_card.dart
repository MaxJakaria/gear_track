import 'package:flutter/material.dart';
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
  late DateTime _displayedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _loadingAction; // 'apply' or 'reset'

  @override
  void initState() {
    super.initState();
    _startDate = widget.selectedStartDate;
    _endDate = widget.selectedEndDate;
    final now = DateTime.now();
    _displayedMonth = DateTime(
      (_startDate ?? now).year,
      (_startDate ?? now).month,
      1,
    );
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
        if (_startDate != null) {
          _displayedMonth = DateTime(_startDate!.year, _startDate!.month, 1);
        }
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start fresh selection
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (date.isBefore(_startDate!)) {
          _startDate = date;
          _endDate = null;
        } else {
          _endDate = date;
        }
      }
    });
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null || _endDate == null) return false;
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return normalized.isAfter(start) && normalized.isBefore(end);
  }

  bool _isStartDate(DateTime date) {
    return _startDate != null && _isSameDay(date, _startDate!);
  }

  bool _isEndDate(DateTime date) {
    return _endDate != null && _isSameDay(date, _endDate!);
  }

  String _formatTwoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final selectedBorderColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF3B82F6);
    final selectedBgColor =
        (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withValues(
          alpha: 0.14,
        );

    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.white;

    final firstDayOfMonth = _displayedMonth;
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final previousMonthDays = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      0,
    ).day;

    final int startWeekday = firstDayOfMonth.weekday % 7;

    final List<Map<String, dynamic>> gridCells = [];

    // 1. Previous month trailing days
    for (int i = startWeekday - 1; i >= 0; i--) {
      final dayNum = previousMonthDays - i;
      final date = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        dayNum,
      );
      gridCells.add({'date': date, 'day': dayNum, 'isCurrentMonth': false});
    }

    // 2. Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, i);
      gridCells.add({'date': date, 'day': i, 'isCurrentMonth': true});
    }

    // 3. Next month leading days
    final remainingCells = (7 - (gridCells.length % 7)) % 7;
    for (int i = 1; i <= remainingCells; i++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month + 1, i);
      gridCells.add({'date': date, 'day': i, 'isCurrentMonth': false});
    }

    final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    final hasSelection = _startDate != null;

    final formattedSelectedPill = hasSelection
        ? DateFormat('MM/dd/yyyy').format(_startDate!)
        : DateFormat('MM/dd/yyyy').format(DateTime.now());

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
          // Header Row: Month Name + Date Capsule + Navigation Controls
          Row(
            children: [
              // Month & Year Text
              Text(
                DateFormat('MMM yyyy').format(_displayedMonth),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),

              // Date Dropdown / Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedSelectedPill,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Left Arrow Button
              InkWell(
                onTap: _previousMonth,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Right Arrow Button
              InkWell(
                onTap: _nextMonth,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 10),

          // Weekdays Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return SizedBox(
                width: 36,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridCells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final cell = gridCells[index];
              final date = cell['date'] as DateTime;
              final day = cell['day'] as int;
              final isCurrentMonth = cell['isCurrentMonth'] as bool;

              final isStart = _isStartDate(date);
              final isEnd = _isEndDate(date);
              final inRange = _isInRange(date);
              final isSelected = isStart || isEnd;

              Color textColor;
              if (isSelected) {
                textColor = isDark ? Colors.white : const Color(0xFF2563EB);
              } else if (!isCurrentMonth) {
                textColor = isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFF94A3B8);
              } else if (inRange) {
                textColor = isDark ? Colors.white : const Color(0xFF1E40AF);
              } else {
                textColor = isDark ? Colors.white : const Color(0xFF0F172A);
              }

              BoxDecoration decoration;
              if (isSelected) {
                decoration = BoxDecoration(
                  color: selectedBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selectedBorderColor, width: 1.6),
                );
              } else if (inRange) {
                decoration = BoxDecoration(
                  color: selectedBorderColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                );
              } else {
                decoration = const BoxDecoration();
              }

              return InkWell(
                onTap: () => _onDateTapped(date),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: decoration,
                  child: Text(
                    _formatTwoDigits(day),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: (isSelected || isCurrentMonth)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              );
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
