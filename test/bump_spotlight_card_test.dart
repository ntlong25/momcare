// Bump photo card on Hôm nay and Tuần thai: both states, missing files,
// order, pre-pregnancy, no overflow at 360 dp x1.5, both themes, contrast.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/appointment_model.dart';
import 'package:momcare/core/models/bump_photo.dart';
import 'package:momcare/core/models/health_log_model.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/services/bump_photo_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/features/bump_journal/bump_image_source.dart';
import 'package:momcare/features/bump_journal/screens/bump_camera_screen.dart';
import 'package:momcare/features/bump_journal/screens/bump_journal_screen.dart';
import 'package:momcare/features/bump_journal/widgets/bump_spotlight_card.dart';
import 'package:momcare/features/home/screens/home_screen.dart';
import 'package:momcare/features/home/screens/pre_pregnancy_home_screen.dart';
import 'package:momcare/features/tracking/screens/tracking_screen.dart';
import 'package:momcare/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_bump_camera.dart';

const int _week = 17;
const ValueKey<String> _homeKey = ValueKey('home-bump-photo');
const ValueKey<String> _trackingKey = ValueKey('tracking-bump-journal');
const ValueKey<String> _camera = ValueKey('bump-spotlight-camera');
const ValueKey<String> _recent = ValueKey('bump-spotlight-recent');

final Map<String, ThemeData> _themes = {
  'light': AppTheme.light(),
  'dark': AppTheme.dark(),
};

class _FakeSource implements BumpImageSource {
  @override
  Future<List<XFile>> pickFromGallery() async => const [];

  @override
  Future<List<XFile>> retrieveLost() async => const [];
}

class _DirectoryAssetBundle extends CachingAssetBundle {
  final String root;

  _DirectoryAssetBundle(this.root);

  String _resolve(String key) =>
      '$root/${key.replaceFirst('assets/content/', '')}';

  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(File(_resolve(key)).readAsBytesSync()),
  );

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      File(_resolve(key)).readAsString();
}

Future<void> _loadAppFont() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      File(
        'assets/fonts/BeVietnamPro-$weight.ttf',
      ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

PregnancyModel _pregnancy() {
  final now = DateTime.now();
  return PregnancyModel(
    id: 'p',
    motherName: 'An',
    dueDate: PregnancyModel.dueDateFromLastPeriod(
      DateTime(now.year, now.month, now.day - _week * 7 - 3),
    ),
    createdAt: now,
    updatedAt: now,
  );
}

BumpPhoto _photo(String id, int week, {int minute = 0}) => BumpPhoto(
  id: id,
  week: week,
  fileName: '$id.jpg',
  addedAt: DateTime(2026, 1, 1, 8, minute),
);

Widget _app(Widget home, {ThemeData? theme, double textScale = 1}) =>
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    );

