import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/models/bump_photo.dart';
import 'package:momcare/core/models/health_log_model.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/models/week_detail_model.dart';
import 'package:momcare/core/services/bump_photo_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/share_helper.dart';
import 'package:momcare/features/bump_journal/bump_image_source.dart';
import 'package:momcare/features/bump_journal/screens/bump_camera_screen.dart';
import 'package:momcare/features/bump_journal/screens/bump_journal_screen.dart';
import 'package:momcare/features/bump_journal/screens/bump_photo_viewer.dart';
import 'package:momcare/features/health_diary/export/health_report.dart';
import 'package:momcare/features/health_diary/screens/health_report_export_screen.dart';
import 'package:momcare/features/milestone_card/milestone_card_text.dart';
import 'package:momcare/features/milestone_card/screens/milestone_card_screen.dart';
import 'package:momcare/features/tracking/screens/week_detail_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_bump_camera.dart';

/// 1x1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);
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

final DateTime _now = DateTime(2026, 10, 29, 10);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

final ThemeData _light = AppTheme.light();
final ThemeData _dark = AppTheme.dark();

void _setView(WidgetTester tester, [Size logical = const Size(360, 640)]) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = logical * 3;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _app(Widget home, {double textScale = 1.0, ThemeData? theme}) =>
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? _light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    );

