import 'package:flutter/material.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/domain/usecases/save_cost_code_mapping.dart';
import 'package:gear_track/core/domain/usecases/save_shop_settings.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/init_dependencies.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SettingsPage());
  }

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Store Profile Controllers
  late final TextEditingController _shopNameController;
  late final TextEditingController _shopAddressController;
  late final TextEditingController _shopPhoneController;

  // Cost Code Cipher Controllers
  late final TextEditingController _keywordController;
  late final TextEditingController _testCodeController;
  final Map<int, TextEditingController> _digitControllers = {};
  final Map<int, FocusNode> _digitFocusNodes = {};

  final List<int> _digits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];

  bool _isLoading = true;
  bool _isSaving = false;
  String _decodedPreview = '৳0';

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _shopAddressController = TextEditingController();
    _shopPhoneController = TextEditingController();
    _keywordController = TextEditingController();
    _testCodeController = TextEditingController();

    for (final d in _digits) {
      _digitControllers[d] = TextEditingController();
      _digitFocusNodes[d] = FocusNode();
    }

    _loadData();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _keywordController.dispose();
    _testCodeController.dispose();

    for (final c in _digitControllers.values) {
      c.dispose();
    }
    for (final f in _digitFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final getMapping = serviceLocator<GetCostCodeMapping>();
    final getShop = serviceLocator<GetShopSettings>();

    final results = await Future.wait([getMapping(), getShop()]);

    if (mounted) {
      // 1. Cost code mapping
      results[0].fold(
        (_) => _populateFromMapping(const CostCodeMapping(charToDigit: {})),
        (mapping) => _populateFromMapping(mapping as CostCodeMapping),
      );

      // 2. Shop settings
      results[1].fold(
        (_) {
          _shopNameController.clear();
          _shopAddressController.clear();
          _shopPhoneController.clear();
        },
        (shop) {
          final s = shop as ShopSettings;
          _shopNameController.text = s.shopName;
          _shopAddressController.text = s.address;
          _shopPhoneController.text = s.phone;
        },
      );

      setState(() => _isLoading = false);
      _updateLivePreview();
    }
  }

  void _populateFromMapping(CostCodeMapping mapping) {
    for (final d in _digits) {
      _digitControllers[d]?.text = mapping.getCharsForDigit(d, separator: ', ');
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
      final text = _digitControllers[d]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        // Strip commas, slashes, and spaces to extract all mapped character aliases
        final cleanChars = text.replaceAll(RegExp(r'[,/\s]+'), '');
        for (int i = 0; i < cleanChars.length; i++) {
          final ch = cleanChars[i].toUpperCase();
          map[ch] = d;
        }
      }
    }
    return CostCodeMapping(charToDigit: map);
  }

  ShopSettings _buildCurrentShopSettings() {
    return ShopSettings(
      shopName: _shopNameController.text.trim(),
      address: _shopAddressController.text.trim(),
      phone: _shopPhoneController.text.trim(),
    );
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

  void _openDigitEditSheet(int digit) {
    final currentText = _digitControllers[digit]?.text.trim() ?? '';
    final cleanChars = currentText.replaceAll(RegExp(r'[,/\s]+'), '');
    final List<String> tempChars = [];
    for (int i = 0; i < cleanChars.length; i++) {
      final ch = cleanChars[i].toUpperCase();
      if (!tempChars.contains(ch)) {
        tempChars.add(ch);
      }
    }

    final TextEditingController charInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final inputBg = isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF1F5F9);

            int? findDigitForChar(String char) {
              final upper = char.toUpperCase();
              for (final otherDigit in _digits) {
                if (otherDigit == digit) continue;
                final otherText =
                    _digitControllers[otherDigit]?.text.trim() ?? '';
                final otherClean = otherText.replaceAll(RegExp(r'[,/\s]+'), '');
                for (int i = 0; i < otherClean.length; i++) {
                  if (otherClean[i].toUpperCase() == upper) {
                    return otherDigit;
                  }
                }
              }
              return null;
            }

            void addChar(String char) {
              final clean = char.trim().toUpperCase();
              if (clean.isEmpty) return;
              for (int i = 0; i < clean.length; i++) {
                final c = clean[i];
                final existingDigit = findDigitForChar(c);
                if (existingDigit != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "'$c' is already assigned to Digit $existingDigit! Remove it from Digit $existingDigit first.",
                      ),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  continue;
                }
                if (!tempChars.contains(c)) {
                  tempChars.add(c);
                }
              }
              charInputController.clear();
              setModalState(() {});
            }

            void removeChar(String char) {
              tempChars.remove(char);
              setModalState(() {});
            }

            const quickSymbols = [
              '@',
              '#',
              r'$',
              '!',
              '*',
              '%',
              '&',
              '+',
              '-',
              '?',
            ];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Digit $digit',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Symbols for $digit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'All listed characters decode to numeric $digit',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Active Characters
                    Text(
                      'ACTIVE CHARACTERS & SYMBOLS:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tempChars.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'No characters mapped yet. Add one below!',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tempChars.map((ch) {
                          return Container(
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.35),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ch,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$digit',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => removeChar(ch),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 18),

                    // Quick Add Common Symbols
                    Text(
                      'QUICK ADD SYMBOLS (TAP TO ADD):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickSymbols.map((sym) {
                        final alreadyAdded = tempChars.contains(sym);
                        final assignedOther = findDigitForChar(sym);
                        final isUsedElsewhere = assignedOther != null;

                        return InkWell(
                          onTap: alreadyAdded
                              ? null
                              : () {
                                  if (isUsedElsewhere) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Symbol '$sym' is already assigned to Digit $assignedOther!",
                                        ),
                                        backgroundColor: const Color(
                                          0xFFDC2626,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  addChar(sym);
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: alreadyAdded
                                  ? const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.15)
                                  : isUsedElsewhere
                                  ? (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.04))
                                  : inputBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: alreadyAdded
                                    ? const Color(0xFF6366F1)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isUsedElsewhere ? '$sym ($assignedOther)' : sym,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: alreadyAdded
                                    ? const Color(0xFF6366F1)
                                    : isUsedElsewhere
                                    ? (isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8))
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Custom input row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: charInputController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Type any letter or symbol (e.g. A)',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (val) => addChar(val),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => addChar(charInputController.text),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons (Cancel / Done)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AppGradientButton(
                            label: 'Done',
                            onPressed: () {
                              setState(() {
                                _digitControllers[digit]?.text = tempChars.join(
                                  ', ',
                                );
                                _updateLivePreview();
                              });
                              Navigator.pop(ctx);
                            },
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
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all mandatory shop information fields.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that no duplicate character is mapped across different digits
    final seenChars = <String, int>{};
    for (final d in _digits) {
      final text = _digitControllers[d]?.text.trim() ?? '';
      final clean = text.replaceAll(RegExp(r'[,/\s]+'), '');
      for (int i = 0; i < clean.length; i++) {
        final c = clean[i].toUpperCase();
        if (seenChars.containsKey(c)) {
          final prevDigit = seenChars[c];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Duplicate character '$c' used in Digit $prevDigit and Digit $d. Each character must be unique!",
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        seenChars[c] = d;
      }
    }

    setState(() => _isSaving = true);
    final mapping = _buildCurrentMapping();
    final shopSettings = _buildCurrentShopSettings();

    final saveMapping = serviceLocator<SaveCostCodeMapping>();
    final saveShop = serviceLocator<SaveShopSettings>();

    final results = await Future.wait([
      saveMapping(mapping),
      saveShop(shopSettings),
    ]);

    if (mounted) {
      setState(() => _isSaving = false);

      final hasError = results.any((r) => r.isLeft());
      if (hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save settings. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. STORE PROFILE & RECEIPT INFO SECTION
                    _buildSectionHeader(
                      icon: Icons.storefront_rounded,
                      title: 'STORE PROFILE & RECEIPT INFO',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Shop Name Input
                    TextFormField(
                      controller: _shopNameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: 'Shop Name *',
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        hintText: 'e.g. GearTrack POS',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.business_rounded,
                          size: 20,
                          color: Color(0xFF6366F1),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Shop name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Address Input
                    TextFormField(
                      controller: _shopAddressController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: 'Store Address *',
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        hintText: 'e.g. 12/A Motijheel, Dhaka',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: Color(0xFF6366F1),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Store address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Phone Number Input
                    TextFormField(
                      controller: _shopPhoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        hintText: 'e.g. +880 1712-345678',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_rounded,
                          size: 20,
                          color: Color(0xFF6366F1),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (val.trim().length < 6) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // 2. COST CODE CIPHER SECTION
                    _buildSectionHeader(
                      icon: Icons.vpn_key_rounded,
                      title: 'COST CODE CIPHER',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    // Helper Banner Explaining Multi-Character Aliases
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            size: 20,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Multiple Symbols Per Number Supported',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'e.g. Type "A, @" for 3. Both A and @ will decode to 3. Tap any number box below to easily add/remove symbols.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Keyword Auto-Fill Bar
                    Container(
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _keywordController,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 10,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: r'Keyword (e.g. BL@CK$M!TH)',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (val) {
                                if (val.trim().length >= 10) {
                                  _applyKeyword(val);
                                }
                              },
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              if (_keywordController.text.trim().isNotEmpty) {
                                _applyKeyword(_keywordController.text);
                              }
                            },
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 10-Digit Interactive Matrix (Supports Multi-character e.g. "A, @" -> 3)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _digits.length,
                      itemBuilder: (context, index) {
                        final digit = _digits[index];

                        return InkWell(
                          onTap: () => _openDigitEditSheet(digit),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: inputFillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$digit',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? const Color(0xFF818CF8)
                                            : const Color(0xFF4F46E5),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.edit_note_rounded,
                                      size: 13,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      _digitControllers[digit]
                                                  ?.text
                                                  .isNotEmpty ==
                                              true
                                          ? _digitControllers[digit]!.text
                                          : '—',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Live Test Decoder Pill
                    Container(
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _testCodeController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                              decoration: InputDecoration(
                                hintText: r'Test Code (e.g. BL@CK or B@T)',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) => _updateLivePreview(),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _decodedPreview,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    AppGradientButton(
                      label: 'Save Changes',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
