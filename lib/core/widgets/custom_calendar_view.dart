import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

enum CalendarSelectionMode {
  single,
  range,
}

class CustomCalendarView extends StatefulWidget {
  final CalendarSelectionMode selectionMode;
  final DateTime? selectedDate;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final ValueChanged<DateTime>? onSingleDateSelected;
  final void Function(DateTime? start, DateTime? end)? onDateRangeSelected;
  final DateTime? initialDisplayedMonth;
  final bool allowFutureDates;

  const CustomCalendarView.single({
    super.key,
    this.selectedDate,
    required this.onSingleDateSelected,
    this.initialDisplayedMonth,
    this.allowFutureDates = false,
  })  : selectionMode = CalendarSelectionMode.single,
        selectedStartDate = null,
        selectedEndDate = null,
        onDateRangeSelected = null;

  const CustomCalendarView.range({
    super.key,
    this.selectedStartDate,
    this.selectedEndDate,
    required this.onDateRangeSelected,
    this.initialDisplayedMonth,
    this.allowFutureDates = false,
  })  : selectionMode = CalendarSelectionMode.range,
        selectedDate = null,
        onSingleDateSelected = null;

  @override
  State<CustomCalendarView> createState() => _CustomCalendarViewState();
}

class _CustomCalendarViewState extends State<CustomCalendarView> {
  late DateTime _displayedMonth;
  DateTime? _selectedSingleDate;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _selectedSingleDate = widget.selectedDate;
    _selectedStartDate = widget.selectedStartDate;
    _selectedEndDate = widget.selectedEndDate;

    final now = DateTime.now();
    final initialMonth = widget.initialDisplayedMonth ??
        _selectedStartDate ??
        _selectedSingleDate ??
        now;

