import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';

/// Minimal & Concise User Guide for GearTrack Operations.
class HelpGuidePage extends StatelessWidget {
  const HelpGuidePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HelpGuidePage());
  }

  static const List<_GuideModuleData> _modules = [
    _GuideModuleData(
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF3B82F6),
      title: '১. ইনভেন্টরি ও স্টক',
      points: [
        '"Add Product" বাটনে ট্যাপ করে পণ্যের নাম, দাম ও স্টক সংরক্ষণ করুন।',
        'একই পণ্যে একাধিক ব্যাচ ও আলাদা দাম ট্র্যাক করা যায়।',
        'স্টক কমে গেলে বা শেষ হলে স্বয়ংক্রিয় কালার অ্যালার্ট দেখাবে।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.point_of_sale_rounded,
      color: Color(0xFF10B981),
      title: '২. পয়েন্ট অব সেল (POS)',
      points: [
        'সার্চ বারে পণ্যের নাম লিখে ব্যাচ সিলেক্ট করলেই কার্টে যুক্ত হবে।',
        'স্টকের অতিরিক্ত পণ্য বিক্রি করা যাবে না।',
        '"Sale Only" দিয়ে দ্রুত বিক্রি অথবা "Generate Bill" দিয়ে PDF মেমো তৈরি করুন।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.analytics_rounded,
      color: Color(0xFFF59E0B),
      title: '৩. সেলস ও প্রফিট রিপোর্ট',
      points: [
        'ক্যালেন্ডার থেকে নির্দিষ্ট দিনের বা মাসের মোট বিক্রি ও নিট লাভ দেখুন।',
        'চার্ট ও গ্রাফের মাধ্যমে ব্যবসার প্রবৃদ্ধি পর্যবেক্ষণ করুন।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF8B5CF6),
      title: '৪. কিউআর (QR) ভেরিফিকেশন',
      points: [
        'ক্যামেরা স্ক্যানার দিয়ে মেমোর QR কোড স্ক্যান করে সত্যতা যাচাই করুন।',
        'কিউআর অস্পষ্ট হলে মেমো আইডি লিখে সার্চ করা যাবে।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.vpn_key_rounded,
      color: Color(0xFFEC4899),
      title: '৫. সিক্রেট কস্ট কোড',
      points: [
        'প্রাইস ট্যাগে কেনা দাম ক্রেতাদের থেকে গোপন রাখতে ১০ অক্ষরের সাইফার ব্যবহার হয়।',
        'Store Settings থেকে নিজস্ব সিক্রেট ওয়ার্ড সেট ও টেস্ট করা যায়।',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

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
          'Help & User Guide',
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
            // Minimal Section Header
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                'ব্যবহার নির্দেশিকা',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),

            // Modules
            ..._modules.map((module) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GuideCard(
                  data: module,
                  surfaceColor: surfaceColor,
                  isDark: isDark,
                ),
              );
            }),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINIMAL GUIDE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  final _GuideModuleData data;
  final Color surfaceColor;
  final bool isDark;

  const _GuideCard({
    required this.data,
    required this.surfaceColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(data.icon, size: 15, color: data.color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Direct Minimal Points
          ...data.points.map((pt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pt,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _GuideModuleData {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> points;

  const _GuideModuleData({
    required this.icon,
    required this.color,
    required this.title,
    required this.points,
  });
}
