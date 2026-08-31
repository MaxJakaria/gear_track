import 'package:flutter/material.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/entities/shop_settings.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/init_dependencies.dart';
import 'package:gear_track/core/domain/usecases/get_cost_code_mapping.dart';
import 'package:gear_track/core/domain/usecases/save_cost_code_mapping.dart';
import 'package:gear_track/core/domain/usecases/get_shop_settings.dart';
import 'package:gear_track/core/domain/usecases/save_shop_settings.dart';

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

  // Shop Info Controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopPhoneController = TextEditingController();

  // Cost Code Controllers & Focus Nodes
  final Map<int, TextEditingController> _digitControllers = {};
  final Map<int, FocusNode> _digitFocusNodes = {};
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _testCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _decodedPreview = '৳0';

  // Standard 10 digits display order: 1..9, 0
  final List<int> _digits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];

  @override
  void initState() {
    super.initState();
    for (final d in _digits) {
      _digitControllers[d] = TextEditingController();
      _digitFocusNodes[d] = FocusNode();
    }
    _loadAllSettings();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();

    for (final c in _digitControllers.values) {
      c.dispose();
    }
    for (final f in _digitFocusNodes.values) {
      f.dispose();
    }
    _keywordController.dispose();
    _testCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);

    final getMapping = serviceLocator<GetCostCodeMapping>();
    final mappingResult = await getMapping();

    final getShop = serviceLocator<GetShopSettings>();
    final shopResult = await getShop();

    if (mounted) {
      mappingResult.fold(
        (_) => _populateFromMapping(CostCodeMapping.defaultMapping()),
        (mapping) => _populateFromMapping(mapping),
      );

      shopResult.fold(
        (_) {
          _shopNameController.text = 'GearTrack POS';
          _shopAddressController.text = '';
          _shopPhoneController.text = '';
        },
        (shop) {
          _shopNameController.text = shop.shopName;
          _shopAddressController.text = shop.address;
          _shopPhoneController.text = shop.phone;
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

  void _resetToDefault() {
    _shopNameController.text = 'GearTrack POS';
    _shopAddressController.clear();
    _shopPhoneController.clear();

    final def = CostCodeMapping.defaultMapping();
    _populateFromMapping(def);
    _keywordController.clear();
    _testCodeController.clear();
    _updateLivePreview();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All settings reset to default!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  CostCodeMapping _buildCurrentMapping() {
    final map = <String, int>{};
    for (final d in _digits) {
      final text = _digitControllers[d]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        map[text[0].toUpperCase()] = d;
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _resetToDefault,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text(
                'Reset',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. STORE PROFILE SECTION
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Shop / Store Name *',
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                                hintText: 'e.g. Gear Track Auto Parts',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.business_rounded,
                                  size: 20,
                                  color: Color(0xFF6366F1),
                                ),
                                filled: true,
                                fillColor: inputFillColor,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 1.5,
                                  ),
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
                                hintText: 'e.g. 123 Gear Street, Auto City',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: Color(0xFF6366F1),
                                ),
                                filled: true,
                                fillColor: inputFillColor,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Address is required for receipts';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Phone Number Input
                            TextFormField(
                              controller: _shopPhoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Contact Phone Number *',
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                                hintText: 'e.g. 017XXXXXXXX',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                  color: Color(0xFF6366F1),
                                ),
                                filled: true,
                                fillColor: inputFillColor,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 1.5,
                                  ),
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
                            const SizedBox(height: 12),

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
                                      textCapitalization:
                                          TextCapitalization.characters,
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      if (_keywordController.text
                                          .trim()
                                          .isNotEmpty) {
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

                            // 10-Digit Interactive Matrix
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.92,
                                  ),
                              itemCount: _digits.length,
                              itemBuilder: (context, index) {
                                final digit = _digits[index];

                                return Container(
                                  decoration: BoxDecoration(
                                    color: inputFillColor,
                                    borderRadius: BorderRadius.circular(12),
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
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? const Color(0xFF818CF8)
                                              : const Color(0xFF4F46E5),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: TextField(
                                          controller: _digitControllers[digit],
                                          focusNode: _digitFocusNodes[digit],
                                          textAlign: TextAlign.center,
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          maxLength: 1,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (val) {
                                            _updateLivePreview();
                                            if (val.isNotEmpty &&
                                                index < _digits.length - 1) {
                                              final nextDigit =
                                                  _digits[index + 1];
                                              _digitFocusNodes[nextDigit]
                                                  ?.requestFocus();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
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
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            r'Live test code (e.g. B@T or @!*)',
                                        hintStyle: TextStyle(
                                          fontSize: 12.5,
                                          letterSpacing: 0,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (_) => _updateLivePreview(),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFF10B981))
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _decodedPreview,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Pinned Bottom Save Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: AppGradientButton(
                        onPressed: _isSaving ? null : _save,
                        isLoading: _isSaving,
                        height: 48,
                        label: 'Save Settings',
                      ),
                    ),
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
          size: 16,
          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