    _displayedMonth = DateTime(initialMonth.year, initialMonth.month, 1);
  }

  @override
  void didUpdateWidget(covariant CustomCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectionMode == CalendarSelectionMode.single) {
      if (oldWidget.selectedDate != widget.selectedDate) {
        setState(() {
          _selectedSingleDate = widget.selectedDate;
          if (_selectedSingleDate != null) {
            _displayedMonth = DateTime(
              _selectedSingleDate!.year,
              _selectedSingleDate!.month,
              1,
            );
          }
        });
      }
    } else {
      if (oldWidget.selectedStartDate != widget.selectedStartDate ||
          oldWidget.selectedEndDate != widget.selectedEndDate) {
        setState(() {
          _selectedStartDate = widget.selectedStartDate;
          _selectedEndDate = widget.selectedEndDate;
          if (_selectedStartDate != null) {
            _displayedMonth = DateTime(
              _selectedStartDate!.year,
              _selectedStartDate!.month,
              1,
            );
          }
        });
      }
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
    final now = DateTime.now();
    if (!widget.allowFutureDates &&
        (_displayedMonth.year > now.year ||
            (_displayedMonth.year == now.year &&
                _displayedMonth.month >= now.month))) {
      return;
    }
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  Future<void> _showMonthYearPicker() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    int tempYear = _displayedMonth.year;
    int tempMonth = _displayedMonth.month;

    final primaryBlue = AppColors.primaryButton(context);

    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool canIncreaseYear =
                widget.allowFutureDates || tempYear < now.year;

            return Dialog(
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year selector with steppers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              tempYear--;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
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
                        Text(
                          '$tempYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        InkWell(
                          onTap: canIncreaseYear
                              ? () {
                                  setDialogState(() {
                                    tempYear++;
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: canIncreaseYear
                                  ? primaryBlue
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: canIncreaseYear
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8)),
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 12 Months Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemBuilder: (context, index) {
                        final monthIndex = index + 1;
                        final isSelected = monthIndex == tempMonth;
                        final monthName = DateFormat('MMM').format(
                          DateTime(tempYear, monthIndex, 1),
                        );

                        final isFutureMonth = !widget.allowFutureDates &&
                            (tempYear > now.year ||
                                (tempYear == now.year &&
                                    monthIndex > now.month));

                        Color tileBg;
                        Color textColor;

                        if (isSelected) {
                          tileBg = primaryBlue;
                          textColor = Colors.white;
                        } else if (isFutureMonth) {
                          tileBg = isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC);
                          textColor = isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1);
                        } else {
                          tileBg = isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9);
                          textColor =
                              isDark ? Colors.white : const Color(0xFF0F172A);
                        }

                        return InkWell(
                          onTap: isFutureMonth
                              ? null
                              : () {
                                  setDialogState(() {
                                    tempMonth = monthIndex;
                                  });
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tileBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              monthName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(
                              ctx,
                              DateTime(tempYear, tempMonth, 1),
                            );
                          },
                          child: const Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _displayedMonth = result;
      });
    }
  }

  void _onDateTapped(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (!widget.allowFutureDates && target.isAfter(today)) {
      return; // Disallow picking future dates
    }

    if (widget.selectionMode == CalendarSelectionMode.single) {
      setState(() {
        _selectedSingleDate = date;
      });
      widget.onSingleDateSelected?.call(date);
    } else {
      setState(() {
        if (_selectedStartDate == null ||
            (_selectedStartDate != null && _selectedEndDate != null)) {
          _selectedStartDate = date;
          _selectedEndDate = null;
        } else if (_selectedStartDate != null && _selectedEndDate == null) {
          if (date.isBefore(_selectedStartDate!)) {
            _selectedStartDate = date;
            _selectedEndDate = null;
          } else {
            _selectedEndDate = date;
          }
        }
      });
      widget.onDateRangeSelected?.call(_selectedStartDate, _selectedEndDate);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime date) {
    if (widget.selectionMode != CalendarSelectionMode.range) return false;
    if (_selectedStartDate == null || _selectedEndDate == null) return false;
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      _selectedStartDate!.year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
    );
    final end = DateTime(
      _selectedEndDate!.year,
      _selectedEndDate!.month,
      _selectedEndDate!.day,
    );
    return normalized.isAfter(start) && normalized.isBefore(end);
  }

  bool _isSelected(DateTime date) {
    if (widget.selectionMode == CalendarSelectionMode.single) {
      return _selectedSingleDate != null &&
          _isSameDay(date, _selectedSingleDate!);
    } else {
      final isStart =
          _selectedStartDate != null && _isSameDay(date, _selectedStartDate!);
      final isEnd =
          _selectedEndDate != null && _isSameDay(date, _selectedEndDate!);
      return isStart || isEnd;
    }
  }

  String _formatTwoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final primaryBlue = AppColors.primaryButton(context);
    final selectedBorderColor = primaryBlue;
    final selectedBgColor = primaryBlue.withValues(alpha: 0.14);

    final firstDayOfMonth = _displayedMonth;
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final previousMonthDays =
        DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;

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

    final activeDateForPill =
        widget.selectionMode == CalendarSelectionMode.single
            ? (_selectedSingleDate ?? now)
            : (_selectedStartDate ?? now);

    final formattedSelectedPill =
        DateFormat('MM/dd/yyyy').format(activeDateForPill);

    final bool canNavigateNextMonth = widget.allowFutureDates ||
        !(_displayedMonth.year > now.year ||
            (_displayedMonth.year == now.year &&
                _displayedMonth.month >= now.month));

    return Column(
      mainAxisSize: MainAxisSize.min,
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

            // Date Dropdown / Indicator Pill (Clickable)
            InkWell(
              onTap: _showMonthYearPicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
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
              onTap: canNavigateNextMonth ? _nextMonth : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: canNavigateNextMonth
                      ? primaryBlue
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: canNavigateNextMonth
                      ? Colors.white
                      : (isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8)),
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
            final isFuture = !widget.allowFutureDates &&
                DateTime(date.year, date.month, date.day).isAfter(today);

            final isSelected = _isSelected(date);
            final inRange = _isInRange(date);

            Color textColor;
            if (isSelected) {
              textColor = isDark ? Colors.white : AppColors.primaryButton(context);
            } else if (isFuture) {
              textColor =
                  isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
            } else if (!isCurrentMonth) {
              textColor =
                  isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
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
              onTap: isFuture ? null : () => _onDateTapped(date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: decoration,
                child: Text(
                  _formatTwoDigits(day),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: (isSelected || (isCurrentMonth && !isFuture))
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