void _setView(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, height * 3);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late Directory tempDir;
  late Directory photoDir;
  late Box<PregnancyModel> pregnancies;
  late List<dynamic> guides;
  late FakeBumpCamera camera;

  setUpAll(() async {
    await _loadAppFont();
    guides = await ContentPackService.loadGuides(
      _DirectoryAssetBundle('assets/content'),
    );
    Hive.init(Directory.systemTemp.createTempSync('momcare_bump_hive').path);
    if (!Hive.isAdapterRegistered(PregnancyModelAdapter().typeId)) {
      Hive.registerAdapter(PregnancyModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppointmentModelAdapter().typeId)) {
      Hive.registerAdapter(AppointmentModelAdapter());
    }
    pregnancies = await Hive.openBox<PregnancyModel>(AppConstants.pregnancyBox);
    if (!Hive.isAdapterRegistered(HealthLogModelAdapter().typeId)) {
      Hive.registerAdapter(HealthLogModelAdapter());
    }
    await Hive.openBox<AppointmentModel>(AppConstants.appointmentBox);
    await Hive.openBox<HealthLogModel>(AppConstants.healthLogBox);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('momcare_bump_card');
    photoDir = Directory('${tempDir.path}/${BumpPhotoService.folderName}')
      ..createSync();
    BumpPhotoService.debugDocumentsDir = () async => tempDir;
    BumpJournalScreen.debugImageSource = _FakeSource.new;
    camera = FakeBumpCamera(tempDir);
    BumpCameraScreen.debugSource = () => camera;
    final pregnancy = _pregnancy();
    await pregnancies.put(pregnancy.id, pregnancy);
  });

  tearDown(() async {
    BumpPhotoService.resetDebugDocumentsDir();
    BumpJournalScreen.debugImageSource = null;
    BumpCameraScreen.debugSource = null;
    ContentPackService.debugGuides = const [];
    await pregnancies.clear();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Saves [photos]; a file is written for those not in [missing].
  void seed(List<BumpPhoto> photos, {Set<String> missing = const {}}) {
    for (final photo in photos) {
      if (missing.contains(photo.id)) continue;
      File('${photoDir.path}/${photo.fileName}').writeAsBytesSync([1, 2, 3]);
    }
    SharedPreferences.setMockInitialValues({
      AppConstants.appModeKey: 'pregnancy',
      AppConstants.bumpPhotosKey: BumpPhotoService.encode(photos),
    });
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
    double width = 360,
  }) async {
    _setView(tester, width, 800);
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: BumpSpotlightCard(key: _homeKey, week: _week),
          ),
        ),
        theme: theme,
        textScale: textScale,
      ),
    );
    await _settle(tester);
  }

  /// The BumpPhotoImage widgets with an existing file, by file name.
  List<String> shownFiles(WidgetTester tester) => [
    for (final image in tester.widgetList<BumpPhotoImage>(
      find.byType(BumpPhotoImage),
    ))
      image.file!.uri.pathSegments.last,
  ];

  group('states', () {
    testWidgets('no photos: invitation, no strip, button opens the camera '
        'on the current week', (tester) async {
      seed(const []);
      BumpJournalScreen.debugCurrentWeek = () => 3;
      addTearDown(() => BumpJournalScreen.debugCurrentWeek = null);
      await pumpCard(tester);
      expect(find.text('Tuần $_week đã có ảnh chưa?'), findsOneWidget);
      expect(find.text('Chụp ảnh'), findsOneWidget);
      expect(find.byKey(_recent), findsNothing);
      expect(find.byType(BumpPhotoImage), findsNothing);

      await tester.tap(find.byKey(_camera));
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsOneWidget);
      expect(find.byType(BumpJournalScreen), findsNothing);
      expect(find.text('Tuần $_week'), findsOneWidget);
    });

    testWidgets('invitation: thumbnails left, button at the right edge', (
      tester,
    ) async {
      seed([_photo('a', 10)]);
      await pumpCard(tester);
      final wrap = tester.getRect(find.byType(Wrap));
      expect(tester.getTopLeft(find.byKey(_recent)).dx, wrap.left);
      expect(tester.getTopRight(find.byKey(_camera)).dx, wrap.right);
    });

    testWidgets('photo this week: newest as the thumbnail, week count, '
        'tap opens the journal', (tester) async {
      seed([
        _photo('old', _week),
        _photo('new', _week, minute: 5),
        _photo('earlier', _week - 1),
      ]);
      await pumpCard(tester);
      expect(find.text('Ảnh bụng tuần $_week'), findsOneWidget);
      expect(find.text('2 ảnh trong tuần này'), findsOneWidget);
      expect(find.byKey(_camera), findsNothing);
      expect(find.byKey(_recent), findsNothing);
      expect(shownFiles(tester), ['new.jpg']);

      await tester.tap(find.text('Ảnh bụng tuần $_week'));
      await tester.pumpAndSettle();
      expect(find.byType(BumpJournalScreen), findsOneWidget);
    });

    testWidgets('older photos, none this week: up to 3 most recent '
        'thumbnails', (tester) async {
      seed([
        _photo('w10', 10),
        _photo('w14', 14),
        _photo('w15a', 15),
        _photo('w15b', 15, minute: 5),
        _photo('w16', 16),
        _photo('later', _week + 1),
      ]);
      await pumpCard(tester);
      expect(find.text('Tuần $_week đã có ảnh chưa?'), findsOneWidget);
      expect(find.byKey(_recent), findsOneWidget);
      expect(shownFiles(tester), ['w16.jpg', 'w15b.jpg', 'w15a.jpg']);
    });

    testWidgets('a photo of a later week alone keeps the plain invitation', (
      tester,
    ) async {
      seed([_photo('later', _week + 1)]);
      await pumpCard(tester);
      expect(find.text('Tuần $_week đã có ảnh chưa?'), findsOneWidget);
      expect(find.byKey(_recent), findsNothing);
    });
  });

  group('camera', () {
    testWidgets('one tap on Chụp ảnh opens the camera once; cancel returns '
        'to the card with nothing added', (tester) async {
      seed(const []);
      await pumpCard(tester);
      await tester.tap(find.byKey(_camera));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(camera.opened, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('bump-camera-close')));
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(find.byKey(_camera), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('tapping the rest of the card does not start the camera', (
      tester,
    ) async {
      seed(const []);
      await pumpCard(tester);
      await tester.tap(find.text('Tuần $_week đã có ảnh chưa?'));
      await tester.pumpAndSettle();
      expect(find.byType(BumpJournalScreen), findsOneWidget);
      expect(find.byType(BumpCameraScreen), findsNothing);
    });

    testWidgets('a photo card tap does not start the camera', (tester) async {
      seed([_photo('p', _week)]);
      await pumpCard(tester);
      await tester.tap(find.text('Ảnh bụng tuần $_week'));
      await tester.pumpAndSettle();
      expect(find.byType(BumpJournalScreen), findsOneWidget);
      expect(find.byType(BumpCameraScreen), findsNothing);
    });
  });

  group('missing files', () {
    testWidgets('latest photo shows the placeholder', (tester) async {
      seed([_photo('gone', _week)], missing: {'gone'});
      await pumpCard(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Ảnh bụng tuần $_week'), findsOneWidget);
      expect(find.byType(BumpPhotoPlaceholder), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('strip shows a placeholder per missing file', (tester) async {
      seed(
        [_photo('a', 10), _photo('b', 11), _photo('c', 12)],
        missing: {'a', 'b', 'c'},
      );
      await pumpCard(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(BumpPhotoPlaceholder), findsNWidgets(3));
    });

    testWidgets('undecodable file falls back to the placeholder', (
      tester,
    ) async {
      seed([_photo('bad', _week)]);
      await pumpCard(tester);
      expect(find.byType(Image), findsOneWidget);
      // The file is read and decoded on real async, finishing in steps.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(BumpPhotoPlaceholder), findsOneWidget);
    });
  });

  group('screens', () {
    void expectBelow(WidgetTester tester, Key lower, Key upper) {
      expect(
        tester.getTopLeft(find.byKey(lower)).dy,
        greaterThan(tester.getBottomLeft(find.byKey(upper)).dy - 1),
      );
    }

    for (final withPhoto in [false, true]) {
      testWidgets('Hôm nay: right after the hero, milestone stays near the '
          'top at 411 dp (photo: $withPhoto)', (tester) async {
        seed(withPhoto ? [_photo('p', _week)] : const []);
        ContentPackService.debugGuides = guides.cast();
        _setView(tester, 411, 891);
        await tester.pumpWidget(_app(const HomeScreen()));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        const hero = ValueKey('home-day-card');
        const milestone = ValueKey('next-milestone-card');
        expectBelow(tester, _homeKey, hero);
        expectBelow(tester, milestone, _homeKey);
        expect(tester.getTopLeft(find.byKey(milestone)).dy, lessThan(480));
        expect(tester.getSize(find.byKey(_homeKey)).height, lessThan(170));
      });
    }

    testWidgets('Tuần thai: directly after the week header, before the '
        'week detail button', (tester) async {
      seed(const []);
      _setView(tester, 411, 891);
      await tester.pumpWidget(_app(const TrackingScreen(showAppBar: false)));
      await _settle(tester);
      const header = ValueKey('tracking-week-header');
      expectBelow(tester, _trackingKey, header);
      expect(
        tester.getTopLeft(find.text('Xem chi tiết tuần $_week')).dy,
        greaterThan(tester.getBottomLeft(find.byKey(_trackingKey)).dy - 1),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(_trackingKey),
          matching: find.byKey(_camera),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsOneWidget);
    });

    for (final withPhoto in [false, true]) {
      testWidgets('Tuần thai: card edges line up with the hero '
          '(photo: $withPhoto)', (tester) async {
        seed(withPhoto ? [_photo('p', _week)] : const []);
        _setView(tester, 411, 891);
        await tester.pumpWidget(_app(const TrackingScreen(showAppBar: false)));
        await _settle(tester);
        final hero = tester.getRect(
          find.byKey(const ValueKey('tracking-week-header')),
        );
        final card = tester.getRect(
          find.descendant(
            of: find.byKey(_trackingKey),
            matching: find.byType(Card),
          ),
        );
        expect(card.left, hero.left);
        expect(card.right, hero.right);
      });
    }

    testWidgets('not shown in pre-pregnancy mode', (tester) async {
      seed([_photo('p', _week)]);
      _setView(tester, 360, 800);
      final today = DateTime.now();
      await tester.pumpWidget(
        _app(
          PrePregnancyHomeScreen(
            debugCycles: const [],
            debugToday: DateTime(today.year, today.month, today.day),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(BumpSpotlightCard), findsNothing);
    });

    testWidgets('not shown without an active pregnancy', (tester) async {
      seed([_photo('p', _week)]);
      await tester.runAsync(pregnancies.clear);
      _setView(tester, 360, 800);
      await tester.pumpWidget(_app(const HomeScreen()));
      await _settle(tester);
      expect(find.byType(BumpSpotlightCard), findsNothing);
      await tester.pumpWidget(_app(const TrackingScreen(showAppBar: false)));
      await _settle(tester);
      expect(find.byType(BumpSpotlightCard), findsNothing);
    });
  });

  for (final MapEntry(key: name, value: theme) in _themes.entries) {
    final states = <String, List<BumpPhoto> Function()>{
      'invitation': () => const [],
      'strip': () => [_photo('a', 10), _photo('b', 11), _photo('c', 12)],
      'photo': () => [_photo('p', _week)],
    };
    for (final MapEntry(key: state, value: photos) in states.entries) {
      testWidgets('no overflow at 360 dp x1.5, real font ($name, $state)', (
        tester,
      ) async {
        seed(photos());
        await pumpCard(tester, theme: theme, textScale: 1.5);
        expect(tester.takeException(), isNull);
      });

      testWidgets('text contrast ($name, $state)', (tester) async {
        final handle = tester.ensureSemantics();
        seed(photos());
        await pumpCard(tester, theme: theme, width: 411);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }

    test('card and button colours keep 4.5:1 ($name)', () {
      final s = theme.colorScheme;
      final sem = theme.extension<AppSemanticColors>()!;
      expect(
        _contrast(sem.onSpotlightContainer, sem.spotlightContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(_contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(s.primary, sem.spotlightContainer),
        greaterThanOrEqualTo(3),
      );
    });

    test('spotlight fill differs from hero, peach and mint ($name)', () {
      final sem = theme.extension<AppSemanticColors>()!;
      for (final other in [
        theme.colorScheme.primaryContainer,
        sem.peachContainer,
        sem.mintContainer,
      ]) {
        expect(sem.spotlightContainer, isNot(other));
      }
    });
  }

  testWidgets('card is not peach or mint', (tester) async {
    seed(const []);
    await pumpCard(tester);
    // Same light look as before the dark token was added.
    final card = tester.widget<Card>(find.byType(Card).first);
    expect(card.color, AppTheme.light().colorScheme.secondaryContainer);
  });
}