/// Waits (in real time, inside `runAsync`) for [condition].
Future<void> _until(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('condition not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  // Let the rest of the handler (save, snackbar, finally) finish.
  await Future<void>.delayed(const Duration(milliseconds: 100));
}

class _FakeSource implements BumpImageSource {
  _FakeSource(this.dir);

  final Directory dir;
  int _counter = 0;

  /// Next gallery result; null = cancel.
  int galleryCount = 0;
  Object? galleryError;

  XFile _file(String ext) {
    final file = File('${dir.path}/pick_${_counter++}$ext')
      ..writeAsBytesSync(_png);
    return XFile(file.path);
  }

  @override
  Future<List<XFile>> pickFromGallery() async {
    final error = galleryError;
    if (error != null) throw error;
    return [for (var i = 0; i < galleryCount; i++) _file('.png')];
  }

  @override
  Future<List<XFile>> retrieveLost() async => const [];
}

HealthLogModel _log(
  String id,
  DateTime date, {
  double? weight,
  int? systolic,
  int? diastolic,
  List<String>? symptoms,
  String? notes,
}) => HealthLogModel(
  id: id,
  date: date,
  weight: weight,
  systolicBP: systolic,
  diastolicBP: diastolic,
  symptoms: symptoms,
  notes: notes,
  createdAt: date,
  updatedAt: date,
);

PregnancyModel _pregnancy({String? name}) => PregnancyModel(
  id: 'p',
  // Week 0 starts on 2026-05-01 -> week 25 on _now.
  dueDate: PregnancyModel.dueDateFromLastPeriod(DateTime(2026, 5, 1)),
  motherName: name,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

HealthReportFonts _diskFonts() {
  ByteData read(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());
  return HealthReportFonts(
    regular: pw.Font.ttf(read(HealthReportFonts.regularAsset)),
    bold: pw.Font.ttf(read(HealthReportFonts.boldAsset)),
  );
}

String _ascii(List<int> bytes, int count) =>
    String.fromCharCodes(bytes.take(count));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late Directory docsDir;
  late Directory cacheDir;

  setUp(() async {
    tempRoot = Directory.systemTemp.createTempSync('momcare_p21_');
    docsDir = Directory('${tempRoot.path}/docs')..createSync();
    cacheDir = Directory('${tempRoot.path}/cache')..createSync();
    BumpPhotoService.debugDocumentsDir = () async => docsDir;
    ShareHelper.debugTempDir = () async => cacheDir;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    BumpPhotoService.resetDebugDocumentsDir();
    ShareHelper.resetDebugOverrides();
    BumpJournalScreen.debugImageSource = null;
    BumpJournalScreen.debugCurrentWeek = null;
    HealthReportFonts.debugLoad = null;
    try {
      tempRoot.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('21.1 font asset', () {
    test('Be Vietnam Pro TTFs and OFL.txt are bundled', () {
      for (final path in [
        HealthReportFonts.regularAsset,
        HealthReportFonts.boldAsset,
      ]) {
        final bytes = File(path).readAsBytesSync();
        expect(bytes.length, greaterThan(10000), reason: path);
        final magic = bytes.take(4).toList();
        final isTrueType =
            _listEquals(magic, [0, 1, 0, 0]) || _ascii(magic, 4) == 'true';
        expect(isTrueType, isTrue, reason: '$path is not a TTF');
      }
      final ofl = File('assets/fonts/OFL.txt');
      expect(ofl.existsSync(), isTrue);
      expect(ofl.readAsStringSync(), contains('SIL Open Font License'));
    });
  });

  group('21.2 BumpPhoto and BumpPhotoService', () {
    final photo = BumpPhoto(
      id: 'a',
      week: 20,
      fileName: 'a.jpg',
      addedAt: DateTime(2026, 10, 1, 9),
      takenAt: DateTime(2026, 9, 30, 8),
    );

    test('JSON round-trip', () {
      expect(BumpPhoto.fromJson(photo.toJson()), photo);
      final decoded = BumpPhotoService.decode(BumpPhotoService.encode([photo]));
      expect(decoded, [photo]);
    });

    test('corrupt values and invalid entries are dropped', () {
      expect(BumpPhotoService.decode(null), isEmpty);
      expect(BumpPhotoService.decode('not json'), isEmpty);
      expect(BumpPhotoService.decode('{"a":1}'), isEmpty);
      final raw = jsonEncode([
        photo.toJson(),
        {'id': '', 'week': 3, 'fileName': 'x.jpg', 'addedAt': '2026-01-01'},
        {'id': 'b', 'week': 43, 'fileName': 'x.jpg', 'addedAt': '2026-01-01'},
        {'id': 'c', 'week': -1, 'fileName': 'x.jpg', 'addedAt': '2026-01-01'},
        {'id': 'd', 'week': 3, 'addedAt': '2026-01-01'},
        {'id': 'e', 'week': 3, 'fileName': 'x.jpg', 'addedAt': 'bad'},
        {'id': 'f', 'week': 3, 'fileName': '../x.jpg', 'addedAt': '2026-01-01'},
        {'id': 'g', 'week': '3', 'fileName': 'x.jpg', 'addedAt': '2026-01-01'},
        42,
      ]);
      expect(BumpPhotoService.decode(raw), [photo]);
    });

    test('decode and groupByWeek sort week desc, newest first', () {
      BumpPhoto p(String id, int week, int day) => BumpPhoto(
        id: id,
        week: week,
        fileName: '$id.jpg',
        addedAt: DateTime(2026, 10, day),
      );
      final photos = [
        p('a', 18, 1),
        p('b', 20, 2),
        p('c', 20, 3),
        p('d', 19, 4),
      ];
      final decoded = BumpPhotoService.decode(BumpPhotoService.encode(photos));
      expect(decoded.map((e) => e.id), ['c', 'b', 'd', 'a']);
      final groups = BumpPhotoService.groupByWeek(photos);
      expect(groups.map((g) => g.key), [20, 19, 18]);
      expect(groups.first.value.map((e) => e.id), ['c', 'b']);
    });

    test('extensions', () {
      expect(BumpPhotoService.extensionFor('IMG_1.JPEG'), '.jpg');
      expect(BumpPhotoService.extensionFor('a.png'), '.png');
      expect(BumpPhotoService.extensionFor('a.heic'), '.heic');
      expect(BumpPhotoService.extensionFor('a.webp'), '.webp');
      expect(BumpPhotoService.extensionFor('a.gif'), '.jpg');
      expect(BumpPhotoService.extensionFor('noext'), '.jpg');
    });

    test(
      'addFiles copies files; delete; reload; missing file; clearAll',
      () async {
        final src1 = File('${tempRoot.path}/one.png')..writeAsBytesSync(_png);
        final src2 = File('${tempRoot.path}/two.jpg')..writeAsBytesSync(_png);
        final missing = XFile('${tempRoot.path}/does_not_exist.jpg');

        final notifier = BumpPhotoNotifier(now: () => _now);
        await notifier.ready;
        final added = await notifier.addFiles(20, [
          XFile(src1.path),
          missing,
          XFile(src2.path),
        ]);
        expect(added, 2);
        expect(notifier.state, hasLength(2));
        expect(notifier.state.every((p) => p.week == 20), isTrue);
        final folder = Directory('${docsDir.path}/bump_photos');
        final files = folder.listSync().whereType<File>().toList();
        expect(files, hasLength(2));
        expect(notifier.state.map((p) => p.fileName.split('.').last).toSet(), {
          'png',
          'jpg',
        });
        // Only file names are stored, never absolute paths.
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(AppConstants.bumpPhotosKey)!;
        expect(raw.contains(docsDir.path.replaceAll('\\', '\\\\')), isFalse);

        // A fresh notifier reloads from prefs.
        final reloaded = BumpPhotoNotifier();
        await reloaded.ready;
        expect(reloaded.state, notifier.state);

        final first = notifier.state.first;
        await notifier.delete(first);
        expect(notifier.state, hasLength(1));
        expect((await BumpPhotoService.fileFor(first)).existsSync(), isFalse);
        expect(
          BumpPhotoService.decode(prefs.getString(AppConstants.bumpPhotosKey)),
          hasLength(1),
        );

        // The file is already gone: deleting the entry still works.
        final second = notifier.state.single;
        (await BumpPhotoService.fileFor(second)).deleteSync();
        await notifier.delete(second);
        expect(notifier.state, isEmpty);
        expect(prefs.getString(AppConstants.bumpPhotosKey), isNull);

        await notifier.addFiles(21, [XFile(src1.path)]);
        final unrelated = File('${docsDir.path}/other.txt')
          ..writeAsStringSync('keep');
        await BumpPhotoService.clearAll();
        expect(prefs.getString(AppConstants.bumpPhotosKey), isNull);
        expect(folder.existsSync(), isFalse);
        expect(unrelated.existsSync(), isTrue);
        notifier.resetLocal();
        expect(notifier.state, isEmpty);
      },
    );
  });

  group('21.7 ShareHelper.clearTempFiles', () {
    const uuidA = '1bfe7b5b-1111-4a2b-9c3d-0123456789ab';
    const uuidB = '9975b2ba-2222-4a2b-9c3d-0123456789ab';

    void seedCache() {
      void write(String rel) => (File(
        '${cacheDir.path}/$rel',
      )..createSync(recursive: true)).writeAsStringSync('x');
      write('momcare_tuan_20.png');
      write('momcare_nhat_ky_20260930_20261029.pdf');
      write('share_plus/ede194ea-b498-418e-a0a2-cecf819eee48.jpg');
      write('share_plus/momcare_nhat_ky_20260701_20261029.pdf');
      write('$uuidA/34.jpg');
      write('$uuidB/36.png');
      write('scaled_34.jpg');
      write('scaled_$uuidA.jpg');
      write('image_picker_5D1F.jpg');
      write('other/deep/nested.bin');
      write('other.pdf');
    }

    test('app-owned temp dir (Android/iOS): emptied recursively', () async {
      ShareHelper.debugOwnsTempDir = () => true;
      seedCache();
      expect(await ShareHelper.clearTempFiles(), 10);
      expect(cacheDir.existsSync(), isTrue);
      expect(cacheDir.listSync(recursive: true), isEmpty);
      // Nothing outside the temp dir is touched.
      expect(docsDir.existsSync(), isTrue);
    });

    test('shared temp dir (desktop): only our files and share_plus', () async {
      ShareHelper.debugOwnsTempDir = () => false;
      seedCache();
      expect(await ShareHelper.clearTempFiles(), 3);
      final left = cacheDir
          .listSync()
          .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .toSet();
      expect(left, {
        uuidA,
        uuidB,
        'scaled_34.jpg',
        'scaled_$uuidA.jpg',
        'image_picker_5D1F.jpg',
        'other',
        'other.pdf',
      });
    });

    test('a missing owned temp dir is not an error', () async {
      ShareHelper.debugOwnsTempDir = () => true;
      ShareHelper.debugTempDir = () async => Directory('${tempRoot.path}/nope');
      expect(await ShareHelper.clearTempFiles(), 0);
      expect(await ShareHelper.clearPickerLeftovers(), 0);
      expect(
        await ShareHelper.deletePickerTempFile('${tempRoot.path}/nope/a.jpg'),
        isFalse,
      );
    });

    test('clearPickerLeftovers removes only image_picker entries', () async {
      ShareHelper.debugOwnsTempDir = () => true;
      seedCache();
      expect(await ShareHelper.clearPickerLeftovers(), 5);
      final left = cacheDir
          .listSync()
          .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .toSet();
      expect(left, {
        'momcare_tuan_20.png',
        'momcare_nhat_ky_20260930_20261029.pdf',
        'share_plus',
        'other',
        'other.pdf',
      });
    });

    test(
      'deletePickerTempFile only deletes inside an owned temp dir',
      () async {
        ShareHelper.debugOwnsTempDir = () => true;
        seedCache();
        final inUuid = File('${cacheDir.path}/$uuidA/34.jpg');
        expect(await ShareHelper.deletePickerTempFile(inUuid.path), isTrue);
        expect(inUuid.existsSync(), isFalse);
        // The emptied <uuid>/ folder goes too; the temp dir itself stays.
        expect(Directory('${cacheDir.path}/$uuidA').existsSync(), isFalse);
        final scaled = File('${cacheDir.path}/scaled_34.jpg');
        expect(await ShareHelper.deletePickerTempFile(scaled.path), isTrue);
        expect(scaled.existsSync(), isFalse);
        expect(cacheDir.existsSync(), isTrue);

        // A user's original outside the temp dir is never deleted.
        final original = File('${tempRoot.path}/Pictures/IMG_1.jpg')
          ..createSync(recursive: true);
        expect(await ShareHelper.deletePickerTempFile(original.path), isFalse);
        expect(original.existsSync(), isTrue);
        final escape = '${cacheDir.path}/../Pictures/IMG_1.jpg';
        expect(await ShareHelper.deletePickerTempFile(escape), isFalse);
        expect(original.existsSync(), isTrue);
        expect(await ShareHelper.deletePickerTempFile(cacheDir.path), isFalse);
        expect(cacheDir.existsSync(), isTrue);

        // On a shared (desktop) temp dir nothing is deleted.
        ShareHelper.debugOwnsTempDir = () => false;
        final png = File('${cacheDir.path}/$uuidB/36.png');
        expect(await ShareHelper.deletePickerTempFile(png.path), isFalse);
        expect(png.existsSync(), isTrue);
      },
    );

    test('addFiles deletes the picker temp copies after storing', () async {
      ShareHelper.debugOwnsTempDir = () => true;
      seedCache();
      final picked = File('${cacheDir.path}/$uuidA/34.jpg')
        ..writeAsBytesSync(_png);
      final camera = File('${cacheDir.path}/image_picker_5D1F.jpg')
        ..writeAsBytesSync(_png);
      final notifier = BumpPhotoNotifier(now: () => _now);
      await notifier.ready;
      expect(
        await notifier.addFiles(20, [XFile(picked.path), XFile(camera.path)]),
        2,
      );
      final stored = Directory(
        '${docsDir.path}/bump_photos',
      ).listSync().whereType<File>().toList();
      expect(stored, hasLength(2));
      for (final file in stored) {
        expect(file.readAsBytesSync(), _png);
      }
      expect(picked.existsSync(), isFalse);
      expect(camera.existsSync(), isFalse);
      // Other image_picker leftovers are swept; our other temp files stay.
      expect(Directory('${cacheDir.path}/$uuidB').existsSync(), isFalse);
      expect(File('${cacheDir.path}/scaled_34.jpg').existsSync(), isFalse);
      expect(File('${cacheDir.path}/other.pdf').existsSync(), isTrue);
      expect(Directory('${cacheDir.path}/share_plus').existsSync(), isTrue);
    });

    test('share deletes only our generated temp file afterwards', () async {
      final card = await ShareHelper.writeTempFile(
        'momcare_tuan_20.png',
        Uint8List.fromList(_png),
      );
      final other = File('${cacheDir.path}/other.png')..writeAsBytesSync(_png);
      var existedDuringShare = false;
      ShareHelper.debugShare = (params) async {
        existedDuringShare = File(params.files!.first.path).existsSync();
      };
      await ShareHelper.share(
        ShareParams(
          files: [
            XFile(card.path, mimeType: 'image/png'),
            XFile(other.path, mimeType: 'image/png'),
          ],
        ),
      );
      expect(existedDuringShare, isTrue);
      expect(card.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);

      // Also after a failing share.
      final pdf = await ShareHelper.writeTempFile(
        'momcare_nhat_ky_20260930_20261029.pdf',
        Uint8List.fromList([1, 2, 3]),
      );
      ShareHelper.debugShare = (params) async => throw StateError('no sheet');
      await expectLater(
        ShareHelper.shareFile(pdf.path, mimeType: 'application/pdf'),
        throwsStateError,
      );
      expect(pdf.existsSync(), isFalse);
    });

    test('removes only generated share files', () async {
      ShareHelper.debugOwnsTempDir = () => false;
      final names = [
        'momcare_tuan_20.png',
        'momcare_nhat_ky_20260930_20261029.pdf',
        'momcare_tuan_x.png',
        'other.pdf',
        'image_picker_123.jpg',
      ];
      for (final name in names) {
        File('${cacheDir.path}/$name').writeAsStringSync('x');
      }
      expect(await ShareHelper.clearTempFiles(), 2);
      final left = cacheDir
          .listSync()
          .map((e) => e.uri.pathSegments.last)
          .toSet();
      expect(left, {'momcare_tuan_x.png', 'other.pdf', 'image_picker_123.jpg'});
    });

    test('a missing temp dir is not an error', () async {
      ShareHelper.debugTempDir = () async => Directory('${tempRoot.path}/nope');
      expect(await ShareHelper.clearTempFiles(), 0);
    });
  });

  group('21.3 BumpJournalScreen', () {
    late _FakeSource source;

    setUp(() {
      source = _FakeSource(tempRoot);
      BumpJournalScreen.debugImageSource = () => source;
      BumpJournalScreen.debugCurrentWeek = () => 20;
    });

    ProviderContainer container(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byType(BumpJournalScreen)),
        );

    Future<void> pick(WidgetTester tester, String key, int expected) async {
      await tester.runAsync(() async {
        await tester.tap(find.byKey(ValueKey(key)));
        await _until(
          () => container(tester).read(bumpPhotoProvider).length == expected,
        );
      });
      await tester.pump();
    }

    testWidgets('empty state, gallery pick, week change, viewer delete', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_app(const BumpJournalScreen()));
      await tester.pump();

      expect(find.text('Nhật ký ảnh bụng bầu'), findsOneWidget);
      expect(find.byKey(const ValueKey('bump-empty')), findsOneWidget);
      expect(find.text('Ảnh chỉ lưu trên thiết bị này.'), findsOneWidget);
      expect(find.text('Tuần 20'), findsOneWidget);

      // Cancel: nothing changes.
      source.galleryCount = 0;
      await tester.tap(find.byKey(const ValueKey('bump-gallery')));
      await tester.pump();
      expect(find.byKey(const ValueKey('bump-empty')), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      source.galleryCount = 2;
      await pick(tester, 'bump-gallery', 2);
      expect(find.text('Đã thêm 2 ảnh vào tuần 20'), findsOneWidget);
      expect(find.text('Tuần 20 · 2 ảnh'), findsOneWidget);
      expect(find.byKey(const ValueKey('bump-empty')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('bump-week-next')));
      await tester.pump();
      expect(find.text('Tuần 21'), findsOneWidget);
      source.galleryCount = 1;
      await pick(tester, 'bump-gallery', 3);
      expect(find.text('Đã thêm 1 ảnh vào tuần 21'), findsOneWidget);
      final y21 = tester.getTopLeft(find.text('Tuần 21 · 1 ảnh')).dy;
      final y20 = tester.getTopLeft(find.text('Tuần 20 · 2 ảnh')).dy;
      expect(y21, lessThan(y20));

      // Open a week-20 photo and delete it.
      final photo = container(
        tester,
      ).read(bumpPhotoProvider).firstWhere((p) => p.week == 20);
      final thumb = find.byKey(ValueKey('bump-photo-${photo.id}'));
      await tester.ensureVisible(thumb);
      await tester.tap(thumb);
      await tester.pumpAndSettle();
      expect(find.byType(BumpPhotoViewer), findsOneWidget);
      expect(find.byKey(const ValueKey('bump-viewer-week')), findsOneWidget);
      expect(find.byKey(const ValueKey('bump-viewer-date')), findsOneWidget);
      // Let the thumbnail and viewer image reads finish: Windows cannot
      // delete a file that is still open.
      await _settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('bump-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tool-confirm-delete')));
      await tester.pumpAndSettle();
      expect(find.byType(BumpPhotoViewer), findsNothing);
      expect(find.text('Tuần 20 · 1 ảnh'), findsOneWidget);
      final file = File('${docsDir.path}/bump_photos/${photo.fileName}');
      expect(file.existsSync(), isFalse);
      expect(tester.takeException(), isNull);
    });

    for (final theme in [_light, _dark]) {
      testWidgets('viewer title keeps the full date at scale 1.5, '
          '${theme.brightness.name}', (tester) async {
        _setView(tester);
        final photo = BumpPhoto(
          id: 'p1',
          week: 28,
          fileName: 'p1.jpg',
          addedAt: DateTime(2026, 10, 29),
        );
        await tester.pumpWidget(
          _app(BumpPhotoViewer(photo: photo), textScale: 1.5, theme: theme),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final week = find.byKey(const ValueKey('bump-viewer-week'));
        final date = find.byKey(const ValueKey('bump-viewer-date'));
        expect(tester.widget<Text>(week).data, 'Tuần 28');
        expect(tester.widget<Text>(date).data, '29/10/2026');
        for (final finder in [week, date]) {
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          expect(paragraph.didExceedMaxLines, isFalse);
          // The laid-out text is as wide as the whole string: not cut off.
          final full = TextPainter(
            text: paragraph.text,
            textDirection: TextDirection.ltr,
            textScaler: paragraph.textScaler,
          )..layout();
          expect(paragraph.size.width, greaterThanOrEqualTo(full.width - 0.5));
          full.dispose();
        }
        // On screen, left of the actions, inside the AppBar.
        final dateRect = tester.getRect(date);
        final shareRect = tester.getRect(
          find.byKey(const ValueKey('bump-share')),
        );
        final appBar = tester.getRect(find.byType(AppBar));
        expect(dateRect.left, greaterThanOrEqualTo(0));
        expect(dateRect.right, lessThanOrEqualTo(shareRect.left));
        expect(dateRect.top, greaterThanOrEqualTo(appBar.top));
        expect(dateRect.bottom, lessThanOrEqualTo(appBar.bottom));
        expect(dateRect.height, greaterThan(8));
      });
    }

    testWidgets('gallery permission error shows the settings hint', (
      tester,
    ) async {
      _setView(tester);
      source.galleryError = PlatformException(code: 'photo_access_denied');
      await tester.pumpWidget(_app(const BumpJournalScreen()));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('bump-gallery')));
      await tester.pump();
      expect(find.text(BumpJournalScreen.permissionMessage), findsOneWidget);
      expect(find.byKey(const ValueKey('bump-empty')), findsOneWidget);

      source.galleryError = StateError('boom');
      await tester.tap(find.byKey(const ValueKey('bump-gallery')));
      await tester.pump();
      expect(find.text(BumpJournalScreen.errorMessage), findsOneWidget);
    });

    testWidgets('camera button opens the camera on the selected week; the '
        'grid button comes back', (tester) async {
      _setView(tester);
      BumpCameraScreen.debugSource = () => FakeBumpCamera(tempRoot);
      addTearDown(() => BumpCameraScreen.debugSource = null);
      await tester.pumpWidget(_app(const BumpJournalScreen(initialWeek: 12)));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('bump-camera')));
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsOneWidget);
      expect(find.text('Tuần 12'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bump-camera-journal')));
      await tester.pumpAndSettle();
      expect(find.byType(BumpCameraScreen), findsNothing);
      expect(find.byType(BumpJournalScreen), findsOneWidget);
    });

    testWidgets('a missing file shows the placeholder', (tester) async {
      _setView(tester);
      SharedPreferences.setMockInitialValues({
        AppConstants.bumpPhotosKey: BumpPhotoService.encode([
          BumpPhoto(
            id: 'gone',
            week: 8,
            fileName: 'gone.jpg',
            addedAt: DateTime(2026, 6, 1),
          ),
        ]),
      });
      await tester.pumpWidget(_app(const BumpJournalScreen()));
      await tester.pump();
      await tester.pump();
      expect(find.text('Tuần 8 · 1 ảnh'), findsOneWidget);
      expect(find.byKey(const ValueKey('bump-photo-missing')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bump-photo-gone')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bump-photo-missing')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 1.5]) {
      for (final theme in [_light, _dark]) {
        testWidgets(
          'no overflow at 360x640, scale $scale, ${theme.brightness.name}',
          (tester) async {
            _setView(tester);
            SharedPreferences.setMockInitialValues({
              AppConstants.bumpPhotosKey: BumpPhotoService.encode([
                for (var i = 0; i < 4; i++)
                  BumpPhoto(
                    id: 'p$i',
                    week: 40 - i % 2,
                    fileName: 'p$i.jpg',
                    addedAt: DateTime(2026, 6, i + 1),
                  ),
              ]),
            });
            await tester.pumpWidget(
              _app(const BumpJournalScreen(), textScale: scale, theme: theme),
            );
            await tester.pump();
            await tester.pump();
            expect(tester.takeException(), isNull);
            await tester.tap(find.byKey(const ValueKey('bump-photo-p0')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    for (final theme in [_light, _dark]) {
      testWidgets('tonal buttons keep 4.5:1 (${theme.brightness.name})', (
        tester,
      ) async {
        _setView(tester);
        await tester.pumpWidget(_app(const BumpJournalScreen(), theme: theme));
        await tester.pump();
        for (final key in ['bump-camera', 'bump-gallery']) {
          final button = find.byKey(ValueKey(key));
          final material = tester.widget<Material>(
            find.descendant(of: button, matching: find.byType(Material)).first,
          );
          final bg = material.color!;
          final fg = material.textStyle!.color!;
          expect(bg, theme.colorScheme.secondaryContainer);
          expect(bg.a, 1.0);
          expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: key);
        }
      });
    }
  });

  group('21.4 milestone card', () {
    WeekDetail week(
      int number, {
      String? size,
      double? lengthCm,
      double? weightG,
      String? lengthLabel,
      String? weightLabel,
    }) => WeekDetail(
      week: number,
      sizeCompare: size,
      lengthCm: lengthCm,
      weightG: weightG,
      lengthLabel: lengthLabel,
      weightLabel: weightLabel,
    );

    test('headline', () {
      expect(
        MilestoneCardText.headline(week(20, size: 'quả chuối')),
        'Tuần 20 – bé to bằng quả chuối',
      );
      expect(MilestoneCardText.headline(week(3)), 'Tuần 3 thai kỳ của mẹ');
      expect(
        MilestoneCardText.headline(week(3, size: '   ')),
        'Tuần 3 thai kỳ của mẹ',
      );
    });

    test('details', () {
      expect(
        MilestoneCardText.details(week(20, lengthCm: 25.6)),
        'Dài khoảng 25.6 cm',
      );
      expect(
        MilestoneCardText.details(week(20, weightG: 300)),
        'Nặng khoảng 300 g',
      );
      expect(
        MilestoneCardText.details(week(20, lengthCm: 25.6, weightG: 300)),
        'Dài khoảng 25.6 cm · Nặng khoảng 300 g',
      );
      expect(
        MilestoneCardText.details(
          week(10, lengthLabel: '3 cm', weightLabel: '4 g'),
        ),
        'Dài khoảng 3 cm · Nặng khoảng 4 g',
      );
      expect(MilestoneCardText.details(week(2)), '');
      expect(MilestoneCardText.fileName(week(20)), 'momcare_tuan_20.png');
    });

    final weeks = {
      20: week(20, size: 'quả chuối', lengthCm: 25.6, weightG: 300),
      21: week(21, size: 'củ cà rốt', lengthCm: 26.7, weightG: 360),
    };

    testWidgets('week page actions open the card for the visible week', (
      tester,
    ) async {
      _setView(tester, const Size(600, 1000));
      await tester.pumpWidget(
        _app(
          WeekDetailScreen(initialWeek: 20, weeks: weeks, sources: const {}),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('week-share-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('week-bump-photos')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('week-share-card')));
      await tester.pumpAndSettle();
      expect(find.byType(MilestoneCardScreen), findsOneWidget);
      expect(find.text('Tuần 20 – bé to bằng quả chuối'), findsOneWidget);
      expect(
        find.text('Dài khoảng 25.6 cm · Nặng khoảng 300 g'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.fling(find.byType(PageView), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Tuần 21'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('week-share-card')));
      await tester.pumpAndSettle();
      expect(find.text('Tuần 21 – bé to bằng củ cà rốt'), findsOneWidget);
    });

    testWidgets('camera action opens the journal on that week', (tester) async {
      _setView(tester, const Size(600, 1000));
      BumpJournalScreen.debugImageSource = () => _FakeSource(tempRoot);
      await tester.pumpWidget(
        _app(
          WeekDetailScreen(initialWeek: 21, weeks: weeks, sources: const {}),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('week-bump-photos')));
      await tester.pumpAndSettle();
      expect(find.byType(BumpJournalScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('bump-week-label')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('bump-week-label'))).data,
        'Tuần 21',
      );
    });

    testWidgets('share renders a PNG and calls the share sheet once', (
      tester,
    ) async {
      _setView(tester);
      final calls = <ShareParams>[];
      List<int>? bytes;
      ShareHelper.debugShare = (params) async {
        bytes = await File(params.files!.single.path).readAsBytes();
        calls.add(params);
      };
      await tester.pumpWidget(_app(MilestoneCardScreen(detail: weeks[20]!)));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('milestone-share')));
        await _until(() => calls.isNotEmpty);
      });
      await tester.pump();
      expect(calls, hasLength(1));
      final files = calls.single.files!;
      expect(files, hasLength(1));
      expect(files.single.path, endsWith('momcare_tuan_20.png'));
      expect(files.single.mimeType, 'image/png');
      expect(calls.single.text, 'Tuần 20 – bé to bằng quả chuối');
      expect(bytes!.take(8).toList(), _pngSignature);
      // The generated card is removed from the temp folder after sharing.
      expect(File(files.single.path).existsSync(), isFalse);
      expect(find.text(MilestoneCardScreen.errorMessage), findsNothing);
    });

    testWidgets('a failing share shows the error snackbar', (tester) async {
      _setView(tester);
      var called = false;
      ShareHelper.debugShare = (params) async {
        called = true;
        throw PlatformException(code: 'share_failed');
      };
      await tester.pumpWidget(_app(MilestoneCardScreen(detail: weeks[20]!)));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('milestone-share')));
        await _until(() => called);
      });
      await tester.pump();
      expect(find.text(MilestoneCardScreen.errorMessage), findsOneWidget);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('card screen has no overflow at 360x640, scale $scale', (
        tester,
      ) async {
        _setView(tester);
        await tester.pumpWidget(
          _app(
            MilestoneCardScreen(
              detail: week(
                30,
                size: 'quả đu đủ to và một cái tên rất dài để thử tràn dòng',
                lengthCm: 39.9,
                weightG: 1300,
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(MilestoneCardScreen(detail: week(2)), textScale: scale),
        );
        await tester.pump();
        expect(find.text('Tuần 2 thai kỳ của mẹ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final theme in [_light, _dark]) {
      testWidgets('share button keeps 4.5:1 (${theme.brightness.name})', (
        tester,
      ) async {
        _setView(tester);
        await tester.pumpWidget(
          _app(MilestoneCardScreen(detail: weeks[20]!), theme: theme),
        );
        await tester.pump();
        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('milestone-share')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(
          _contrast(material.textStyle!.color!, material.color!),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('21.5 health report', () {
    test('the Ngày column fits any dd/MM/yyyy on one line', () {
      final doc = PdfDocument();
      for (final asset in [
        HealthReportFonts.regularAsset,
        HealthReportFonts.boldAsset,
      ]) {
        final font = PdfTtfFont(
          doc,
          ByteData.sublistView(File(asset).readAsBytesSync()),
        );
        double width(String text) =>
            font.stringMetrics(text).advanceWidth *
            HealthReportPdf.tableFontSize;
        // Widest possible date: the widest digit everywhere.
        final widestDigit = [
          for (var d = 0; d <= 9; d++) width('$d'),
        ].reduce((a, b) => a > b ? a : b);
        final worst = 8 * widestDigit + 2 * width('/');
        final available =
            HealthReportPdf.dateColumnWidth -
            2 * HealthReportPdf.tableCellPadding;
        expect(worst, lessThan(available), reason: asset);
        for (final date in ['25/08/2026', '29/10/2026', '20/09/2026']) {
          expect(width(date), lessThan(available), reason: '$asset $date');
        }
        expect(width('Ngày'), lessThan(available), reason: asset);
      }
    });

    final range = HealthReportRange(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 10),
    );

    test('range presets and file name', () {
      final last30 = HealthReportRange.last30Days(_now);
      expect(last30.from, DateTime(2026, 9, 30));
      expect(last30.to, DateTime(2026, 10, 29));
      final since = HealthReportRange.sincePregnancyStart(_pregnancy(), _now);
      expect(since.from, DateTime(2026, 5, 1));
      expect(since.to, DateTime(2026, 10, 29));
      expect(last30.fileName, 'momcare_nhat_ky_20260930_20261029.pdf');
      expect(ShareHelper.isGeneratedFileName(last30.fileName), isTrue);
    });

    test('filterLogs is inclusive, date-only and ascending', () {
      final logs = [
        _log('after', DateTime(2026, 10, 11, 0, 0)),
        _log('last', DateTime(2026, 10, 10, 23, 59)),
        _log('mid', DateTime(2026, 10, 5, 12)),
        _log('first', DateTime(2026, 10, 1, 0, 0)),
        _log('before', DateTime(2026, 9, 30, 23, 59)),
      ];
      expect(HealthReport.filterLogs(logs, range).map((l) => l.id), [
        'first',
        'mid',
        'last',
      ]);
    });

    test('rowsFor formats values and uses — for missing ones', () {
      final rows = HealthReport.rowsFor([
        _log(
          'a',
          DateTime(2026, 10, 2),
          weight: 65.5,
          systolic: 120,
          diastolic: 80,
          symptoms: ['Buồn nôn', 'Đau lưng'],
          notes: '  Đau lưng nhẹ, ngủ ít  ',
        ),
        _log('b', DateTime(2026, 10, 3), systolic: 118),
        _log('c', DateTime(2026, 10, 4), weight: 66, symptoms: [], notes: ' '),
      ]);
      expect(rows[0], [
        '02/10/2026',
        '65.5',
        '120/80',
        'Buồn nôn, Đau lưng',
        'Đau lưng nhẹ, ngủ ít',
      ]);
      expect(rows[1], ['03/10/2026', '—', '—', '—', '—']);
      expect(rows[2], ['04/10/2026', '66.0', '—', '—', '—']);
    });

    test('summary has only numbers', () {
      final summary = HealthReport.summary([
        _log(
          'c',
          DateTime(2026, 10, 9),
          weight: 66.2,
          systolic: 125,
          diastolic: 82,
        ),
        _log(
          'a',
          DateTime(2026, 10, 1),
          weight: 65.0,
          systolic: 110,
          diastolic: 70,
        ),
        _log('b', DateTime(2026, 10, 5), systolic: 130),
      ]);
      expect(summary.count, 3);
      expect(summary.firstWeight, 65.0);
      expect(summary.firstWeightDate, DateTime(2026, 10, 1));
      expect(summary.lastWeight, 66.2);
      expect(summary.lastWeightDate, DateTime(2026, 10, 9));
      expect(summary.minSystolic, 110);
      expect(summary.maxSystolic, 125);
      expect(summary.minDiastolic, 70);
      expect(summary.maxDiastolic, 82);
      final text = summary.lines.join('\n');
      expect(text, contains('Số ghi nhận: 3'));
      expect(text, contains('65.0 kg (01/10/2026) – 66.2 kg (09/10/2026)'));
      for (final word in ['bình thường', 'bất thường', 'cao', 'thấp']) {
        expect(text.toLowerCase(), isNot(contains(word)));
      }
      final empty = HealthReport.summary(const []);
      expect(empty.lines, ['Số ghi nhận: 0']);
    });

    test('build gives a PDF; 80 logs span pages; Vietnamese text', () async {
      final fonts = _diskFonts();
      final bytes = await HealthReportPdf.build(
        logs: [
          _log(
            'a',
            DateTime(2026, 10, 2),
            weight: 65.5,
            systolic: 120,
            diastolic: 80,
            symptoms: ['Đau lưng'],
            notes: 'Đau lưng nhẹ, ngủ ít',
          ),
        ],
        range: range,
        pregnancy: _pregnancy(name: 'Nguyễn Thị Hằng'),
        generatedAt: _now,
        regular: fonts.regular,
        bold: fonts.bold,
      );
      expect(_ascii(bytes, 4), '%PDF');

      final many = [
        for (var i = 0; i < 80; i++)
          _log(
            'l$i',
            DateTime(2026, 8, 1).add(Duration(days: i)),
            weight: 60 + i / 10,
            systolic: 110 + i % 10,
            diastolic: 70 + i % 5,
            symptoms: ['Buồn nôn'],
            notes: 'Ghi chú số $i: mệt mỏi, khó ngủ',
          ),
      ];
      final doc = HealthReportPdf.buildDocument(
        logs: many,
        range: HealthReportRange(DateTime(2026, 8, 1), DateTime(2026, 10, 29)),
        generatedAt: _now,
        regular: fonts.regular,
        bold: fonts.bold,
      );
      final manyBytes = await doc.save();
      expect(_ascii(manyBytes, 4), '%PDF');
      expect(doc.document.pdfPageList.pages.length, greaterThan(1));
    });
  });

  group('21.6 HealthReportExportScreen', () {
    late HealthReportFonts fonts;

    setUp(() {
      fonts = _diskFonts();
      HealthReportFonts.debugLoad = () async => fonts;
    });

    final logs = [
      _log(
        'a',
        DateTime(2026, 10, 28),
        weight: 66,
        systolic: 120,
        diastolic: 80,
      ),
      _log('b', DateTime(2026, 10, 10), symptoms: ['Đau lưng']),
      _log('c', DateTime(2026, 9, 30, 0, 5), notes: 'Đau lưng nhẹ, ngủ ít'),
      _log('d', DateTime(2026, 9, 29, 23, 0), weight: 65),
      _log('e', DateTime(2026, 6, 1), weight: 60),
    ];

    Widget screen({
      List<HealthLogModel>? items,
      PregnancyModel? pregnancy,
      double textScale = 1.0,
      ThemeData? theme,
    }) => _app(
      HealthReportExportScreen(
        logs: items ?? logs,
        pregnancy: pregnancy,
        now: () => _now,
      ),
      textScale: textScale,
      theme: theme,
    );

    testWidgets('presets update the count; no pregnancy hides the chip', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(screen(pregnancy: _pregnancy()));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('health-export-last30Days')),
      );
      expect(chip.selected, isTrue);
      expect(
        find.text('Từ 30/09/2026 đến 29/10/2026 · 3 ghi nhận'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('health-export-sincePregnancy')),
      );
      await tester.pump();
      expect(
        find.text('Từ 01/05/2026 đến 29/10/2026 · 5 ghi nhận'),
        findsOneWidget,
      );

      // A new tree so the screen state is created again.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('Từ đầu thai kỳ'), findsNothing);
      expect(find.text('Tùy chọn'), findsOneWidget);
    });

    testWidgets('an empty range disables the button', (tester) async {
      _setView(tester);
      await tester.pumpWidget(
        screen(items: [logs.last], pregnancy: _pregnancy()),
      );
      await tester.pump();
      expect(find.text(HealthReportExportScreen.emptyMessage), findsOneWidget);
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('health-export-share')),
      );
      expect(button.onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey('health-export-sincePregnancy')),
      );
      await tester.pump();
      expect(find.text(HealthReportExportScreen.emptyMessage), findsNothing);
    });

    testWidgets('share builds the PDF and calls the share sheet once', (
      tester,
    ) async {
      _setView(tester);
      final calls = <ShareParams>[];
      List<int>? bytes;
      ShareHelper.debugShare = (params) async {
        bytes = await File(params.files!.single.path).readAsBytes();
        calls.add(params);
      };
      await tester.pumpWidget(screen(pregnancy: _pregnancy(name: 'Lan')));
      await tester.pump();
      await _showExportShare(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('health-export-share')));
        await _until(() => calls.isNotEmpty);
      });
      await tester.pump();
      expect(calls, hasLength(1));
      final file = calls.single.files!.single;
      expect(file.path, endsWith('momcare_nhat_ky_20260930_20261029.pdf'));
      expect(file.mimeType, 'application/pdf');
      expect(_ascii(bytes!, 4), '%PDF');
      // The generated PDF is removed from the temp folder after sharing.
      expect(File(file.path).existsSync(), isFalse);
      expect(find.text(HealthReportExportScreen.errorMessage), findsNothing);
    });

    testWidgets('a failing share shows the error snackbar', (tester) async {
      _setView(tester);
      var called = false;
      ShareHelper.debugShare = (params) async {
        called = true;
        throw StateError('no share sheet');
      };
      await tester.pumpWidget(screen());
      await tester.pump();
      await _showExportShare(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('health-export-share')));
        await _until(() => called);
      });
      await tester.pump();
      expect(find.text(HealthReportExportScreen.errorMessage), findsOneWidget);
    });

    for (final theme in [_light, _dark]) {
      testWidgets('preset chips keep >= 4.5:1 contrast, '
          '${theme.brightness.name}', (tester) async {
        _setView(tester);
        await tester.pumpWidget(screen(pregnancy: _pregnancy(), theme: theme));
        await tester.pump();
        for (final preset in HealthReportPreset.values) {
          final chipFinder = find.byKey(
            ValueKey('health-export-${preset.name}'),
          );
          final chip = tester.widget<ChoiceChip>(chipFinder);
          final label = tester.widget<Text>(
            find.descendant(of: chipFinder, matching: find.byType(Text)),
          );
          final style = DefaultTextStyle.of(
            tester.element(
              find.descendant(of: chipFinder, matching: find.byType(Text)),
            ),
          ).style.merge(label.style);
          // Theme chip colours (Phase 22): selected secondaryContainer,
          // unselected transparent over the screen background.
          expect(chip.color, isNull);
          final bg = chip.selected
              ? theme.chipTheme.selectedColor!
              : theme.scaffoldBackgroundColor;
          expect(
            _contrast(style.color!, bg),
            greaterThanOrEqualTo(4.5),
            reason: '${preset.name} selected=${chip.selected}',
          );
          expect(
            _contrast(theme.chipTheme.checkmarkColor!, bg),
            greaterThanOrEqualTo(4.5),
          );
        }
        // Also with another chip selected.
        await tester.tap(
          find.byKey(const ValueKey('health-export-sincePregnancy')),
        );
        await tester.pump();
        final selected = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey('health-export-sincePregnancy')),
        );
        expect(selected.selected, isTrue);
        final bg = theme.chipTheme.selectedColor!;
        expect(
          _contrast(theme.colorScheme.onSecondaryContainer, bg),
          greaterThanOrEqualTo(4.5),
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.0, 1.5]) {
      for (final theme in [_light, _dark]) {
        testWidgets(
          'no overflow at 360x640, scale $scale, ${theme.brightness.name}',
          (tester) async {
            _setView(tester);
            await tester.pumpWidget(
              screen(pregnancy: _pregnancy(), textScale: scale, theme: theme),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            await _showExportShare(tester);
            final material = tester.widget<Material>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('health-export-share')),
                    matching: find.byType(Material),
                  )
                  .first,
            );
            expect(
              _contrast(material.textStyle!.color!, material.color!),
              greaterThanOrEqualTo(4.5),
            );
          },
        );
      }
    }
  });
}

Future<void> _showExportShare(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('health-export-share'));
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// Interleaves real and fake async so pending file reads complete.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
