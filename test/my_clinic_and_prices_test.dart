import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/models/my_clinic.dart';
import 'package:momcare/core/services/guide_price_service.dart';
import 'package:momcare/core/services/milestone_progress_service.dart';
import 'package:momcare/core/services/my_clinic_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/vnd_format.dart';
import 'package:momcare/features/emergency/screens/emergency_warning_screen.dart';
import 'package:momcare/features/guides/guide_actions.dart';
import 'package:momcare/features/guides/screens/guide_detail_screen.dart';
import 'package:momcare/features/guides/widgets/guide_updated_banner.dart';
import 'package:momcare/features/settings/screens/my_clinic_screen.dart';
import 'package:momcare/features/settings/widgets/my_clinic_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

GuideArticle _guide(
  GuideCategory category, {
  String id = 'fixture',
  String? lastUpdated,
  List<GuideSection> sections = const [],
}) {
  return GuideArticle(
    id: id,
    stage: GuideStage.pregnant,
    category: category,
    title: 'Fixture ${category.name}',
    summary: 'Tóm tắt fixture',
    sections: sections,
    checklist: const [
      GuideChecklistItem(id: 'chk_a', text: 'Áo ngực bầu'),
      GuideChecklistItem(id: 'chk_b', text: 'Nôi hoặc cũi'),
      GuideChecklistItem(id: 'chk_c', text: 'Bình sữa'),
    ],
    lastUpdated: lastUpdated,
  );
}

final _shopping = _guide(GuideCategory.shopping, id: 'shop');
final _documents = _guide(
  GuideCategory.documents,
  id: 'docs',
  lastUpdated: '2026-10-29',
  sections: const [
    GuideSection(heading: 'Giấy tờ cần chuẩn bị', body: 'CCCD, sổ khám.'),
  ],
);

const _fullClinic = MyClinic(
  name: 'BV Từ Dũ',
  doctor: 'Nguyễn A',
  phone: '028 3829 5723',
  address: '284 Cống Quỳnh, Quận 1, TP.HCM',
);

Finder _priceKeys() => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('price-chk'),
);

