import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/features/legal/screens/medical_disclaimer_screen.dart';
import 'package:momcare/features/legal/screens/privacy_policy_screen.dart';

void main() {
  testWidgets('Privacy policy screen renders user-friendly data statements', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(
      find.textContaining('Dữ liệu được lưu trên thiết bị'),
      findsOneWidget,
    );
    expect(find.textContaining('Chưa có sao lưu trực tuyến'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kiểm soát dữ liệu'), findsOneWidget);
    // P23-R1-04: the URL is still a placeholder.
    expect(find.text('Mở chính sách trên website'), findsNothing);
    expect(find.textContaining('example.com'), findsNothing);
  });

  testWidgets('a real URL brings the website buttons back', (tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    addTearDown(tester.view.resetPhysicalSize);
    const url = 'https://momcare.vn/legal';

    await tester.pumpWidget(
      const MaterialApp(home: PrivacyPolicyScreen(websiteUrl: url)),
    );
    expect(find.text('Mở chính sách trên website'), findsOneWidget);
    expect(find.text(url), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: MedicalDisclaimerScreen(websiteUrl: url)),
    );
    expect(find.text('Mở tuyên bố trên website'), findsOneWidget);
    expect(find.text(url), findsOneWidget);
  });

  test('isPublishedUrl rejects placeholders only', () {
    expect(AppConstants.isPublishedUrl(''), isFalse);
    expect(AppConstants.isPublishedUrl('   '), isFalse);
    expect(AppConstants.isPublishedUrl('https://example.com/x'), isFalse);
    expect(AppConstants.isPublishedUrl('https://WWW.example.com/x'), isFalse);
    expect(AppConstants.isPublishedUrl('https://momcare.vn/x'), isTrue);
    expect(AppConstants.isPublishedUrl('https://notexample.com/x'), isTrue);
  });

  testWidgets('Medical disclaimer screen renders required safety statements', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MedicalDisclaimerScreen()));

    expect(find.text('Tuyên bố miễn trừ y tế'), findsOneWidget);
    expect(find.text('MomCare+ không thay thế bác sĩ'), findsOneWidget);
    expect(find.text('Không chẩn đoán hoặc điều trị'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Dữ liệu theo dõi có thể sai lệch'), findsOneWidget);
    // P23-R1-04: the URL is still a placeholder.
    expect(find.text('Mở tuyên bố trên website'), findsNothing);
    expect(find.textContaining('example.com'), findsNothing);
  });
}
