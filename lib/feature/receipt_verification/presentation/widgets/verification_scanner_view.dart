import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class VerificationScannerView extends StatefulWidget {
  final ValueChanged<String> onScanned;

  const VerificationScannerView({
    super.key,
    required this.onScanned,
  });

  @override
  State<VerificationScannerView> createState() => _VerificationScannerViewState();
}

class _VerificationScannerViewState extends State<VerificationScannerView>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  bool _isTorchOn = false;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Mobile Camera View
            MobileScanner(
              controller: _controller,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.no_photography_rounded,
                            size: 36,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Camera Access Required',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Allow camera permissions or switch to Manual ID tab.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue?.trim() ?? '';
                  if (raw.isNotEmpty) {
                    widget.onScanned(raw);
                    break;
                  }
                }
              },
            ),

            // 2. Translucent Dark Dimmer around Frame
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.35),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Cyberpunk Scanning Reticle Corners
            SizedBox(
              width: 224,
              height: 224,
              child: CustomPaint(
                painter: _ReticleCornerPainter(
                  color: const Color(0xFF6366F1),
                  cornerLength: 28,
                  strokeWidth: 3.5,
                  borderRadius: 18,
                ),
              ),
            ),

            // 4. Smooth Laser Line Animation
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                return Positioned(
                  top: (380 - 220) / 2 + (220 * _laserAnimation.value) - 1,
                  child: Container(
                    width: 200,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.0),
                          const Color(0xFF818CF8),
                          const Color(0xFF6366F1).withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 5. Floating Glass Controls (Top Right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GlassButton(
                      icon: _isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      isActive: _isTorchOn,
                      activeColor: const Color(0xFFF59E0B),
                      onTap: () async {
                        try {
                          await _controller.toggleTorch();
                          if (mounted) {
                            setState(() => _isTorchOn = !_isTorchOn);
                          }
                        } catch (_) {}
                      },
                    ),
                    const SizedBox(width: 4),
                    _GlassButton(
                      icon: Icons.cameraswitch_rounded,
                      isActive: false,
                      onTap: () async {
                        try {
                          await _controller.switchCamera();
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 6. Floating Status Pill (Bottom)
            Positioned(
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 15,
                      color: Color(0xFF818CF8),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Align invoice QR inside frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _GlassButton({
    required this.icon,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? const Color(0xFF6366F1)).withValues(alpha: 0.25)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive
              ? (activeColor ?? const Color(0xFF6366F1))
              : Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _ReticleCornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double borderRadius;

  _ReticleCornerPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = borderRadius;
    final l = cornerLength;

    // Top-Left Corner
    final pathTL = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(l, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right Corner
    final pathTR = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, l);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(l, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - l);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _ReticleCornerPainter oldDelegate) => false;
}
