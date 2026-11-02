// Phase 31: 'Chia sẻ' on the camera review and in the journal viewer, the
// choice sheet and the framed image.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/bump_photo.dart';
import 'package:momcare/core/models/week_detail_model.dart';
import 'package:momcare/core/services/bump_photo_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/share_helper.dart';
import 'package:momcare/core/widgets/brand_mark.dart';
import 'package:momcare/features/bump_journal/bump_photo_share.dart';
import 'package:momcare/features/bump_journal/screens/bump_camera_screen.dart';
import 'package:momcare/features/bump_journal/screens/bump_photo_viewer.dart';
import 'package:momcare/features/bump_journal/widgets/framed_bump_photo.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_bump_camera.dart';

const ValueKey<String> _shutter = ValueKey('bump-camera-shutter');
const ValueKey<String> _save = ValueKey('bump-camera-save');
const ValueKey<String> _retake = ValueKey('bump-camera-retake');
const ValueKey<String> _share = ValueKey('bump-camera-share');
const ValueKey<String> _original = ValueKey('bump-share-original');
const ValueKey<String> _framed = ValueKey('bump-share-framed');
const ValueKey<String> _viewerShare = ValueKey('bump-share');
const ValueKey<String> _headline = ValueKey('framed-photo-headline');

const List<int> _pngSignature = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

final WeekDetail _banana = WeekDetail(week: 20, sizeCompare: 'quả chuối');

void _setView(WidgetTester tester, [double width = 360, double height = 640]) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, height * 3);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

