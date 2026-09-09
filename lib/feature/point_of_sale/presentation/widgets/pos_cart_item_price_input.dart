import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';

/// Scoped price input field with real-time loss sale color feedback (turns red when selling below cost)
class PosCartItemPriceInput extends StatefulWidget {
  final double sellPrice;
  final double buyPrice;
  final ValueChanged<double> onPriceChanged;

  const PosCartItemPriceInput({
    super.key,
    required this.sellPrice,
    required this.buyPrice,
    required this.onPriceChanged,
  });

  @override
  State<PosCartItemPriceInput> createState() => _PosCartItemPriceInputState();
}

class _PosCartItemPriceInputState extends State<PosCartItemPriceInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatPrice(widget.sellPrice));
  }

  @override
  void didUpdateWidget(covariant PosCartItemPriceInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sellPrice != widget.sellPrice) {
      final currentTyped = double.tryParse(_controller.text.trim()) ?? 0.0;
      if (currentTyped != widget.sellPrice) {
        _controller.text = _formatPrice(widget.sellPrice);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _formatPrice(double price) {
    if (price <= 0) return '';
    return price % 1 == 0 ? price.toInt().toString() : price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final typedPrice = double.tryParse(_controller.text.trim()) ?? 0.0;
    final activePrice = _controller.text.trim().isNotEmpty
        ? typedPrice
        : widget.sellPrice;
    final isLoss =
        activePrice > 0 && widget.buyPrice > 0 && activePrice < widget.buyPrice;

    final fieldBg = isLoss
        ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
        : (isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight);

    final borderColor = isLoss ? const Color(0xFFDC2626) : Colors.transparent;
    final textColor = isLoss
        ? const Color(0xFFDC2626)
        : (isDark ? Colors.white : const Color(0xFF0F172A));
    final currencyColor = isLoss
        ? const Color(0xFFDC2626)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: isLoss ? 1.5 : 0),
      ),
      child: Row(
        children: [
          Text(
            '৳',
            style: TextStyle(
              fontSize: 13,
              color: currencyColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              onChanged: (val) {
                setState(() {});
                final parsed = double.tryParse(val.trim()) ?? 0.0;
                widget.onPriceChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
