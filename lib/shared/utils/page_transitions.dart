import 'package:flutter/material.dart';

class FadeScaleRoute extends PageRouteBuilder {
  final Widget page;

  FadeScaleRoute({
    required this.page,
    super.transitionDuration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade and Scale effect for a cinematic "dive in" feel
            var curve = Curves.easeOutQuint;
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
            var scaleTween = Tween<double>(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
        );
}
