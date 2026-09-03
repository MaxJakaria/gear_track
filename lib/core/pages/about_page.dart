import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Professional, Modular & Clean Enterprise About Page for Gear Track.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AboutPage());
  }

  static const String _linkedInUrl =
      'https://www.linkedin.com/company/solid-tech-it/';

  static const List<_CapabilityData> _capabilities = [
    _CapabilityData(
      title: 'Live Inventory Sync',
      desc: 'Real-time multi-device stock tracking and auto low-stock alerts.',
      color: Color(0xFF3B82F6),
    ),
    _CapabilityData(
      title: 'High-Velocity POS',
      desc: 'Barcode checkout, customer invoicing, and digital receipts.',
      color: Color(0xFF10B981),
    ),
    _CapabilityData(
      title: 'Sales & Profit Reports',
      desc: 'Daily revenue analytics, profit margins, and PDF exports.',
      color: Color(0xFFF59E0B),
    ),
    _CapabilityData(
      title: 'QR Verification',
      desc: 'Tamper-evident invoice QR validation and fraud protection.',
      color: Color(0xFF8B5CF6),
    ),
  ];

  static const List<String> _platforms = [
    'Web Apps',
    'iOS & Android',
    'macOS',
    'Windows',
    'Linux',
    'Cloud Infrastructure',
  ];

  static const List<_SpecData> _specifications = [
    _SpecData('Application Version', '1.0.0 (Build 1)'),
    _SpecData('Architecture Standard', 'Clean Architecture (SOLID)'),
    _SpecData('State Management', 'BLoC Pattern'),
    _SpecData('Cloud Database', 'Google Cloud Firestore'),
    _SpecData('License Type', 'Commercial Pro'),
  ];

  static void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '$label copied to clipboard!',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  static Future<void> _launchLinkedIn(BuildContext context) async {
    final uri = Uri.parse(_linkedInUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _copy(context, _linkedInUrl, 'LinkedIn link');
      }
    } catch (_) {
      if (context.mounted) {
        _copy(context, _linkedInUrl, 'LinkedIn link');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceSecondary = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainerLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // 1. BRAND HEADER
            _BrandHeader(surfaceColor: surfaceColor, isDark: isDark),
            const SizedBox(height: 16),

            // 2. CORE CAPABILITIES (EQUAL SIZE GRID & FULL TEXT VISIBILITY)
            _SectionLabel('CORE CAPABILITIES', isDark: isDark),
            const SizedBox(height: 6),
            _CapabilitiesGrid(surfaceColor: surfaceColor, isDark: isDark),
            const SizedBox(height: 16),

            // 3. DEVELOPER PROFILE (SOLID TECH)
            _SectionLabel('DEVELOPED & MAINTAINED BY', isDark: isDark),
            const SizedBox(height: 6),
            _CompanyCard(
              surfaceColor: surfaceColor,
              surfaceSecondary: surfaceSecondary,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // 4. APPLICATION SPECIFICATIONS (TABLE IN SURFACE CONTAINER WITHOUT PADDING)
            _SectionLabel('APPLICATION SPECIFICATIONS', isDark: isDark),
            const SizedBox(height: 6),
            _SpecificationsCard(surfaceColor: surfaceColor, isDark: isDark),
            const SizedBox(height: 16),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Reusable Section Label with uniform typography and spacing
class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionLabel(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

/// Reusable Surface Card Container with flat borderless style and 8px padding
class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color surfaceColor;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    required this.surfaceColor,
    required this.isDark,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Brand Identity Header Widget (8px inner padding, max fontSize 16)
class _BrandHeader extends StatelessWidget {
  final Color surfaceColor;
  final bool isDark;

  const _BrandHeader({required this.surfaceColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      surfaceColor: surfaceColor,
      isDark: isDark,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Image.asset(
            'assets/logos/app_logo.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Gear Track',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v1.0.0 Pro',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Industrial Inventory, POS & Supply Chain Suite',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
    );
  }
}

/// 2x2 Capabilities Grid Widget with Guaranteed Equal Heights & Zero Text Truncation
class _CapabilitiesGrid extends StatelessWidget {
  final Color surfaceColor;
  final bool isDark;

  const _CapabilitiesGrid({required this.surfaceColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CapabilityCard(
                  AboutPage._capabilities[0],
                  surfaceColor,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CapabilityCard(
                  AboutPage._capabilities[1],
                  surfaceColor,
                  isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CapabilityCard(
                  AboutPage._capabilities[2],
                  surfaceColor,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CapabilityCard(
                  AboutPage._capabilities[3],
                  surfaceColor,
                  isDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single Capability Card (Full text visible, zero clipping)
class _CapabilityCard extends StatelessWidget {
  final _CapabilityData data;
  final Color surfaceColor;
  final bool isDark;

  const _CapabilityCard(this.data, this.surfaceColor, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.desc,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

/// Developer Profile Card Widget (SOLID Tech) (8px inner padding)
class _CompanyCard extends StatelessWidget {
  final Color surfaceColor;
  final Color surfaceSecondary;
  final bool isDark;

  const _CompanyCard({
    required this.surfaceColor,
    required this.surfaceSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      surfaceColor: surfaceColor,
      isDark: isDark,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Title & Logo
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/logos/solid_tech.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOLID Tech',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Full-Cycle Web, Mobile & Desktop Solutions',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
          const SizedBox(height: 8),

          // Supported Platform Chips
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: AboutPage._platforms
                .map((p) => _ChipPill(p, surfaceSecondary, isDark))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Clickable LinkedIn Tile with Official LinkedIn Logo (8px padding)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => AboutPage._launchLinkedIn(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF0A66C2,
                  ).withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/logos/linkedin.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOLID Tech on LinkedIn',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF0A66C2),
                            ),
                          ),
                          Text(
                            'linkedin.com/company/solid-tech-it',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF0A66C2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Specifications Table inside Background Container (without outer container padding)
class _SpecificationsCard extends StatelessWidget {
  final Color surfaceColor;
  final bool isDark;

  const _SpecificationsCard({required this.surfaceColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.35)
        : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.0),
            1: FlexColumnWidth(1.15),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(color: dividerColor, width: 1),
            verticalInside: BorderSide(color: dividerColor, width: 1),
          ),
          children: AboutPage._specifications.map((spec) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7.5,
                    horizontal: 10,
                  ),
                  child: Text(
                    spec.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7.5,
                    horizontal: 10,
                  ),
                  child: Text(
                    spec.value,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Reusable Chip Pill Widget
class _ChipPill extends StatelessWidget {
  final String label;
  final Color bg;
  final bool isDark;

  const _ChipPill(this.label, this.bg, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _CapabilityData {
  final String title;
  final String desc;
  final Color color;

  const _CapabilityData({
    required this.title,
    required this.desc,
    required this.color,
  });
}

class _SpecData {
  final String label;
  final String value;

  const _SpecData(this.label, this.value);
}
