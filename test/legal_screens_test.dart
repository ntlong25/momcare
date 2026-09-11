import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/features/legal/screens/medical_disclaimer_screen.dart';
import 'package:momcare/features/legal/screens/privacy_policy_screen.dart';

void main() {
  testWidgets('Privacy policy screen renders required V1 statements', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(
      find.textContaining('Dữ liệu được lưu trên thiết bị'),
      findsOneWidget,
    );
    expect(find.textContaining('Chưa có đồng bộ cloud'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Mở chính sách trên website'), findsOneWidget);
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

    expect(find.text('Mở tuyên bố trên website'), findsOneWidget);
  });
}
