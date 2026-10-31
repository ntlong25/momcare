// In-app bump camera and the home-screen widget route: permission, no
// camera, errors, double tap, review, save, cancel, lifecycle, widget gates,
// layout at 360 dp x1.5, token contrast, crop, temp files, manifest.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/services/bump_photo_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/core/utils/share_helper.dart';
import 'package:momcare/features/bump_journal/bump_camera_source.dart';
import 'package:momcare/features/bump_journal/quick_camera.dart';
import 'package:momcare/features/bump_journal/screens/bump_camera_screen.dart';
import 'package:momcare/features/bump_journal/screens/bump_journal_screen.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_bump_camera.dart';

const ValueKey<String> _shutter = ValueKey('bump-camera-shutter');
const ValueKey<String> _save = ValueKey('bump-camera-save');
const ValueKey<String> _retake = ValueKey('bump-camera-retake');
const ValueKey<String> _close = ValueKey('bump-camera-close');
const ValueKey<String> _flash = ValueKey('bump-camera-flash');
const ValueKey<String> _switch = ValueKey('bump-camera-switch');
const ValueKey<String> _grid = ValueKey('bump-camera-journal');
const ValueKey<String> _frame = ValueKey('bump-camera-frame');
const ValueKey<String> _frozen = ValueKey('bump-camera-frozen');

void _setView(WidgetTester tester, [double width = 360, double height = 640]) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, height * 3);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

IconButton iconButton(WidgetTester tester, Key key) =>
    tester.widget<IconButton>(
      find.descendant(of: find.byKey(key), matching: find.byType(IconButton)),
    );

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

class _Opener extends StatelessWidget {
  final Widget Function() screen;

  const _Opener(this.screen);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const ValueKey('open'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => screen())),
        child: const Text('Trang trước'),
      ),
    ),
  );
}

