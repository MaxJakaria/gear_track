import 'package:flutter/material.dart';

/// Reusable Illustration Image Header for Authentication Screens
class AuthHeaderImage extends StatelessWidget {
  final String imagePath;
  final double height;
  final double topSpacing;
  final double bottomSpacing;

  const AuthHeaderImage({
    super.key,
    required this.imagePath,
    this.height = 190,
    this.topSpacing = 0,
    this.bottomSpacing = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topSpacing > 0) SizedBox(height: topSpacing),
        Center(
          child: Image.asset(
            imagePath,
            height: height,
            fit: BoxFit.contain,
          ),
        ),
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}
