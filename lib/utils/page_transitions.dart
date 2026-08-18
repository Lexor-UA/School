import 'package:flutter/material.dart';

class FadeScaleRoute extends PageRouteBuilder {
  final Widget page;
  @override
  final Duration transitionDuration;

  FadeScaleRoute({
    required this.page,
    this.transitionDuration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: transitionDuration,
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
