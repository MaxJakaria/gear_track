import 'package:flutter/material.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/init_dependencies.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/domain/usecases/save_cost_code_mapping.dart';

class CostCodeSettingsSheet extends StatefulWidget {
  const CostCodeSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CostCodeSettingsSheet(),
    );
  }

  @override
  State<CostCodeSettingsSheet> createState() => _CostCodeSettingsSheetState();
}

class _CostCodeSettingsSheetState extends State<CostCodeSettingsSheet> {
  final Map<int, TextEditingController> _digitControllers = {};
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _testCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _decodedPreview = '৳0';

  // Standard 10 digits order for display: 1..9, 0
  final List<int> _digits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];

  @override
  void initState() {
    super.initState();
    for (final d in _digits) {
      _digitControllers[d] = TextEditingController();
    }
    _loadMapping();
  }

  @override
  void dispose() {
    for (final c in _digitControllers.values) {
      c.dispose();
    }
    _keywordController.dispose();
    _testCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadMapping() async {
    setState(() => _isLoading = true);
    final getMapping = serviceLocator<GetCostCodeMapping>();
    final result = await getMapping();

    if (mounted) {
      result.fold(
        (failure) {
          final def = CostCodeMapping.defaultMapping();
          _populateFromMapping(def);
        },
        (mapping) {
          _populateFromMapping(mapping);
        },
      );
      setState(() => _isLoading = false);
      _updateLivePreview();
    }
  }

  void _populateFromMapping(CostCodeMapping mapping) {
    for (final d in _digits) {
      _digitControllers[d]?.text = mapping.getCharForDigit(d);
    }
  }

  void _applyKeyword(String keyword) {
    final clean = keyword.trim().replaceAll(RegExp(r'\s+'), '');
    for (int i = 0; i < clean.length && i < 10; i++) {
      final digit = (i + 1) % 10; // 0th -> 1, 1st -> 2 ... 9th -> 0
      _digitControllers[digit]?.text = clean[i].toUpperCase();
    }
    _updateLivePreview();
  }

  CostCodeMapping _buildCurrentMapping() {
    final map = <String, int>{};
    for (final d in _digits) {
      final text = _digitControllers[d]?.text.trim().toUpperCase() ?? '';
      if (text.isNotEmpty) {
        map[text[0]] = d;
      }
    }
    return CostCodeMapping(charToDigit: map);
  }

  void _updateLivePreview() {
    final mapping = _buildCurrentMapping();
    final testInput = _testCodeController.text.trim();
    if (testInput.isEmpty) {
      setState(() => _decodedPreview = '৳0');
      return;
    }
    final val = mapping.decode(testInput);
    setState(() {
      _decodedPreview = val % 1 == 0
          ? '৳${val.toInt()}'
          : '৳${val.toStringAsFixed(1)}';
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final mapping = _buildCurrentMapping();
    final saveMapping = serviceLocator<SaveCostCodeMapping>();
    final result = await saveMapping(mapping);

    if (mounted) {
      setState(() => _isSaving = false);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cost Code mapping saved successfully!'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 12,
          left: 20,
          right: 20,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.vpn_key_rounded,
                              size: 20,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cost Code Settings',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Map characters to digits 0–9',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick 10-Letter Keyword Input
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Quick Keyword Auto-Fill (10 Letters)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _keywordController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'e.g. BLACKSMITH',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val.trim().length >= 10) {
                                    _applyKeyword(val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (_keywordController.text.trim().isNotEmpty) {
                                  _applyKeyword(_keywordController.text);
                                }
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Digit to Character Grid (1..9, 0)
                  Text(
                    'DIGIT MAPPING (0–9)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.05,
                        ),
                    itemCount: _digits.length,
                    itemBuilder: (context, index) {
                      final digit = _digits[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$digit',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Expanded(
                              child: TextField(
                                controller: _digitControllers[digit],
                                textAlign: TextAlign.center,
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => _updateLivePreview(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Live Test / Decoder Preview Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF059669,
                      ).withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Test Cost Code',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _testCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'Type code (e.g. BAT)',
                                  hintStyle: TextStyle(fontSize: 13),
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => _updateLivePreview(),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'DECODED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _decodedPreview,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Action Button
                  AppGradientButton(
                    onPressed: _isSaving ? null : _save,
                    isLoading: _isSaving,
                    label: 'Save Cost Code',
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