void _setView(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = logical * 3;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _app(Widget home, {double textScale = 1.0, Key? scopeKey}) {
  return ProviderScope(
    key: scopeKey,
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

Widget _detail(GuideArticle guide) =>
    GuideDetailScreen(guide: guide, sources: const {});

Widget _cardHost({bool emergency = false}) => Scaffold(
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [MyClinicCard(emergency: emergency)],
  ),
);

Future<void> _savePrice(WidgetTester tester, String itemId, String raw) async {
  final button = find.byKey(ValueKey('price-$itemId'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('price-input')), raw);
  await tester.pump();
  await tester.tap(find.text('Lưu'));
  await tester.pumpAndSettle();
}

void main() {
  group('VND format', () {
    test('formatVnd', () {
      expect(formatVnd(0), '0 đ');
      expect(formatVnd(999), '999 đ');
      expect(formatVnd(1000), '1.000 đ');
      expect(formatVnd(1250000), '1.250.000 đ');
      expect(formatVnd(999999999), '999.999.999 đ');
    });

    test('parseVndInput', () {
      expect(parseVndInput('1.250.000'), 1250000);
      expect(parseVndInput('350000 đ'), 350000);
      expect(parseVndInput('abc'), isNull);
      expect(parseVndInput(''), isNull);
      expect(parseVndInput('0'), isNull);
      expect(parseVndInput('000'), isNull);
      expect(parseVndInput('999999999'), 999999999);
      expect(parseVndInput('1234567890'), isNull);
    });
  });

  group('GuidePriceService', () {
    test('decode/encode round trip and corrupt values', () {
      final prices = {'chk_b': 1200000, 'chk_a': 350000};
      expect(
        GuidePriceService.decode(GuidePriceService.encode(prices)),
        prices,
      );
      expect(GuidePriceService.decode(null), isEmpty);
      expect(GuidePriceService.decode('{not json'), isEmpty);
      expect(GuidePriceService.decode('[1,2]'), isEmpty);
      expect(
        GuidePriceService.decode(
          jsonEncode({'a': 10, 'b': 'x', '': 5, 'c': 0, 'd': -3, 'e': 1.5}),
        ),
        {'a': 10},
      );
    });

    test('notifier sets, removes and persists prices', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.guidePricesKey: jsonEncode({'chk_a': 100}),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(guidePriceProvider.notifier);
      await notifier.ready;
      expect(container.read(guidePriceProvider), {'chk_a': 100});

      await notifier.setPrice('chk_b', 350000);
      final prefs = await SharedPreferences.getInstance();
      expect(
        GuidePriceService.decode(prefs.getString(AppConstants.guidePricesKey)),
        {'chk_a': 100, 'chk_b': 350000},
      );

      await notifier.setPrice('chk_a', null);
      await notifier.setPrice('chk_b', 0);
      expect(container.read(guidePriceProvider), isEmpty);
      expect(prefs.getString(AppConstants.guidePricesKey), isNull);

      await notifier.setPrice('chk_c', 5);
      notifier.resetLocal();
      expect(container.read(guidePriceProvider), isEmpty);
    });
  });

  group('GuideArticle prices', () {
    test('tracksPrices only for shopping and hospital_bag', () {
      expect(_guide(GuideCategory.shopping).tracksPrices, isTrue);
      expect(_guide(GuideCategory.hospitalBag).tracksPrices, isTrue);
      expect(_guide(GuideCategory.documents).tracksPrices, isFalse);
      expect(_guide(GuideCategory.warning).tracksPrices, isFalse);
      expect(_guide(GuideCategory.checkup).tracksPrices, isFalse);
      const empty = GuideArticle(
        id: 'e',
        stage: GuideStage.pregnant,
        category: GuideCategory.shopping,
        title: 'Empty',
      );
      expect(empty.tracksPrices, isFalse);
    });

    test('boughtTotal counts only ticked items with a price', () {
      final prices = {'chk_a': 350000, 'chk_b': 1200000, 'other': 99};
      expect(_shopping.boughtTotal({'chk_a'}, prices), 350000);
      expect(_shopping.boughtTotal({'chk_a', 'chk_b'}, prices), 1550000);
      expect(_shopping.boughtTotal({'chk_c', 'other'}, prices), 0);
      expect(_shopping.boughtTotal(const {}, prices), 0);
      expect(_shopping.pricedCount(prices), 2);
      expect(_shopping.pricedCount(const {}), 0);
    });
  });

  group('Guide price UI', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('price dialog, total, untick and clear', (tester) async {
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(_detail(_shopping)));
      await tester.pumpAndSettle();

      expect(find.text('Thêm giá'), findsNWidgets(3));
      expect(find.text('Đã mua 0/3 món · Đã chi 0 đ'), findsOneWidget);
      expect(find.text('Ghi giá để xem tổng chi phí'), findsOneWidget);

      // Live preview in the dialog.
      await tester.tap(find.byKey(const ValueKey('price-chk_a')));
      await tester.pumpAndSettle();
      expect(find.text('Giá (VND)'), findsOneWidget);
      expect(find.text('Xóa giá'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('price-input')),
        '350000',
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('price-preview'))).data,
        '350.000 đ',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('350.000 đ'), findsOneWidget);
      expect(find.text('Thêm giá'), findsNWidgets(2));
      expect(find.text('Ghi giá để xem tổng chi phí'), findsNothing);
      expect(find.text('Đã mua 0/3 món · Đã chi 0 đ'), findsOneWidget);

      await tester.tap(find.text('Áo ngực bầu'));
      await tester.pumpAndSettle();
      expect(find.text('Đã mua 1/3 món · Đã chi 350.000 đ'), findsOneWidget);

      await tester.tap(find.text('Áo ngực bầu'));
      await tester.pumpAndSettle();
      expect(find.text('Đã mua 0/3 món · Đã chi 0 đ'), findsOneWidget);
      expect(find.text('350.000 đ'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('price-chk_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa giá'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm giá'), findsNWidgets(3));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.guidePricesKey), isNull);
    });

    testWidgets('10-digit input is cut to 9 digits, Hủy keeps nothing', (
      tester,
    ) async {
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(_detail(_shopping)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('price-chk_b')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('price-input')),
        '1234567890',
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        hasLength(9),
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm giá'), findsNWidgets(3));
    });

    testWidgets('price persists after reload from prefs', (tester) async {
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(_detail(_shopping)));
      await tester.pumpAndSettle();
      await _savePrice(tester, 'chk_b', '1.200.000');
      expect(find.text('1.200.000 đ'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(_detail(_shopping), scopeKey: UniqueKey()));
      await tester.pumpAndSettle();
      expect(find.text('1.200.000 đ'), findsOneWidget);
    });

    testWidgets('documents guide has no price buttons or total', (
      tester,
    ) async {
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(_detail(_documents)));
      await tester.pumpAndSettle();
      expect(_priceKeys(), findsNothing);
      expect(find.byKey(const ValueKey('guide-bought-total')), findsNothing);
      expect(find.text('Thêm giá'), findsNothing);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('no overflow at 360x640, text scale $scale', (tester) async {
        _setView(tester, const Size(360, 640));
        await tester.pumpWidget(_app(_detail(_shopping), textScale: scale));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('price-chk_a')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await _savePrice(tester, 'chk_a', '999999999');
        expect(find.text('999.999.999 đ'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('price-chk_c')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('GuideUpdatedBanner', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('label', () {
      expect(
        GuideUpdatedBanner.label('2026-10-29'),
        'Cập nhật ngày 29/10/2026',
      );
      expect(GuideUpdatedBanner.label(null), 'Chưa rõ ngày cập nhật');
      expect(GuideUpdatedBanner.label('2026-02-31'), 'Chưa rõ ngày cập nhật');
      expect(GuideUpdatedBanner.label('hôm qua'), 'Chưa rõ ngày cập nhật');
    });

    testWidgets('documents guide shows banner above draft note and sections', (
      tester,
    ) async {
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(_detail(_documents)));
      await tester.pumpAndSettle();

      final banner = find.text('Cập nhật ngày 29/10/2026');
      expect(banner, findsOneWidget);
      expect(
        find.textContaining('có thể thay đổi', findRichText: true),
        findsOneWidget,
      );
      final bannerY = tester.getTopLeft(banner).dy;
      expect(
        bannerY,
        lessThan(tester.getTopLeft(find.text('Giấy tờ cần chuẩn bị')).dy),
      );
      expect(
        bannerY,
        lessThan(
          tester.getTopLeft(find.text('Nội dung đang chờ bác sĩ duyệt')).dy,
        ),
      );
      expect(
        bannerY,
        greaterThan(tester.getTopLeft(find.text('Tóm tắt fixture')).dy),
      );
    });

    testWidgets('invalid date shows fallback', (tester) async {
      _setView(tester, const Size(430, 1400));
      final guide = _guide(GuideCategory.documents, lastUpdated: 'không rõ');
      await tester.pumpWidget(_app(_detail(guide)));
      await tester.pumpAndSettle();
      expect(find.text('Chưa rõ ngày cập nhật'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shopping guide has no banner', (tester) async {
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(_detail(_shopping)));
      await tester.pumpAndSettle();
      expect(find.byType(GuideUpdatedBanner), findsNothing);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('banner fits 360 dp at text scale $scale', (tester) async {
        _setView(tester, const Size(360, 640));
        await tester.pumpWidget(_app(_detail(_documents), textScale: scale));
        await tester.pumpAndSettle();
        expect(find.byType(GuideUpdatedBanner), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    test('bundled pregnant_documents.json has a valid lastUpdated', () {
      final raw = File(
        'assets/content/guides/pregnant_documents.json',
      ).readAsStringSync();
      final guide = ContentPackService.parseGuide(raw)!;
      expect(guide.category, GuideCategory.documents);
      expect(MilestoneProgressService.parseDate(guide.lastUpdated), isNotNull);
    });
  });

  group('MyClinic model', () {
    test('JSON round trip', () {
      expect(MyClinic.fromJson(_fullClinic.toJson()), _fullClinic);
      expect(
        MyClinicService.decode(MyClinicService.encode(_fullClinic)),
        _fullClinic,
      );
    });

    test('corrupt and partial JSON never throws', () {
      expect(MyClinicService.decode(null), MyClinic.empty);
      expect(MyClinicService.decode('{broken'), MyClinic.empty);
      expect(MyClinicService.decode('[1]'), MyClinic.empty);
      expect(MyClinic.fromJson('text'), MyClinic.empty);
      final partial = MyClinic.fromJson({
        'name': '  BV Hùng Vương ',
        'phone': 123,
        'address': null,
        'extra': 'x',
      });
      expect(partial.name, 'BV Hùng Vương');
      expect(partial.phone, '');
      expect(partial.address, '');
      expect(partial.doctor, '');
      expect(partial.isEmpty, isFalse);
      expect(MyClinic.empty.isEmpty, isTrue);
    });

    test('mapsQuery priority and hasPhone', () {
      expect(_fullClinic.mapsQuery, '284 Cống Quỳnh, Quận 1, TP.HCM');
      expect(const MyClinic(name: 'BV Từ Dũ').mapsQuery, 'BV Từ Dũ');
      expect(const MyClinic(phone: '115').mapsQuery, isNull);
      expect(const MyClinic(phone: '12').hasPhone, isFalse);
      expect(const MyClinic(phone: '028 3829 5723').hasPhone, isTrue);
      expect(const MyClinic().hasPhone, isFalse);
    });

    test('launch URIs', () {
      expect(
        GuideActions.phoneUri(_fullClinic.phone).toString(),
        'tel:02838295723',
      );
      expect(
        GuideActions.mapsSearchUri(GuideActions.nearbyHospitalQuery).toString(),
        startsWith('https://www.google.com/maps/search/?api=1&query='),
      );
      expect(
        GuideActions.mapsSearchUri(
          GuideActions.nearbyHospitalQuery,
        ).queryParameters['query'],
        'bệnh viện phụ sản',
      );
    });

    test('service: empty save removes the key; notifier clear', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await MyClinicService.save(_fullClinic);
      expect(await MyClinicService.load(), _fullClinic);
      await MyClinicService.save(MyClinic.empty);
      expect(prefs.getString(AppConstants.myClinicKey), isNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(myClinicProvider.notifier);
      await notifier.ready;
      await notifier.save(_fullClinic);
      expect(prefs.getString(AppConstants.myClinicKey), isNotNull);
      await notifier.clear();
      expect(container.read(myClinicProvider), MyClinic.empty);
      expect(prefs.getString(AppConstants.myClinicKey), isNull);
      await notifier.save(_fullClinic);
      notifier.resetLocal();
      expect(container.read(myClinicProvider).isEmpty, isTrue);
    });
  });

  group('MyClinicScreen', () {
    Widget host() => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyClinicScreen())),
            child: const Text('open'),
          ),
        ),
      ),
    );

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    test('phone validator', () {
      expect(MyClinicScreen.validatePhone(''), isNull);
      expect(MyClinicScreen.validatePhone('028 3829 5723'), isNull);
      expect(MyClinicScreen.validatePhone('+84 (28) 3829-5723'), isNull);
      expect(MyClinicScreen.validatePhone('ab'), 'Số điện thoại không hợp lệ');
      expect(MyClinicScreen.validatePhone('12'), 'Số điện thoại không hợp lệ');
    });

    testWidgets('save stores values and reopening shows them', (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setView(tester, const Size(430, 1000));
      await tester.pumpWidget(_app(host()));
      await open(tester);

      await tester.enterText(
        find.byKey(const ValueKey('clinic-name')),
        'BV Từ Dũ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('clinic-doctor')),
        'Nguyễn A',
      );
      await tester.enterText(
        find.byKey(const ValueKey('clinic-phone')),
        '028 5404 2829',
      );
      await tester.enterText(
        find.byKey(const ValueKey('clinic-address')),
        '284 Cống Quỳnh, Quận 1, TP.HCM',
      );
      await tester.tap(find.byKey(const ValueKey('clinic-save')));
      await tester.pumpAndSettle();

      expect(find.text('Đã lưu nơi khám'), findsOneWidget);
      expect(find.byType(MyClinicScreen), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      final saved = MyClinicService.decode(
        prefs.getString(AppConstants.myClinicKey),
      );
      expect(saved.name, 'BV Từ Dũ');
      expect(saved.doctor, 'Nguyễn A');
      expect(saved.phone, '028 5404 2829');
      expect(saved.address, '284 Cống Quỳnh, Quận 1, TP.HCM');

      await open(tester);
      expect(find.widgetWithText(TextFormField, 'BV Từ Dũ'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, '028 5404 2829'),
        findsOneWidget,
      );
      expect(find.text('Xóa thông tin'), findsOneWidget);
    });

    testWidgets('invalid phone blocks save', (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setView(tester, const Size(430, 1000));
      await tester.pumpWidget(_app(host()));
      await open(tester);

      await tester.enterText(
        find.byKey(const ValueKey('clinic-name')),
        'BV Từ Dũ',
      );
      await tester.enterText(find.byKey(const ValueKey('clinic-phone')), 'ab');
      await tester.tap(find.byKey(const ValueKey('clinic-save')));
      await tester.pumpAndSettle();

      expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
      expect(find.byType(MyClinicScreen), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.myClinicKey), isNull);
    });

    testWidgets('loads a saved profile and clears it after confirm', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.myClinicKey: MyClinicService.encode(_fullClinic),
      });
      _setView(tester, const Size(430, 1000));
      await tester.pumpWidget(_app(host()));
      await open(tester);

      expect(find.widgetWithText(TextFormField, 'BV Từ Dũ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clinic-clear')));
      await tester.pumpAndSettle();
      expect(find.text('Xóa thông tin nơi khám?'), findsOneWidget);
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.myClinicKey), isNull);
      expect(find.widgetWithText(TextFormField, 'BV Từ Dũ'), findsNothing);
      expect(find.text('Xóa thông tin'), findsNothing);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('editor fits 360 dp at text scale $scale', (tester) async {
        SharedPreferences.setMockInitialValues({
          AppConstants.myClinicKey: MyClinicService.encode(_fullClinic),
        });
        _setView(tester, const Size(360, 640));
        await tester.pumpWidget(_app(host(), textScale: scale));
        await open(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('clinic-clear')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('MyClinicCard', () {
    late List<Uri> launched;
    var launchResult = true;

    setUp(() {
      launched = [];
      launchResult = true;
      GuideActions.debugLauncher = (uri) async {
        launched.add(uri);
        return launchResult;
      };
    });
    tearDown(() => GuideActions.debugLauncher = null);

    void prefsWith(MyClinic clinic) => SharedPreferences.setMockInitialValues(
      clinic.isEmpty
          ? {}
          : {AppConstants.myClinicKey: MyClinicService.encode(clinic)},
    );

    testWidgets('empty card pushes MyClinicScreen', (tester) async {
      prefsWith(MyClinic.empty);
      await tester.pumpWidget(_app(_cardHost()));
      await tester.pumpAndSettle();

      expect(find.text('Thêm nơi khám'), findsOneWidget);
      expect(find.text('Gọi'), findsNothing);
      expect(find.byKey(const ValueKey('find-hospital-button')), findsNothing);
      await tester.tap(find.text('Thêm nơi khám'));
      await tester.pumpAndSettle();
      expect(find.byType(MyClinicScreen), findsOneWidget);
    });

    testWidgets('full profile: Gọi and Bản đồ launch the right URIs', (
      tester,
    ) async {
      prefsWith(_fullClinic);
      await tester.pumpWidget(_app(_cardHost()));
      await tester.pumpAndSettle();

      expect(find.text('BV Từ Dũ'), findsOneWidget);
      expect(find.text('BS. Nguyễn A'), findsOneWidget);
      expect(find.text('028 3829 5723'), findsOneWidget);
      expect(find.text('Sửa'), findsOneWidget);

      await tester.tap(find.text('Gọi'));
      await tester.pump();
      expect(launched.last.toString(), 'tel:02838295723');

      await tester.tap(find.text('Bản đồ'));
      await tester.pump();
      expect(launched.last.host, 'www.google.com');
      expect(
        launched.last.queryParameters['query'],
        '284 Cống Quỳnh, Quận 1, TP.HCM',
      );

      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      expect(find.byType(MyClinicScreen), findsOneWidget);
    });

    testWidgets('name-only profile shows Bản đồ but no Gọi', (tester) async {
      prefsWith(const MyClinic(name: 'BV Từ Dũ'));
      await tester.pumpWidget(_app(_cardHost()));
      await tester.pumpAndSettle();

      expect(find.text('Gọi'), findsNothing);
      await tester.tap(find.text('Bản đồ'));
      await tester.pump();
      expect(launched.last.queryParameters['query'], 'BV Từ Dũ');
    });

    testWidgets('emergency variant finds nearby hospitals', (tester) async {
      prefsWith(MyClinic.empty);
      await tester.pumpWidget(_app(_cardHost(emergency: true)));
      await tester.pumpAndSettle();

      expect(find.text('Thêm nơi khám'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('find-hospital-button')));
      await tester.pump();
      expect(launched.last.queryParameters['query'], 'bệnh viện phụ sản');
      expect(
        launched.last.toString(),
        GuideActions.mapsSearchUri(GuideActions.nearbyHospitalQuery).toString(),
      );
    });

    testWidgets('failing launcher shows the snackbar', (tester) async {
      prefsWith(_fullClinic);
      launchResult = false;
      await tester.pumpWidget(_app(_cardHost(emergency: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gọi'));
      await tester.pumpAndSettle();
      expect(find.text('Không mở được ứng dụng phù hợp'), findsOneWidget);
    });

    testWidgets('EmergencyWarningScreen shows the card after the action card', (
      tester,
    ) async {
      prefsWith(_fullClinic);
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const EmergencyWarningScreen()));
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('find-hospital-button'));
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(MyClinicCard), findsOneWidget);
      final cardY = tester.getTopLeft(find.byType(MyClinicCard)).dy;
      expect(
        cardY,
        greaterThan(
          tester
              .getTopLeft(find.text('Bạn nên làm gì?', skipOffstage: false))
              .dy,
        ),
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(launched.last.queryParameters['query'], 'bệnh viện phụ sản');

      await tester.ensureVisible(find.text('Gọi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gọi'));
      await tester.pump();
      expect(launched.last.toString(), 'tel:02838295723');
    });

    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    // AppTheme.lightTheme/darkTheme fetch Poppins over the network in tests;
    // they define no filledButtonTheme, so their schemes alone reproduce the
    // button colours.
    for (final entry in {
      'light': ThemeData(
        colorScheme: AppTheme.lightColorScheme,
        primaryColor: AppTheme.primaryColor,
      ),
      'dark': ThemeData(
        colorScheme: AppTheme.darkColorScheme,
        primaryColor: AppTheme.primaryColor,
      ),
    }.entries) {
      for (final (key, clinic) in [
        ('my-clinic-add', MyClinic.empty),
        ('my-clinic-call', _fullClinic),
      ]) {
        testWidgets('$key button text is >= 4.5:1 (${entry.key})', (
          tester,
        ) async {
          prefsWith(clinic);
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(theme: entry.value, home: _cardHost()),
            ),
          );
          await tester.pumpAndSettle();

          final button = find.byKey(ValueKey(key));
          expect(button, findsOneWidget);
          // ButtonStyleButton paints its resolved background and foreground
          // onto the Material it builds.
          final material = tester.widget<Material>(
            find.descendant(of: button, matching: find.byType(Material)).first,
          );
          final bg = material.color!;
          final fg = material.textStyle!.color!;
          expect(bg.a, 1.0, reason: 'background must be opaque');
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }
    }

    for (final scale in [1.0, 1.5]) {
      for (final emergency in [false, true]) {
        testWidgets('card fits 360 dp (scale $scale, emergency $emergency)', (
          tester,
        ) async {
          prefsWith(_fullClinic);
          _setView(tester, const Size(360, 640));
          await tester.pumpWidget(
            _app(_cardHost(emergency: emergency), textScale: scale),
          );
          await tester.pumpAndSettle();
          expect(find.text('Bản đồ'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
      testWidgets('empty emergency card fits 360 dp (scale $scale)', (
        tester,
      ) async {
        prefsWith(MyClinic.empty);
        _setView(tester, const Size(360, 640));
        await tester.pumpWidget(
          _app(_cardHost(emergency: true), textScale: scale),
        );
        await tester.pumpAndSettle();
        expect(find.text('Thêm nơi khám'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
