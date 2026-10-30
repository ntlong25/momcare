import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/bump_photo.dart';
import '../../core/models/pregnancy_model.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/app_logger.dart';
import '../home/screens/main_navigation.dart';
import 'screens/bump_camera_screen.dart';

/// Week the camera should open on after a tap on the home-screen widget;
/// null when nothing is waiting.
final quickCameraRequestProvider = StateProvider<int?>((ref) => null);

/// The week to open the camera on, or null when the widget tap must show the
/// normal flow: consent, onboarding or setup is incomplete, the app is in
/// pre-pregnancy mode, or no pregnancy is active.
int? quickCameraWeek({
  required int? acceptedDisclaimerVersion,
  required bool onboarded,
  required String? appMode,
  required PregnancyModel? pregnancy,
  required DateTime now,
}) {
  if (acceptedDisclaimerVersion != AppConstants.disclaimerVersion) return null;
  if (!onboarded || appMode != 'pregnancy' || pregnancy == null) return null;
  return pregnancy
      .currentWeekAt(now)
      .clamp(BumpPhoto.minWeek, BumpPhoto.maxWeek);
}

/// [quickCameraWeek] for the stored app state.
Future<int?> storedQuickCameraWeek() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return quickCameraWeek(
      acceptedDisclaimerVersion: prefs.getInt(
        AppConstants.disclaimerAcceptedVersionKey,
      ),
      onboarded: prefs.getBool(AppConstants.onboardingKey) ?? false,
      appMode: prefs.getString(AppConstants.appModeKey),
      pregnancy: DatabaseService.getActivePregnancy(),
      now: DateTime.now(),
    );
  } catch (error) {
    AppLogger.instance.warning('Could not check the widget gates: $error');
    return null;
  }
}

/// Receives taps on the Android home-screen widget from `MainActivity`. Each
/// tap is taken once and judged right away: a tap the gates refuse is
/// dropped, so finishing onboarding later never opens the camera by itself.
class QuickCameraBridge {
  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'com.ntlong25.momcare/quick_camera',
  );

  final ProviderContainer _container;

  /// Stored app state; replaced in tests.
  final Future<int?> Function() _week;

  QuickCameraBridge(
    this._container, {
    Future<int?> Function() week = storedQuickCameraWeek,
  }) : _week = week;

  /// Starts listening and handles a tap that launched the app. True when the
  /// camera will open.
  Future<bool> start() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'tapped') await _takeTap();
    });
    return _takeTap();
  }

  Future<bool> _takeTap() async {
    try {
      final tapped = await channel.invokeMethod<bool>('takeTap') ?? false;
      if (!tapped) return false;
      final week = await _week();
      if (week == null) return false;
      _container.read(quickCameraRequestProvider.notifier).state = week;
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      AppLogger.instance.warning('Quick camera channel failed: $error');
      return false;
    }
  }
}

/// Lives under the root navigator once the gates are passed. Clears the stack
/// and selects Hôm nay before opening the camera, so cancel, back and save
/// all land on Hôm nay. Leaves a camera that is already open alone, so a
/// second tap does not lose a photo under review.
class QuickCameraListener extends ConsumerStatefulWidget {
  /// True while "Xóa toàn bộ dữ liệu" runs. The stored gates can still pass
  /// at its start, and leaving the settings screen would stop it half way.
  static bool suspended = false;

  final Widget child;

  const QuickCameraListener({super.key, required this.child});

  @override
  ConsumerState<QuickCameraListener> createState() =>
      _QuickCameraListenerState();
}

class _QuickCameraListenerState extends ConsumerState<QuickCameraListener> {
  @override
  void initState() {
    super.initState();
    // The tap of a cold start arrives before this widget exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open(ref.read(quickCameraRequestProvider));
    });
  }

  void _open(int? week) {
    if (week == null) return;
    ref.read(quickCameraRequestProvider.notifier).state = null;
    if (BumpCameraScreen.openCount > 0 || QuickCameraListener.suspended) return;
    ref.read(navigationIndexProvider.notifier).state = 0;
    Navigator.of(context)
      ..popUntil((route) => route.isFirst)
      ..push(
        MaterialPageRoute<void>(builder: (_) => BumpCameraScreen(week: week)),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(quickCameraRequestProvider, (_, week) => _open(week));
    return widget.child;
  }
}
