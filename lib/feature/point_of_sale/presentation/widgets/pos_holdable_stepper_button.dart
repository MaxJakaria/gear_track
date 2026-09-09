import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';

/// Holdable Stepper Button supporting continuous auto-increment / auto-decrement on long press / hold
class PosHoldableStepperButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onStep;
  final bool enabled;
  final String tooltip;

  const PosHoldableStepperButton({
    super.key,
    required this.icon,
    required this.onStep,
    this.enabled = true,
    this.tooltip = '',
  });

  @override
  State<PosHoldableStepperButton> createState() =>
      _PosHoldableStepperButtonState();
}

class _PosHoldableStepperButtonState extends State<PosHoldableStepperButton> {
  Timer? _initialDelayTimer;
  Timer? _periodicTimer;
  bool _isPressed = false;

  void _startHolding() {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    widget.onStep();

    _initialDelayTimer?.cancel();
    _periodicTimer?.cancel();
    _initialDelayTimer = Timer(const Duration(milliseconds: 300), () {
      _periodicTimer = Timer.periodic(const Duration(milliseconds: 75), (_) {
        if (!widget.enabled || !mounted) {
          _stopHolding();
          return;
        }
        widget.onStep();
      });
    });
  }

  void _stopHolding() {
    _initialDelayTimer?.cancel();
    _periodicTimer?.cancel();
    _initialDelayTimer = null;
    _periodicTimer = null;
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  void didUpdateWidget(covariant PosHoldableStepperButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isPressed) {
      _stopHolding();
    }
  }

  @override
  void dispose() {
    _stopHolding();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.enabled
        ? (_isPressed
            ? (isDark
                ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                : const Color(0xFF4F46E5).withValues(alpha: 0.15))
            : (isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLight))
        : (isDark
            ? AppColors.surfaceContainerDark.withValues(alpha: 0.4)
            : AppColors.surfaceContainerLight.withValues(alpha: 0.4));

    final iconColor = widget.enabled
        ? (_isPressed
            ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
            : (isDark ? Colors.white : const Color(0xFF0F172A)))
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return Tooltip(
      message: widget.tooltip,
      triggerMode: TooltipTriggerMode.manual,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _startHolding(),
        onPointerUp: (_) => _stopHolding(),
        onPointerCancel: (_) => _stopHolding(),
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}
