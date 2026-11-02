import 'package:flutter/material.dart';

/// Motion tokens. Every animation of the app reads its duration through
/// [of], so all of them are off when the OS asks for reduced motion.
class AppMotion {
  const AppMotion._();

  /// A progress bar filling up.
  static const Duration progress = Duration(milliseconds: 600);

  /// The "Đã làm" action changing state.
  static const Duration action = Duration(milliseconds: 250);

  /// A saved photo appearing.
  static const Duration photo = Duration(milliseconds: 300);

  /// A card opening its detail screen.
  static const Duration detail = Duration(milliseconds: 300);

  /// The week and its baby size changing.
  static const Duration week = Duration(milliseconds: 250);

  /// Curve of things settling into place.
  static const Curve standard = Curves.easeOutCubic;

  /// True when the OS asks for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when the OS asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// A route from a card to its detail screen. Keeps the platform page
  /// transition (and iOS swipe back).
  static Route<T> detailRoute<T>(BuildContext context, WidgetBuilder builder) =>
      _DetailRoute<T>(builder: builder, duration: of(context, detail));
}

class _DetailRoute<T> extends MaterialPageRoute<T> {
  final Duration duration;

  _DetailRoute({required super.builder, required this.duration});

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;
}
