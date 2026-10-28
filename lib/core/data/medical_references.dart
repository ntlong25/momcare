import 'package:flutter/material.dart';

enum MedicalReferenceGroup {
  pregnancy,
  nutrition,
  growthAndVitals,
  fertility,
  urgentWarning,
}

class MedicalReference {
  final String title;
  final String organization;
  final String url;
  final MedicalReferenceGroup group;

  const MedicalReference({
    required this.title,
    required this.organization,
    required this.url,
    required this.group,
  });
}

class MedicalReferenceData {
  static const String lastUpdated = '12/09/2026';

  static const references = [
    MedicalReference(
      title: 'Văn bản hướng dẫn chuyên môn về sức khỏe bà mẹ và trẻ em',
      organization: 'Cục Bà mẹ và Trẻ em - Bộ Y tế Việt Nam',
      url: 'https://mch.moh.gov.vn/',
      group: MedicalReferenceGroup.pregnancy,
    ),
    MedicalReference(
      title: 'WHO recommendations on antenatal care',
      organization: 'World Health Organization',
      url: 'https://www.who.int/publications/i/item/9789241549912',
      group: MedicalReferenceGroup.pregnancy,
    ),
    MedicalReference(
      title: 'WHO maternal health recommendations',
      organization: 'World Health Organization',
      url: 'https://www.who.int/publications/i/item/9789240080591',
      group: MedicalReferenceGroup.growthAndVitals,
    ),
    MedicalReference(
      title: 'WHO maternal health topic',
      organization: 'World Health Organization',
      url: 'https://www.who.int/health-topics/maternal-health',
      group: MedicalReferenceGroup.growthAndVitals,
    ),
    MedicalReference(
      title: 'WHO antenatal care nutrition recommendations',
      organization: 'World Health Organization',
      url: 'https://www.who.int/publications/i/item/WHO-RHR-18.02',
      group: MedicalReferenceGroup.nutrition,
    ),
    MedicalReference(
      title: 'Multiple micronutrient supplements during pregnancy',
      organization: 'World Health Organization',
      url: 'https://www.who.int/publications/i/item/9789240007789',
      group: MedicalReferenceGroup.nutrition,
    ),
    MedicalReference(
      title: 'Preconception and pregnancy complication guidance',
      organization: 'Centers for Disease Control and Prevention',
      url:
          'https://www.cdc.gov/maternal-infant-health/pregnancy-complications/index.html',
      group: MedicalReferenceGroup.fertility,
    ),
    MedicalReference(
      title: 'Urgent maternal warning signs and symptoms',
      organization: 'Centers for Disease Control and Prevention',
      url: 'https://www.cdc.gov/hearher/maternal-warning-signs/index.html',
      group: MedicalReferenceGroup.urgentWarning,
    ),
    MedicalReference(
      title: 'Pregnant and postpartum women warning signs',
      organization: 'Centers for Disease Control and Prevention',
      url: 'https://www.cdc.gov/hearher/pregnant-postpartum/index.html',
      group: MedicalReferenceGroup.urgentWarning,
    ),
  ];

  static List<MedicalReference> byGroup(MedicalReferenceGroup group) {
    return references.where((reference) => reference.group == group).toList();
  }

  static String labelForGroup(MedicalReferenceGroup group) {
    return switch (group) {
      MedicalReferenceGroup.pregnancy => 'Thai kỳ',
      MedicalReferenceGroup.nutrition => 'Dinh dưỡng',
      MedicalReferenceGroup.growthAndVitals =>
        'Huyết áp, cân nặng, chăm sóc mẹ',
      MedicalReferenceGroup.fertility => 'Chu kỳ và chuẩn bị mang thai',
      MedicalReferenceGroup.urgentWarning => 'Dấu hiệu nguy hiểm',
    };
  }

  static IconData iconForGroup(MedicalReferenceGroup group) {
    return switch (group) {
      MedicalReferenceGroup.pregnancy => Icons.pregnant_woman,
      MedicalReferenceGroup.nutrition => Icons.restaurant_menu,
      MedicalReferenceGroup.growthAndVitals => Icons.monitor_heart,
      MedicalReferenceGroup.fertility => Icons.calendar_month,
      MedicalReferenceGroup.urgentWarning => Icons.warning_amber_rounded,
    };
  }
}