/// Chunk names of a PNG file.
List<String> _pngChunks(List<int> bytes) {
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final names = <String>[];
  for (var at = 8; at < bytes.length;) {
    names.add(String.fromCharCodes(bytes.sublist(at + 4, at + 8)));
    at += 12 + data.getUint32(at);
  }
  return names;
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
  late ProviderContainer scope;
  late List<ShareParams> shares;
  late List<List<int>> sharedBytes;
  Object? shareError;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('momcare_share');
    temp = Directory('${root.path}/cache')..createSync();
    docs = Directory('${root.path}/docs')..createSync();
    camera = FakeBumpCamera(temp);
    scope = ProviderContainer();
    shares = [];
    sharedBytes = [];
    shareError = null;
    BumpCameraScreen.debugSource = () => camera;
    BumpPhotoService.debugDocumentsDir = () async => docs;
    ShareHelper.debugTempDir = () async => temp;
    ShareHelper.debugOwnsTempDir = () => true;
    ShareHelper.debugShare = (params) async {
      sharedBytes.add(File(params.files!.single.path).readAsBytesSync());
      shares.add(params);
      final error = shareError;
      if (error != null) throw error;
    };
    ContentPackService.debugWeekDetails = {20: _banana};
  });

  tearDown(() {
    scope.dispose();
    BumpCameraScreen.debugSource = null;
    BumpPhotoService.resetDebugDocumentsDir();
    ShareHelper.resetDebugOverrides();
    ContentPackService.debugWeekDetails = const {};
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  Widget app(Widget home, {double textScale = 1, ThemeData? theme}) =>
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: home,
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Real time and frames until [done]: the flow does real file work, and a
  /// spinner keeps `pumpAndSettle` from ending.
  Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await settle(tester);
    }
    expect(done(), isTrue);
  }

  Future<void> untilFound(WidgetTester tester, Finder finder) =>
      settleUntil(tester, () => finder.evaluate().isNotEmpty);

  Future<void> reviewFromCaller(
    WidgetTester tester, {
    double textScale = 1,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      app(
        _Opener(() => const BumpCameraScreen(week: 20)),
        textScale: textScale,
        theme: theme,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    await settle(tester);
    await tester.tap(find.byKey(_shutter));
    await settle(tester);
    expect(find.byKey(_share), findsOneWidget);
  }

  /// Taps 'Chia sẻ' and waits for the fully open sheet.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(_share));
    await untilFound(tester, find.byKey(_original));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> backAtCaller(WidgetTester tester) async {
    await settleUntil(
      tester,
      () => find.byType(BumpCameraScreen).evaluate().isEmpty,
    );
    await settle(tester);
    expect(find.byType(_Opener), findsOneWidget);
  }

  List<String> tempNames() =>
      temp.listSync().map((e) => e.uri.pathSegments.last).toList();

  void expectSavedOnce() {
    expect(scope.read(bumpPhotoProvider), hasLength(1));
    expect(
      Directory('${docs.path}/${BumpPhotoService.folderName}').listSync(),
      hasLength(1),
    );
  }

  group('31.1 camera review', () {
    testWidgets('Lưu is primary; Chia sẻ and Chụp lại are secondary', (
      tester,
    ) async {
      _setView(tester);
      await reviewFromCaller(tester);
      expect(tester.widget(find.byKey(_save)), isA<FilledButton>());
      expect(tester.widget(find.byKey(_share)), isA<OutlinedButton>());
      expect(tester.widget(find.byKey(_retake)), isA<OutlinedButton>());
      expect(find.text('Chia sẻ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    testWidgets('waits for the crop, saves, then asks; dismissing keeps the '
        'photo and returns like Lưu', (tester) async {
      _setView(tester);
      final gate = camera.finishGate = Completer<void>();
      await reviewFromCaller(tester);

      await tester.tap(find.byKey(_share));
      await settle(tester);
      expect(scope.read(bumpPhotoProvider), isEmpty);
      expect(find.byKey(_original), findsNothing);
      for (final key in [_save, _share, _retake]) {
        expect(
          tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed,
          isNull,
        );
      }

      gate.complete();
      await untilFound(tester, find.byKey(_original));
      await tester.pump(const Duration(milliseconds: 400));
      expectSavedOnce();
      expect(find.text('Ảnh gốc'), findsOneWidget);
      expect(find.text('Ảnh kèm khung MomCare+'), findsOneWidget);
      // The review stays behind the sheet.
      expect(
        find.byKey(const ValueKey('bump-camera-review-photo')),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(10, 10));
      await backAtCaller(tester);
      expectSavedOnce();
      expect(shares, isEmpty);
      expect(find.text('Đã lưu ảnh vào tuần 20'), findsOneWidget);
      expect(tempNames(), isEmpty);
    });

    testWidgets('double tap saves once and opens one sheet', (tester) async {
      _setView(tester);
      final gate = camera.finishGate = Completer<void>();
      await reviewFromCaller(tester);
      await tester.tap(find.byKey(_share));
      await tester.tap(find.byKey(_share), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.byKey(_share), warnIfMissed: false);
      gate.complete();
      await untilFound(tester, find.byKey(_original));
      await settle(tester);
      expect(find.byKey(_original), findsOneWidget);
      expectSavedOnce();
      await tester.tap(find.byKey(_original));
      await backAtCaller(tester);
      expect(shares, hasLength(1));
      expectSavedOnce();
    });

    testWidgets('Ảnh gốc shares the saved file and leaves it in place', (
      tester,
    ) async {
      _setView(tester);
      await reviewFromCaller(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(_original));
      await backAtCaller(tester);

      final photo = scope.read(bumpPhotoProvider).single;
      final saved =
          '${docs.path}/${BumpPhotoService.folderName}/'
          '${photo.fileName}';
      final file = shares.single.files!.single;
      expect(file.path.replaceAll('\\', '/'), saved.replaceAll('\\', '/'));
      expect(file.mimeType, 'image/jpeg');
      expect(File(saved).existsSync(), isTrue);
      expect(find.text('Đã lưu ảnh vào tuần 20'), findsOneWidget);
      expect(tempNames(), isEmpty);
    });

    testWidgets('the framed image is a PNG without metadata, removed from '
        'the temp folder after sharing', (tester) async {
      _setView(tester);
      await reviewFromCaller(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(_framed));
      await backAtCaller(tester);

      final file = shares.single.files!.single;
      expect(file.path, endsWith('momcare_tuan_20.png'));
      expect(file.mimeType, 'image/png');
      expect(shares.single.text, isNull);
      final bytes = sharedBytes.single;
      expect(bytes.take(8).toList(), _pngSignature);
      expect(
        _pngChunks(
          bytes,
        ).toSet().intersection({'tEXt', 'iTXt', 'zTXt', 'eXIf', 'tIME'}),
        isEmpty,
      );
      expectSavedOnce();
      expect(tempNames(), isEmpty);
      expect(find.text('Đã lưu ảnh vào tuần 20'), findsOneWidget);
    });

    testWidgets('a failing share explains in Vietnamese, the photo stays '
        'saved and no temp file is left', (tester) async {
      _setView(tester);
      shareError = StateError('no sheet');
      await reviewFromCaller(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(_framed));
      await backAtCaller(tester);
      expect(shares, hasLength(1));
      expectSavedOnce();
      expect(find.text(BumpCameraScreen.shareErrorMessage(20)), findsOneWidget);
      expect(find.text('Đã lưu ảnh vào tuần 20'), findsNothing);
      expect(tempNames(), isEmpty);
    });

    testWidgets('a failed save shows no sheet and keeps the review', (
      tester,
    ) async {
      _setView(tester);
      // A file where the photo folder should be.
      File('${docs.path}/${BumpPhotoService.folderName}').writeAsBytesSync([1]);
      await reviewFromCaller(tester);
      await tester.tap(find.byKey(_share));
      await untilFound(tester, find.text(BumpCameraScreen.saveErrorMessage));
      expect(find.byKey(_original), findsNothing);
      expect(shares, isEmpty);
      expect(find.byKey(_save), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(_share)).onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('Chụp lại and Chia sẻ stay one line and the same height at '
          'x$scale', (tester) async {
        _setView(tester);
        await reviewFromCaller(tester, textScale: scale);
        expect(
          tester.getSize(find.byKey(_retake)).height,
          tester.getSize(find.byKey(_share)).height,
        );
        expect(tester.getSize(find.byKey(_retake)).height, greaterThan(39));
        for (final label in ['Chụp lại', 'Chia sẻ']) {
          expect(tester.widget<Text>(find.text(label)).maxLines, 1);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await settle(tester);
      });
    }

    testWidgets('the sheet says Ảnh gốc goes as is and keeps clear of the '
        'gesture bar', (tester) async {
      _setView(tester);
      tester.view.viewPadding = const FakeViewPadding(bottom: 72);
      addTearDown(tester.view.resetViewPadding);
      await reviewFromCaller(tester);
      await openSheet(tester);
      expect(
        find.text('Gửi nguyên bản, có thể còn thông tin trong tệp ảnh.'),
        findsOneWidget,
      );
      expect(
        tester.getBottomLeft(find.byKey(_framed)).dy,
        lessThanOrEqualTo(640 - 24 - 16),
      );
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('review and sheet, no overflow at 360x640 x$scale, '
            '${theme.brightness.name}', (tester) async {
          _setView(tester);
          await reviewFromCaller(tester, textScale: scale, theme: theme);
          expect(tester.takeException(), isNull);
          await openSheet(tester);
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byKey(_framed)).width, 360);
          await tester.pumpWidget(const SizedBox());
          await settle(tester);
        });
      }
    }
  });

  group('31.2 framed image', () {
    Future<void> pumpFramed(WidgetTester tester, WeekDetail detail) async {
      final image = await tester.runAsync(() => createTestImage(width: 8));
      addTearDown(image!.dispose);
      await tester.pumpWidget(
        app(
          Center(
            child: FramedBumpPhoto(image: image, detail: detail),
          ),
          textScale: 1.5,
        ),
      );
    }

    String headline(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(_headline)).data!;

    testWidgets('week, size comparison and the mark, at a fixed size', (
      tester,
    ) async {
      _setView(tester);
      await pumpFramed(tester, _banana);
      expect(headline(tester), 'Tuần 20 – bé to bằng quả chuối');
      expect(find.text('MomCare+'), findsOneWidget);
      expect(find.byType(BrandMark), findsOneWidget);
      expect(
        tester.getSize(find.byType(FramedBumpPhoto)),
        const Size(360, 450),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back when the week has no size comparison', (
      tester,
    ) async {
      _setView(tester);
      for (final size in [null, '  ']) {
        await pumpFramed(tester, WeekDetail(week: 7, sizeCompare: size));
        expect(headline(tester), 'Tuần 7 thai kỳ của mẹ');
      }
    });

    testWidgets('a very long size comparison stays in the frame', (
      tester,
    ) async {
      _setView(tester);
      await pumpFramed(
        tester,
        WeekDetail(
          week: 30,
          sizeCompare:
              'quả đu đủ rất to và một cái tên dài để thử tràn dòng '
              'trong phần chữ dưới ảnh của khung chia sẻ',
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 1080 x 1350 and the overlay is left clean', (
      tester,
    ) async {
      _setView(tester);
      final file = File('${temp.path}/wide.png')
        ..writeAsBytesSync(
          img.encodePng(
            img.fill(
              img.Image(width: 64, height: 32),
              color: img.ColorRgb8(0, 200, 0),
            ),
          ),
        );
      await tester.pumpWidget(app(const Scaffold(body: SizedBox())));
      final overlay = tester.state<OverlayState>(find.byType(Overlay).first);
      Uint8List? bytes;
      unawaited(
        BumpPhotoShare.renderFramed(
          overlay,
          file,
          _banana,
        ).then((value) => bytes = value),
      );
      await settleUntil(tester, () => bytes != null);
      await settle(tester);
      final png = img.decodePng(bytes!)!;
      expect((png.width, png.height), (1080, 1350));
      expect(png.exif.isEmpty, isTrue);
      // The photo itself is in the image, cropped to fill its square.
      for (final (x, y) in [(60, 60), (540, 540), (1020, 1020)]) {
        expect(png.getPixel(x, y).g, greaterThan(180), reason: '($x, $y)');
        expect(png.getPixel(x, y).r, lessThan(40), reason: '($x, $y)');
      }
      expect(find.byType(FramedBumpPhoto), findsNothing);
    });

    testWidgets('an unreadable photo fails and leaves the overlay clean', (
      tester,
    ) async {
      _setView(tester);
      final file = File('${temp.path}/bad.jpg')..writeAsBytesSync([1, 2, 3]);
      await tester.pumpWidget(app(const Scaffold(body: SizedBox())));
      final overlay = tester.state<OverlayState>(find.byType(Overlay).first);
      Object? error;
      unawaited(
        BumpPhotoShare.renderFramed(
          overlay,
          file,
          _banana,
        ).then<void>((_) {}, onError: (Object e) => error = e),
      );
      await settleUntil(tester, () => error != null);
      expect(find.byType(FramedBumpPhoto), findsNothing);
    });

    test('the temp name is one ShareHelper already removes', () {
      expect(ShareHelper.isGeneratedFileName('momcare_tuan_20.png'), isTrue);
    });
  });

  group('31.3 journal viewer', () {
    final photo = BumpPhoto(
      id: 'p1',
      week: 20,
      fileName: 'p1.png',
      addedAt: DateTime(2026, 10, 29),
    );
    late File file;

    setUp(() {
      final folder = Directory('${docs.path}/${BumpPhotoService.folderName}')
        ..createSync();
      file = File('${folder.path}/p1.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 8, height: 8)));
    });

    Future<void> pumpViewer(WidgetTester tester) async {
      await tester.pumpWidget(app(BumpPhotoViewer(photo: photo)));
      await settle(tester);
    }

    Future<void> sheet(WidgetTester tester) async {
      await tester.tap(find.byKey(_viewerShare));
      await untilFound(tester, find.byKey(_original));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('Ảnh gốc shares the file as before', (tester) async {
      _setView(tester);
      await pumpViewer(tester);
      await sheet(tester);
      await tester.tap(find.byKey(_original));
      await settleUntil(tester, () => shares.isNotEmpty);
      await settle(tester);
      final shared = shares.single.files!.single;
      expect(shared.path, endsWith('p1.png'));
      expect(shared.mimeType, 'image/png');
      expect(file.existsSync(), isTrue);
    });

    testWidgets('the frame is generated, shared and removed; a second share '
        'works', (tester) async {
      _setView(tester);
      await pumpViewer(tester);
      for (var round = 1; round <= 2; round++) {
        await sheet(tester);
        await tester.tap(find.byKey(_framed));
        await settleUntil(tester, () => shares.length == round);
        await settle(tester);
        expect(shares.last.files!.single.path, endsWith('momcare_tuan_20.png'));
        expect(tempNames(), isEmpty);
      }
      expect(file.existsSync(), isTrue);
    });

    testWidgets('dismissing shares nothing; a double tap opens one sheet', (
      tester,
    ) async {
      _setView(tester);
      await pumpViewer(tester);
      await tester.tap(find.byKey(_viewerShare));
      await tester.tap(find.byKey(_viewerShare), warnIfMissed: false);
      await untilFound(tester, find.byKey(_original));
      await settle(tester);
      expect(find.byKey(_original), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await settleUntil(tester, () => find.byKey(_original).evaluate().isEmpty);
      await settle(tester);
      expect(shares, isEmpty);
      expect(find.byType(BumpPhotoViewer), findsOneWidget);
    });

    testWidgets('a broken photo shows the error', (tester) async {
      _setView(tester);
      await pumpViewer(tester);
      file.writeAsBytesSync([1, 2, 3]);
      await sheet(tester);
      await tester.tap(find.byKey(_framed));
      await untilFound(tester, find.text(BumpPhotoShare.errorMessage));
      expect(shares, isEmpty);
      expect(tempNames(), isEmpty);
      expect(file.existsSync(), isTrue);
    });

    testWidgets('a missing file shows the error without asking', (
      tester,
    ) async {
      _setView(tester);
      await pumpViewer(tester);
      file.deleteSync();
      await tester.tap(find.byKey(_viewerShare));
      await untilFound(tester, find.text(BumpPhotoShare.errorMessage));
      expect(find.byKey(_original), findsNothing);
    });

    test('deleting a photo clears share copies, not other temp files, and '
        'sharing alone leaves the copies for the receiving app', () async {
      final copies = Directory('${temp.path}/${ShareHelper.sharePlusFolder}')
        ..createSync();
      final copy = File('${copies.path}/p1.png')..writeAsBytesSync([1]);
      final framedCopy = File('${copies.path}/momcare_tuan_20.png')
        ..writeAsBytesSync([1]);
      final framed = File('${temp.path}/momcare_tuan_20.png')
        ..writeAsBytesSync([1]);
      final other = File('${temp.path}/other.png')..writeAsBytesSync([1]);

      await ShareHelper.shareFile(file.path, mimeType: 'image/png');
      expect(copy.existsSync(), isTrue);

      final notifier = scope.read(bumpPhotoProvider.notifier);
      await notifier.ready;
      await notifier.delete(photo);
      for (var i = 0; i < 100 && copies.existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(file.existsSync(), isFalse);
      expect(copies.existsSync(), isFalse);
      expect(framedCopy.existsSync(), isFalse);
      expect(framed.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);
    });

    test('clearing share copies never throws', () async {
      ShareHelper.debugTempDir = () async => throw StateError('no temp');
      expect(await ShareHelper.clearShareCopies(), 0);
      ShareHelper.debugTempDir = () async => Directory('${root.path}/nope');
      expect(await ShareHelper.clearShareCopies(), 0);
    });

    test('delete-all clears a frame left behind', () async {
      final left = await ShareHelper.writeTempFile(
        'momcare_tuan_20.png',
        Uint8List.fromList([1]),
      );
      await ShareHelper.clearTempFiles();
      expect(left.existsSync(), isFalse);
    });
  });
}