void main() {
  late Directory root;
  late Directory temp;
  late Directory docs;
  late FakeBumpCamera camera;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('momcare_camera');
    temp = Directory('${root.path}/cache')..createSync();
    docs = Directory('${root.path}/docs')..createSync();
    camera = FakeBumpCamera(temp);
    BumpCameraScreen.debugSource = () => camera;
    BumpPhotoService.debugDocumentsDir = () async => docs;
    ShareHelper.debugTempDir = () async => temp;
    ShareHelper.debugOwnsTempDir = () => true;
  });

  tearDown(() {
    BumpCameraScreen.debugSource = null;
    BumpCameraScreen.debugOpenSettings = null;
    BumpPhotoService.resetDebugDocumentsDir();
    ShareHelper.resetDebugOverrides();
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  Widget app(Widget home, {double textScale = 1, ProviderContainer? scope}) {
    final child = MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    );
    return scope == null
        ? ProviderScope(child: child)
        : UncontrolledProviderScope(container: scope, child: child);
  }

  /// Lets the screen's prefs read and camera start finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  /// Pumps with real time until [done]: the save does real file work.
  Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await settle(tester);
    }
    expect(done(), isTrue);
  }

  Future<void> pumpCamera(
    WidgetTester tester, {
    double textScale = 1,
    int week = 20,
    bool fromJournal = false,
  }) async {
    await tester.pumpWidget(
      app(
        BumpCameraScreen(week: week, fromJournal: fromJournal),
        textScale: textScale,
      ),
    );
    await settle(tester);
  }

  /// Opens the camera from a page below it.
  Future<void> pumpFromCaller(WidgetTester tester) async {
    await tester.pumpWidget(
      app(_Opener(() => const BumpCameraScreen(week: 20))),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    await settle(tester);
  }

  Future<void> shoot(WidgetTester tester) async {
    await tester.tap(find.byKey(_shutter));
    await settle(tester);
    expect(find.byKey(_save), findsOneWidget);
  }

  List<String> tempNames() =>
      temp.listSync().map((e) => e.uri.pathSegments.last).toList();

  group('camera', () {
    testWidgets('opens the back lens by default, week pill, square frame, '
        'flash off', (tester) async {
      _setView(tester);
      await pumpCamera(tester);
      expect(camera.opened, [BumpLens.back]);
      expect(camera.flash, [false]);
      expect(find.text('Tuần 20'), findsOneWidget);
      expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
      final size = tester.getSize(find.byKey(_frame));
      expect(size.width, size.height);
      expect(
        tester
            .widget<FittedBox>(
              find.byKey(const ValueKey('bump-camera-preview')),
            )
            .fit,
        BoxFit.cover,
      );
    });

    testWidgets('remembers the last lens', (tester) async {
      _setView(tester);
      await pumpCamera(tester);
      await tester.tap(find.byKey(_switch));
      await settle(tester);
      expect(camera.opened, [BumpLens.back, BumpLens.front]);
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(prefs!.getString(AppConstants.bumpCameraLensKey), 'front');

      await tester.pumpWidget(const SizedBox());
      camera = FakeBumpCamera(temp);
      await pumpCamera(tester);
      expect(camera.opened, [BumpLens.front]);
    });

    testWidgets('a saved lens the device lacks falls back; one lens has no '
        'switch', (tester) async {
      _setView(tester);
      SharedPreferences.setMockInitialValues({
        AppConstants.bumpCameraLensKey: 'front',
      });
      camera.available = const [BumpLens.back];
      await pumpCamera(tester);
      expect(camera.opened, [BumpLens.back]);
      expect(iconButton(tester, _switch).onPressed, isNull);
    });

    testWidgets('flash toggles on the back lens, is off on the front', (
      tester,
    ) async {
      _setView(tester);
      await pumpCamera(tester);
      await tester.tap(find.byKey(_flash));
      await tester.pump();
      expect(camera.flash.last, isTrue);
      await tester.tap(find.byKey(_switch));
      await settle(tester);
      expect(camera.flash.last, isFalse);
      expect(iconButton(tester, _flash).onPressed, isNull);
    });

    testWidgets('permission denied explains in Vietnamese and opens settings', (
      tester,
    ) async {
      _setView(tester);
      var opened = 0;
      BumpCameraScreen.debugOpenSettings = () async {
        opened++;
        return true;
      };
      camera.openFailure = BumpCameraFailure.permissionDenied;
      await pumpCamera(tester);
      expect(find.text(BumpCameraScreen.permissionTitle), findsOneWidget);
      expect(find.text(BumpCameraScreen.permissionMessage), findsOneWidget);
      expect(find.byKey(_shutter), findsNothing);
      await tester.tap(find.byKey(const ValueKey('bump-camera-open-settings')));
      await tester.pump();
      expect(opened, 1);

      // Back from Settings with the permission granted.
      camera.openFailure = null;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(find.byKey(_shutter), findsOneWidget);
    });

    testWidgets('no camera: message and a way to the journal', (tester) async {
      _setView(tester);
      camera.available = const [];
      await pumpCamera(tester);
      expect(find.text(BumpCameraScreen.noCameraMessage), findsOneWidget);
      expect(camera.opened, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('bump-camera-failure-journal')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BumpJournalScreen), findsOneWidget);
      await settle(tester);
    });

    testWidgets('init error offers a retry', (tester) async {
      _setView(tester);
      camera.openFailure = BumpCameraFailure.error;
      await pumpCamera(tester);
      expect(find.text(BumpCameraScreen.startErrorMessage), findsOneWidget);
      camera.openFailure = null;
      await tester.tap(find.byKey(const ValueKey('bump-camera-retry')));
      await settle(tester);
      expect(find.byKey(_shutter), findsOneWidget);
      expect(find.text(BumpCameraScreen.startErrorMessage), findsNothing);
    });

    testWidgets('double tap on the shutter takes one photo', (tester) async {
      _setView(tester);
      final gate = camera.captureGate = Completer<void>();
      await pumpCamera(tester);
      await tester.tap(find.byKey(_shutter));
      await tester.tap(find.byKey(_shutter));
      await tester.pump();
      await tester.tap(find.byKey(_shutter));
      await tester.pump();
      expect(camera.captures, 1);
      expect(tester.widget<InkWell>(find.byKey(_shutter)).onTap, isNull);
      gate.complete();
      await settle(tester);
      expect(camera.captures, 1);
      expect(find.byKey(_save), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    testWidgets('the shutter gives feedback at once, before the photo exists', (
      tester,
    ) async {
      _setView(tester);
      final gate = camera.captureGate = Completer<void>();
      await pumpCamera(tester);
      await tester.tap(find.byKey(_shutter));
      await tester.pump();
      expect(camera.captures, 1);
      expect(find.byKey(_save), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await settle(tester);
      expect(find.byKey(_save), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    testWidgets('the stopped frame waits for the frame with the shutter '
        'feedback', (tester) async {
      _setView(tester);
      final gate = camera.captureGate = Completer<void>();
      await pumpCamera(tester);
      await tester.tap(find.byKey(_shutter));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(_frozen), findsNothing);
      await settle(tester);
      expect(find.byKey(_frozen), findsOneWidget);
      gate.complete();
      await settle(tester);
      expect(find.byKey(_frozen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    for (final failed in [true, false]) {
      testWidgets('Home during a capture, then back: live preview, no stopped '
          'frame, no file left (capture failed: $failed)', (tester) async {
        _setView(tester);
        final gate = camera.captureGate = Completer<void>();
        await pumpCamera(tester);
        await tester.tap(find.byKey(_shutter));
        await settle(tester);
        expect(find.byKey(_frozen), findsOneWidget);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(find.byKey(_frozen), findsNothing);
        final empty = File('${temp.path}/CAP1.jpg')..writeAsBytesSync([]);
        if (failed) {
          camera.captureError = const BumpCameraException(
            BumpCameraFailure.error,
          );
        } else {
          empty.deleteSync();
        }
        gate.complete();
        await settle(tester);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await settle(tester);
        expect(find.byKey(_frozen), findsNothing);
        expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
        expect(tester.widget<InkWell>(find.byKey(_shutter)).onTap, isNotNull);
        expect(find.byKey(_save), findsNothing);
        expect(tempNames(), isEmpty);
      });
    }

    testWidgets('a failed capture keeps the camera and can be tried again', (
      tester,
    ) async {
      _setView(tester);
      camera.captureError = const BumpCameraException(BumpCameraFailure.error);
      await pumpCamera(tester);
      await tester.tap(find.byKey(_shutter));
      await settleUntil(
        tester,
        () => find
            .text(BumpCameraScreen.captureErrorMessage)
            .evaluate()
            .isNotEmpty,
      );
      expect(tester.widget<InkWell>(find.byKey(_shutter)).onTap, isNotNull);
    });

    testWidgets('lifecycle: pause closes, resume reopens, inactive does not '
        'touch the camera', (tester) async {
      _setView(tester);
      await pumpCamera(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(camera.closed, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(camera.opened, hasLength(1));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(camera.closed, 1);
      expect(find.byKey(const ValueKey('fake-preview')), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(camera.opened, hasLength(2));
      expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    });

    testWidgets('leaving closes the camera and restores no temp files', (
      tester,
    ) async {
      _setView(tester);
      await pumpFromCaller(tester);
      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(camera.closed, 1);
      expect(BumpCameraScreen.openCount, 0);
    });

    testWidgets('opening clears a photo left by a process death', (
      tester,
    ) async {
      _setView(tester);
      final stale = File('${temp.path}/bump_camera_old.jpg')
        ..writeAsBytesSync([1]);
      final other = File('${temp.path}/keep.txt')..writeAsBytesSync([1]);
      await pumpCamera(tester);
      await settle(tester);
      expect(stale.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);
    });

    group('grid button', () {
      testWidgets('opens the journal on the week, replacing the camera', (
        tester,
      ) async {
        _setView(tester);
        await pumpFromCaller(tester);
        await tester.tap(find.byKey(_grid));
        await tester.pumpAndSettle();
        await settle(tester);
        expect(find.byType(BumpCameraScreen), findsNothing);
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('bump-week-label')))
              .data,
          'Tuần 20',
        );
      });

      testWidgets('from the journal goes back to it', (tester) async {
        _setView(tester);
        await tester.pumpWidget(
          app(
            _Opener(() => const BumpCameraScreen(week: 20, fromJournal: true)),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('open')));
        await tester.pumpAndSettle();
        await settle(tester);
        await tester.tap(find.byKey(_grid));
        await tester.pumpAndSettle();
        expect(find.byType(_Opener), findsOneWidget);
        expect(find.byType(BumpJournalScreen), findsNothing);
      });
    });
  });

  group('review', () {
    testWidgets('shows the photo in the same frame with both actions; the '
        'camera is released', (tester) async {
      _setView(tester);
      await pumpCamera(tester);
      await shoot(tester);
      expect(find.text('Lưu vào tuần 20'), findsOneWidget);
      expect(find.text('Chụp lại'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bump-camera-review-photo')),
        findsOneWidget,
      );
      expect(find.byKey(_frame), findsOneWidget);
      expect(camera.closed, 1);
      expect(find.byKey(const ValueKey('fake-preview')), findsNothing);
    });

    testWidgets('Chụp lại deletes the temp file and restarts the camera', (
      tester,
    ) async {
      _setView(tester);
      await pumpCamera(tester);
      await shoot(tester);
      final path = camera.captured.single;
      expect(File(path).existsSync(), isTrue);
      await settle(tester);
      await tester.tap(find.byKey(_retake));
      await settle(tester);
      expect(File(path).existsSync(), isFalse);
      expect(find.byKey(_shutter), findsOneWidget);
      expect(camera.opened, hasLength(2));
    });

    testWidgets('system back from the review is Chụp lại, not leaving', (
      tester,
    ) async {
      _setView(tester);
      await pumpFromCaller(tester);
      await shoot(tester);
      final path = camera.captured.single;
      await settle(tester);
      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue);
      await settle(tester);
      expect(find.byType(BumpCameraScreen), findsOneWidget);
      expect(find.byKey(_shutter), findsOneWidget);
      expect(File(path).existsSync(), isFalse);
    });

    testWidgets('the review appears before the crop finishes; Lưu waits for '
        'it and saves the finished file', (tester) async {
      _setView(tester);
      final gate = camera.finishGate = Completer<void>();
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        app(_Opener(() => const BumpCameraScreen(week: 20)), scope: scope),
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await settle(tester);

      await shoot(tester);
      expect(camera.finished, isEmpty);
      expect(
        find.byKey(const ValueKey('bump-camera-review-photo')),
        findsOneWidget,
      );
      final raw = camera.captured.single;

      await tester.tap(find.byKey(_save));
      await tester.pump();
      await tester.pump();
      expect(scope.read(bumpPhotoProvider), isEmpty);
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(_save)).onPressed,
        isNull,
      );

      gate.complete();
      await settleUntil(tester, () => scope.read(bumpPhotoProvider).isNotEmpty);
      await settle(tester);
      await tester.pumpAndSettle();
      await settle(tester);
      expect(scope.read(bumpPhotoProvider), hasLength(1));
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(File(raw).existsSync(), isFalse);
      expect(File(camera.finished.single).existsSync(), isFalse);
      expect(tempNames(), isEmpty);
    });

    testWidgets('Chụp lại during the crop still removes both files', (
      tester,
    ) async {
      _setView(tester);
      final gate = camera.finishGate = Completer<void>();
      await pumpCamera(tester);
      await shoot(tester);
      await settle(tester);
      await tester.tap(find.byKey(_retake));
      await settle(tester);
      expect(find.byKey(_shutter), findsOneWidget);
      gate.complete();
      await settle(tester);
      expect(tempNames(), isEmpty);
    });

    testWidgets('leaving the screen deletes an unsaved photo', (tester) async {
      _setView(tester);
      await pumpCamera(tester);
      await shoot(tester);
      final path = camera.captured.single;
      await settle(tester);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      expect(File(path).existsSync(), isFalse);
      expect(BumpCameraScreen.openCount, 0);
    });

    testWidgets('a photo under review survives pause and resume', (
      tester,
    ) async {
      _setView(tester);
      await pumpCamera(tester);
      await shoot(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(find.byKey(_save), findsOneWidget);
      expect(camera.opened, hasLength(1));
      expect(File(camera.captured.single).existsSync(), isTrue);
    });

    testWidgets('Lưu saves through addFiles into the app folder on that week, '
        'removes the temp file and returns to the caller', (tester) async {
      _setView(tester);
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        app(_Opener(() => const BumpCameraScreen(week: 20)), scope: scope),
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await settle(tester);
      await shoot(tester);
      final path = camera.captured.single;
      await settle(tester);

      await tester.tap(find.byKey(_save));
      await settleUntil(tester, () => scope.read(bumpPhotoProvider).isNotEmpty);
      await settle(tester);
      await tester.pumpAndSettle();
      await settle(tester);

      final photo = scope.read(bumpPhotoProvider).single;
      expect(photo.week, 20);
      expect(
        File(
          '${docs.path}/${BumpPhotoService.folderName}/${photo.fileName}',
        ).existsSync(),
        isTrue,
      );
      expect(File(path).existsSync(), isFalse);
      expect(find.byType(_Opener), findsOneWidget);
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(find.text('Đã lưu ảnh vào tuần 20'), findsOneWidget);
      expect(tempNames(), isEmpty);
    });
  });

  group('widget gates', () {
    final now = DateTime(2026, 10, 31);
    final pregnancy = PregnancyModel(
      id: 'p',
      motherName: 'An',
      dueDate: PregnancyModel.dueDateFromLastPeriod(
        DateTime(2026, 10, 31 - 20 * 7 - 3),
      ),
      createdAt: now,
      updatedAt: now,
    );

    int? week({
      int? consent = AppConstants.disclaimerVersion,
      bool onboarded = true,
      String? mode = 'pregnancy',
      PregnancyModel? active,
      bool noPregnancy = false,
    }) => quickCameraWeek(
      acceptedDisclaimerVersion: consent,
      onboarded: onboarded,
      appMode: mode,
      pregnancy: noPregnancy ? null : (active ?? pregnancy),
      now: now,
    );

    test('all passed gives the current week', () {
      expect(week(), pregnancy.currentWeekAt(now));
    });

    test('no consent, or an older consent version, does not pass', () {
      expect(week(consent: null), isNull);
      expect(week(consent: AppConstants.disclaimerVersion - 1), isNull);
    });

    test('onboarding not finished does not pass', () {
      expect(week(onboarded: false), isNull);
    });

    test('pre-pregnancy or no mode does not pass', () {
      expect(week(mode: 'prePregnancy'), isNull);
      expect(week(mode: null), isNull);
    });

    test('no active pregnancy (setup incomplete) does not pass', () {
      expect(week(noPregnancy: true), isNull);
    });
  });

  group('widget route', () {
    const channel = QuickCameraBridge.channel;
    late bool tapPending;
    late int takes;

    setUp(() {
      tapPending = false;
      takes = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'takeTap');
            takes++;
            final tapped = tapPending;
            tapPending = false;
            return tapped;
          });
    });

    /// The bridge only runs on Android. Not for testWidgets: the framework
    /// insists the override is gone before the test body ends.
    void onAndroid() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      channel.setMethodCallHandler(null);
    });

    Future<void> nativeTap() async {
      tapPending = true;
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            channel.codec.encodeMethodCall(const MethodCall('tapped')),
            (_) {},
          );
    }

    test('a launch without a tap opens nothing', () async {
      onAndroid();
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      expect(
        await QuickCameraBridge(scope, week: () async => 20).start(),
        false,
      );
      expect(scope.read(quickCameraRequestProvider), isNull);
    });

    test(
      'a cold-start tap that passes the gates requests the camera once',
      () async {
        onAndroid();
        final scope = ProviderContainer();
        addTearDown(scope.dispose);
        tapPending = true;
        final bridge = QuickCameraBridge(scope, week: () async => 20);
        expect(await bridge.start(), isTrue);
        expect(scope.read(quickCameraRequestProvider), 20);
        expect(tapPending, isFalse);
      },
    );

    test('a tap the gates refuse is dropped, not kept for later', () async {
      onAndroid();
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      tapPending = true;
      expect(
        await QuickCameraBridge(scope, week: () async => null).start(),
        isFalse,
      );
      expect(scope.read(quickCameraRequestProvider), isNull);
      expect(tapPending, isFalse);
      expect(takes, 1);
    });

    test('a tap while the app runs requests the camera', () async {
      onAndroid();
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      await QuickCameraBridge(scope, week: () async => 21).start();
      await nativeTap();
      await Future<void>.delayed(Duration.zero);
      expect(scope.read(quickCameraRequestProvider), 21);
    });

    test('no channel on this platform is not an error', () async {
      onAndroid();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      expect(await QuickCameraBridge(scope).start(), isFalse);
    });

    Widget home(ProviderContainer scope) => app(
      QuickCameraListener(
        child: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Column(
              children: [
                Text('tab ${ref.watch(navigationIndexProvider)}'),
                TextButton(
                  key: const ValueKey('push'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const Scaffold(body: Text('Trang bên trong')),
                    ),
                  ),
                  child: const Text('Mở'),
                ),
              ],
            ),
          ),
        ),
      ),
      scope: scope,
    );

    testWidgets('cold start: camera on the week, cancel lands on Hôm nay', (
      tester,
    ) async {
      _setView(tester);
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      scope.read(quickCameraRequestProvider.notifier).state = 20;
      await tester.pumpWidget(home(scope));
      await tester.pumpAndSettle();
      await settle(tester);
      expect(find.byType(BumpCameraScreen), findsOneWidget);
      expect(find.text('Tuần 20'), findsOneWidget);
      expect(scope.read(quickCameraRequestProvider), isNull);

      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(find.text('tab 0'), findsOneWidget);
    });

    testWidgets('nothing requested: no camera, nothing started', (
      tester,
    ) async {
      _setView(tester);
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      await tester.pumpWidget(home(scope));
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(camera.opened, isEmpty);
    });

    testWidgets('warm: leaves another tab and page, back lands on Hôm nay', (
      tester,
    ) async {
      _setView(tester);
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      scope.read(navigationIndexProvider.notifier).state = 3;
      await tester.pumpWidget(home(scope));
      await tester.tap(find.byKey(const ValueKey('push')));
      await tester.pumpAndSettle();
      expect(find.text('Trang bên trong'), findsOneWidget);

      scope.read(quickCameraRequestProvider.notifier).state = 20;
      await tester.pumpAndSettle();
      await settle(tester);
      expect(find.byType(BumpCameraScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(find.text('Trang bên trong'), findsNothing);
      expect(find.text('tab 0'), findsOneWidget);
    });

    testWidgets('a tap during delete-all is ignored', (tester) async {
      _setView(tester);
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      QuickCameraListener.suspended = true;
      addTearDown(() => QuickCameraListener.suspended = false);
      await tester.pumpWidget(home(scope));
      scope.read(quickCameraRequestProvider.notifier).state = 20;
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(scope.read(quickCameraRequestProvider), isNull);
    });

    testWidgets('a second tap leaves a photo under review alone', (
      tester,
    ) async {
      _setView(tester);
      final scope = ProviderContainer();
      addTearDown(scope.dispose);
      scope.read(quickCameraRequestProvider.notifier).state = 20;
      await tester.pumpWidget(home(scope));
      await tester.pumpAndSettle();
      await settle(tester);
      await shoot(tester);

      scope.read(quickCameraRequestProvider.notifier).state = 20;
      await tester.pumpAndSettle();
      expect(find.byKey(_save), findsOneWidget);
      expect(File(camera.captured.single).existsSync(), isTrue);
      expect(scope.read(quickCameraRequestProvider), isNull);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });
  });

  group('layout', () {
    for (final size in [const Size(360, 640), const Size(411, 891)]) {
      for (final scale in [1.0, 1.5]) {
        final name = '${size.width.toInt()}x${size.height.toInt()} x$scale';

        testWidgets('live, no overflow, $name', (tester) async {
          _setView(tester, size.width, size.height);
          await pumpCamera(tester, textScale: scale, week: 40);
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byKey(_frame)).shortestSide,
            greaterThan(100),
          );
        });

        testWidgets('review, no overflow, $name', (tester) async {
          _setView(tester, size.width, size.height);
          await pumpCamera(tester, textScale: scale, week: 40);
          await shoot(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('Lưu vào tuần 40'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          await settle(tester);
        });

        for (final failure in BumpCameraFailure.values) {
          testWidgets('${failure.name}, no overflow, $name', (tester) async {
            _setView(tester, size.width, size.height);
            camera.openFailure = failure;
            await pumpCamera(tester, textScale: scale);
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const ValueKey('bump-camera-failure')),
              findsOneWidget,
            );
          });
        }
      }
    }
  });

  group('tokens', () {
    test('text and controls keep their contrast on the dark chrome', () {
      for (final bg in [AppCameraColors.background, AppCameraColors.surface]) {
        expect(
          _contrast(AppCameraColors.foreground, bg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppCameraColors.foregroundSoft, bg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppCameraColors.foregroundDisabled, bg),
          greaterThanOrEqualTo(3),
        );
      }
      expect(
        _contrast(AppCameraColors.onAccent, AppCameraColors.accent),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppCameraColors.accent, AppCameraColors.background),
        greaterThanOrEqualTo(3),
      );
    });

    test('peach and mint stay reserved', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final s = theme.extension<AppSemanticColors>()!;
        for (final colour in [
          AppCameraColors.background,
          AppCameraColors.surface,
          AppCameraColors.accent,
        ]) {
          expect(colour, isNot(s.peachContainer));
          expect(colour, isNot(s.mintContainer));
        }
      }
    });
  });

  group('mirror', () {
    test('only the front lens on Android is flipped', () {
      expect(bumpPhotoMirrored(BumpLens.front, TargetPlatform.android), isTrue);
      expect(bumpPhotoMirrored(BumpLens.back, TargetPlatform.android), isFalse);
      expect(bumpPhotoMirrored(BumpLens.back, TargetPlatform.iOS), isFalse);
      expect(bumpPhotoMirrored(BumpLens.front, TargetPlatform.iOS), isFalse);
    });

    for (final front in [false, true]) {
      testWidgets('review and saved photo follow the lens (front: $front)', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        _setView(tester);
        SharedPreferences.setMockInitialValues({
          AppConstants.bumpCameraLensKey: front ? 'front' : 'back',
        });
        await pumpCamera(tester);
        await shoot(tester);
        expect(camera.mirrors, [front]);
        final flip = tester.widget<Transform>(
          find.byKey(const ValueKey('bump-camera-review-flip')),
        );
        expect(flip.transform.storage[0], front ? -1 : 1);
        await tester.pumpWidget(const SizedBox());
        await settle(tester);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });

  group('crop', () {
    /// RGBA picture whose left half is dark, so a wrong crop or flip shows.
    Uint8List rgba(int width, int height) {
      final bytes = Uint8List(width * height * 4);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final at = (y * width + x) * 4;
          bytes[at + 1] = x < width ~/ 2 ? 0 : 200;
          bytes[at + 3] = 255;
        }
      }
      return bytes;
    }

    test('landscape and portrait become the centre square', () {
      for (final (w, h) in [(160, 90), (90, 160)]) {
        final out = img.decodeJpg(squareCropRgba(rgba(w, h), w, h))!;
        expect((out.width, out.height), (90, 90));
      }
    });

    test('the crop is centred and carries no metadata', () {
      final out = img.decodeJpg(squareCropRgba(rgba(200, 100), 200, 100))!;
      expect(out.getPixel(10, 50).g, lessThan(60));
      expect(out.getPixel(90, 50).g, greaterThan(150));
      expect(out.exif.isEmpty, isTrue);
    });

    test('mirror flips the photo left to right', () {
      final plain = img.decodeJpg(squareCropRgba(rgba(160, 160), 160, 160))!;
      final mirrored = img.decodeJpg(
        squareCropRgba(rgba(160, 160), 160, 160, mirror: true),
      )!;
      expect(plain.getPixel(10, 80).g, lessThan(60));
      expect(mirrored.getPixel(10, 80).g, greaterThan(150));
      expect(mirrored.getPixel(150, 80).g, lessThan(60));
    });

    test('plugin error codes map to failures', () {
      for (final code in [
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
        'cameraPermission',
      ]) {
        expect(bumpCameraFailureFor(code), BumpCameraFailure.permissionDenied);
      }
      expect(bumpCameraFailureFor('IOError'), BumpCameraFailure.error);
    });
  });

  group('temp files', () {
    File write(String name) =>
        File('${temp.path}/$name')..writeAsBytesSync([1]);

    test('clearCameraTempFiles removes only camera photos', () async {
      final cropped = write('bump_camera_a.jpg');
      final capture = write('CAP123.jpg');
      final other = write('note.jpg');
      expect(await ShareHelper.clearCameraTempFiles(), 2);
      expect(cropped.existsSync(), isFalse);
      expect(capture.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);
    });

    test(
      'delete-all removes them, also when the temp folder is shared',
      () async {
        ShareHelper.debugOwnsTempDir = () => false;
        final cropped = write('bump_camera_a.jpg');
        final capture = write('CAP123.jpg');
        final other = write('note.jpg');
        await ShareHelper.clearTempFiles();
        expect(cropped.existsSync(), isFalse);
        expect(capture.existsSync(), isFalse);
        expect(other.existsSync(), isTrue);
      },
    );

    test('delete-all empties the app-owned temp folder', () async {
      write('bump_camera_a.jpg');
      write('CAP123.jpg');
      await ShareHelper.clearTempFiles();
      expect(tempNames(), isEmpty);
    });
  });

  group('Android manifest', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    test('declares CAMERA, requires no camera hardware', () {
      expect(manifest, contains('android.permission.CAMERA'));
      for (final feature in ['camera', 'camera.autofocus']) {
        expect(
          manifest,
          contains(
            '<uses-feature android:name="android.hardware.$feature" '
            'android:required="false" />',
          ),
        );
      }
    });

    test('the plugin\'s microphone and storage permissions are removed', () {
      for (final name in ['RECORD_AUDIO', 'WRITE_EXTERNAL_STORAGE']) {
        expect(
          manifest,
          contains(
            '<uses-permission android:name="android.permission.$name" '
            'tools:node="remove" />',
          ),
        );
      }
      expect(
        manifest,
        contains(
          '<uses-feature android:name="android.hardware.camera.any" '
          'android:required="false" tools:replace="android:required" />',
        ),
      );
    });

    test('the widget label shrinks instead of being cut off', () {
      final layout = File(
        'android/app/src/main/res/layout/quick_camera_widget.xml',
      ).readAsStringSync();
      expect(layout, contains('android:autoSizeTextType="uniform"'));
      expect(layout, isNot(contains('android:ellipsize')));
    });

    test('the launch window carries the brand mark', () {
      for (final folder in ['drawable', 'drawable-v21']) {
        expect(
          File(
            'android/app/src/main/res/$folder/launch_background.xml',
          ).readAsStringSync(),
          contains('@drawable/ic_launcher_foreground'),
        );
      }
      for (final folder in ['values', 'values-night']) {
        expect(
          RegExp(
            r'name="NormalTheme"[^>]*>\s*<item '
            r'name="android:windowBackground">@drawable/launch_background',
          ).hasMatch(
            File(
              'android/app/src/main/res/$folder/styles.xml',
            ).readAsStringSync(),
          ),
          isTrue,
        );
      }
    });

    test('the external camera intent is gone', () {
      expect(manifest, isNot(contains('IMAGE_CAPTURE')));
    });

    test('other apps cannot reach the widget entry', () {
      expect(
        RegExp(
          r'android:name="\.QuickCameraEntry"\s+android:exported="false"',
        ).hasMatch(manifest),
        isTrue,
      );
    });
  });
}
