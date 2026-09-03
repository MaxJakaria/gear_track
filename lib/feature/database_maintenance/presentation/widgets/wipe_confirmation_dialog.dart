import 'package:flutter/material.dart';

/// High-Security Factory Wipe Challenge Dialog
class WipeConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirmed;

  const WipeConfirmationDialog({super.key, required this.onConfirmed});

  @override
  State<WipeConfirmationDialog> createState() => _WipeConfirmationDialogState();
}

class _WipeConfirmationDialogState extends State<WipeConfirmationDialog> {
  late final TextEditingController _inputController;
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _inputController.addListener(_validateInput);
  }

  void _validateInput() {
    final isValid = _inputController.text.trim() == 'RESET';
    if (isValid != _canConfirm) {
      setState(() => _canConfirm = isValid);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const dangerRed = Color(0xFFEF4444);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: dangerRed.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.delete_forever_rounded,
                color: dangerRed,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Permanent Factory Reset',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is irreversible. All inventory, sales, returns, settings, and ledger history will be permanently erased.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      children: const [
                        TextSpan(text: 'Type '),
                        TextSpan(
                          text: 'RESET',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: dangerRed,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextSpan(text: ' below to confirm:'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type RESET',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 0,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: dangerRed,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: dangerRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _canConfirm
              ? () {
                  Navigator.pop(context);
                  widget.onConfirmed();
                }
              : null,
          child: const Text(
            'Confirm Wipe',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
