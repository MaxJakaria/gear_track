import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/pages/main_navigation_page.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:gear_track/feature/auth/presentation/pages/login_page.dart';

/// Luxury, buttery-smooth Animated Splash Page for Gear Track.
class SplashPage extends StatefulWidget {
  final VoidCallback? onInitializationComplete;
  final Duration minimumDuration;

  const SplashPage({
    super.key,
    this.onInitializationComplete,
    this.minimumDuration = const Duration(milliseconds: 2200),
  });

  static Route<void> route({VoidCallback? onInitializationComplete}) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, _, _) =>
          SplashPage(onInitializationComplete: onInitializationComplete),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _indicatorFade;
  late final Animation<double> _pulseAnimation;

  Timer? _minDurationTimer;
  bool _timerElapsed = false;
  bool _hasNavigated = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation sequence (1600ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Staggered animations
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
      ),
    );

    _indicatorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 0.95, curve: Curves.easeIn),
      ),
    );


    // 2. Ambient breathing glow animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();

    // 3. Minimum duration timer to ensure premium brand display
    _minDurationTimer = Timer(widget.minimumDuration, () {
      if (mounted) {
        setState(() {
          _timerElapsed = true;
        });
        _checkAndProceed();
      }
    });

    // 4. Listen to AuthBloc state changes
    final authBloc = context.read<AuthBloc>();
    _authSubscription = authBloc.stream.listen((_) {
      if (mounted) {
        _checkAndProceed();
      }
    });
  }

  @override
  void dispose() {
    _minDurationTimer?.cancel();
    _authSubscription?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkAndProceed() {
    if (!mounted || _hasNavigated || !_timerElapsed) return;

    final authState = context.read<AuthBloc>().state;
    // If still initializing, wait for resolution
    if (authState is AuthInitial) return;

    _hasNavigated = true;

    if (widget.onInitializationComplete != null) {
      widget.onInitializationComplete!();
    } else {
      // Standalone navigation fallback
      final targetPage = (authState is Authenticated)
          ? const MainNavigationPage()
          : const LoginPage();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => targetPage,
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final primaryGradient = AppColors.primaryGradient(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background ambient radial glowing auras
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.9,
                  colors: isDark
                      ? [
                          const Color(0xFF4F46E5).withValues(alpha: 0.16),
                          const Color(0xFF1E1B4B).withValues(alpha: 0.06),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFF6366F1).withValues(alpha: 0.08),
                          const Color(0xFFE0E7FF).withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Main Center Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Animated Logo (No container, larger size)
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _entranceController,
                      _pulseController,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value * _pulseAnimation.value,
                        child: Opacity(opacity: _logoFade.value, child: child),
                      );
                    },
                    child: Image.asset(
                      'assets/logos/app_logo.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Animated App Title & Tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) =>
                              primaryGradient.createShader(bounds),
                          child: const Text(
                            'GEAR TRACK',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Industrial Inventory & POS Suite',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Animated Modern Loading Bar & Status
                FadeTransition(
                  opacity: _indicatorFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 3.5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryButton(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Initializing workspace...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
