import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';

class VerificationManualInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onVerify;

  const VerificationManualInput({
    super.key,
    required this.controller,
    required this.onVerify,
  });

  @override
  State<VerificationManualInput> createState() => _VerificationManualInputState();
}

class _VerificationManualInputState extends State<VerificationManualInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.7)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt / Invoice ID',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter or paste the code printed on the receipt',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Clean Minimal Input Field
          TextField(
            controller: widget.controller,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'e.g. INV-POS01-20260903-0001',
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                letterSpacing: 0,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      onPressed: () => widget.controller.clear(),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        final clip = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (clip?.text != null &&
                            clip!.text!.trim().isNotEmpty) {
                          widget.controller.text = clip.text!.trim();
                        }
                      },
                      child: Text(
                        'Paste',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                widget.onVerify(val.trim());
              }
            },
          ),
          const SizedBox(height: 16),

          // Minimalist Verify Action
          AppGradientButton(
            label: 'Verify Receipt',
            onPressed: hasText
                ? () => widget.onVerify(widget.controller.text.trim())
                : null,
          ),
        ],
      ),
    );
  }
}
