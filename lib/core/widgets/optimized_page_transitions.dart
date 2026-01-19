import 'package:flutter/material.dart';

/// Optimized page transitions with better performance
class OptimizedPageTransitions {
  /// Fast slide transition with reduced animation duration
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget page,
    RouteSettings? settings,
    bool maintainState = true,
    Duration duration = const Duration(milliseconds: 200), // Reduced from 300ms
    Curve curve = Curves.easeOutCubic,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      maintainState: maintainState,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Fast fade transition
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget page,
    RouteSettings? settings,
    bool maintainState = true,
    Duration duration = const Duration(milliseconds: 150), // Very fast fade
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      maintainState: maintainState,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        final opacityAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: opacityAnimation,
          child: child,
        );
      },
    );
  }

  /// No animation transition for instant navigation
  static PageRouteBuilder<T> instantTransition<T>({
    required Widget page,
    RouteSettings? settings,
    bool maintainState = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      maintainState: maintainState,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  /// Scale transition with fade
  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget page,
    RouteSettings? settings,
    bool maintainState = true,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeOutCubic,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      maintainState: maintainState,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        final scaleAnimation = animation.drive(scaleTween);
        final fadeAnimation = animation.drive(fadeTween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Custom theme-based page transition
  static Widget buildTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    bool isIOS = false,
  }) {
    // Use platform-specific transitions for better performance
    if (isIOS) {
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      );
    } else {
      // Android-style fade + slide
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: FadeTransition(
          opacity: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeInOut),
            ),
          ),
          child: child,
        ),
      );
    }
  }
}

/// Performance-optimized custom page transition
class OptimizedPageTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String transitionType;
  final Curve curve;
  final Alignment? alignment;
  final Duration duration;

  OptimizedPageTransition({
    required this.child,
    this.transitionType = 'fade',
    this.curve = Curves.easeInOut,
    this.alignment,
    this.duration = const Duration(milliseconds: 200),
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, _) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (transitionType) {
      case 'fade':
        return FadeTransition(
          opacity: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            ),
          ),
          child: child,
        );
      case 'slide':
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: curve)),
          ),
          child: child,
        );
      case 'scale':
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            ),
          ),
          child: child,
        );
      case 'rotation':
        return RotationTransition(
          turns: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            ),
          ),
          child: child,
        );
      case 'none':
      default:
        return child;
    }
  }
}
