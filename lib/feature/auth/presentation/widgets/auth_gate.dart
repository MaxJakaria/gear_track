import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/pages/main_navigation_page.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:gear_track/feature/auth/presentation/pages/login_page.dart';
import 'package:gear_track/feature/splash/presentation/pages/splash_page.dart';

/// Manages root app routing: displays animated [SplashPage] on cold start,
/// then smoothly transitions between [MainNavigationPage] and [LoginPage].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _splashComplete = false;

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _splashComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return SplashPage(
        onInitializationComplete: _onSplashComplete,
      );
    }

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        if (current is Authenticated) return true;
        if (current is Unauthenticated) return true;
        if (previous is Authenticated && current is! Authenticated) return true;
        return false;
      },
      builder: (context, state) {
        final Widget destination;
        final Key destinationKey;

        if (state is Authenticated) {
          destination = const MainNavigationPage();
          destinationKey = const ValueKey('MainNavigationPage');
        } else {
          destination = const LoginPage();
          destinationKey = const ValueKey('LoginPage');
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: destinationKey,
            child: destination,
          ),
        );
      },
    );
  }
}
