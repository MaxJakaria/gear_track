import 'package:flutter/material.dart';
import 'package:gear_track/core/theme/app_colors.dart';

/// User-Friendly, Simple & Professional Operation Guide for GearTrack.
class HelpGuidePage extends StatelessWidget {
  const HelpGuidePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HelpGuidePage());
  }

  static const List<_GuideModuleData> _modules = [
    _GuideModuleData(
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF3B82F6),
      title: '১. ইনভেন্টরি ও স্টক ম্যানেজমেন্ট',
      points: [
        'পণ্য যুক্ত করতে "Add Product" এ ট্যাপ করে নাম, বিক্রয়মূল্য ও স্টক সেভ করুন।',
        'একই পণ্যে একাধিক ব্যাচ, ভিন্ন কেনা দাম ও আলাদা বারকোড ট্র্যাক করতে পারবেন।',
        'স্টক কমে গেলে বা ফুরিয়ে গেলে স্বয়ংক্রিয় কালার অ্যালার্ট দেখতে পাবেন।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.point_of_sale_rounded,
      color: Color(0xFF10B981),
      title: '২. পয়েন্ট অব সেল (POS) ও ক্যাশ মেমো',
      points: [
        'বারকোড স্ক্যান করে বা নাম সার্চ করে কাঙ্ক্ষিত ব্যাচটি সরাসরি কার্টে যোগ করুন।',
        'স্টকে পণ্য না থাকলে অতিরিক্ত আইটেম সেল তালিকায় যুক্ত করা যাবে না।',
        '"Sale Only" দিয়ে দ্রুত বিক্রি অথবা "Generate Bill" দিয়ে প্রিন্টযোগ্য PDF রসিদ তৈরি করুন।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.assignment_return_rounded,
      color: Color(0xFFF97316),
      title: '৩. পণ্য রিটার্ন ও রিফান্ড প্রসেস',
      points: [
        'কাস্টমার মেমোর QR স্ক্যান করে বা ইনভয়েস নম্বর লিখে রিটার্ন অপশনে প্রবেশ করুন।',
        'ফেরত নেওয়া পণ্যের পরিমাণ সিলেক্ট করে রিফান্ড দিলে স্টক স্বয়ংক্রিয়ভাবে ইনভেন্টরিতে যোগ হবে।',
        'রিটার্ন হিস্ট্রি থেকে যেকোনো সময় রিফান্ড ভাউচার দেখা ও পুনরায় প্রিন্ট করা যাবে।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.analytics_rounded,
      color: Color(0xFFF59E0B),
      title: '৪. সেলস, প্রফিট ও ইনভেস্টমেন্ট রিপোর্ট',
      points: [
        'ক্যালেন্ডার সিলেক্টর দিয়ে যেকোনো নির্দিষ্ট দিন বা মাসের মোট বিক্রি এবং আসল লাভ দেখুন।',
        'ইনভেন্টরিতে মোট পণ্যের বর্তমান ক্রয়মূল্য (Investment) ও বিক্রির সঠিক হিসাব পর্যবেক্ষণ করুন।',
        'এক ক্লিকেই ব্যবসার সার্বিক আর্থিক রিপোর্ট সরাসরি PDF আকারে ডাউনলোড ও প্রিন্ট করুন।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.cloud_sync_rounded,
      color: Color(0xFF06B6D4),
      title: '৫. ডাটাবেজ মেইন্টেন্যান্স ও লেজার সুরক্ষা',
      points: [
        'প্রয়োজনে সেলস বা রিটার্ন হিস্ট্রি ক্লিয়ার করে ক্লাউড ডাটাবেজের গতি বাড়াতে পারবেন।',
        'হিস্ট্রি ডিলিট করলেও আজীবন ব্যবসার মোট লাভ, আয় ও ইনভেস্টমেন্ট স্থায়ী লেজারে শতভাগ সুরক্ষিত থাকে।',
        'গ্রাহকের ক্যাশ মেমো ভবিষ্যতে যাচাইয়ের সুবিধার্থে মূল ইনভয়েসগুলো মুছে ফেলা হয় না।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF8B5CF6),
      title: '৬. কিউআর (QR) মেমো ভেরিফিকেশন',
      points: [
        'ক্যামেরা স্ক্যানার দিয়ে গ্রাহকের মেমোর QR কোড স্ক্যান করে ভুয়া মেমো প্রতিরোধ করুন।',
        'QR কোড ক্ষতিগ্রস্ত থাকলে ইনভয়েস নম্বর টাইপ করে আসল মেমোর বিবরণ যাচাই করুন।',
      ],
    ),
    _GuideModuleData(
      icon: Icons.vpn_key_rounded,
      color: Color(0xFFEC4899),
      title: '৭. সিক্রেট কস্ট সাইফার (Confidential Code)',
      points: [
        'প্রাইস ট্যাগে পণ্যের কেনা দাম ক্রেতাদের থেকে গোপন রাখতে ১০ অক্ষরের ইউনিক সাইফার কোড ব্যবহার হয়।',
        'ড্রয়ারের Store Settings থেকে আপনার নিজস্ব সিক্রেট ওয়ার্ড দিয়ে কস্ট কোড সেট ও টেস্ট করা যায়।',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

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
            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                'ব্যবহার নির্দেশিকা ও গাইড',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
// USER FRIENDLY GUIDE CARD
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(data.icon, size: 16, color: data.color),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Clean, readable bullet points
          ...data.points.map((pt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6.5),
                    child: Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      pt,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
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
