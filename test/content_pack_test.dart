
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/maternal_habit_model.dart';
import 'package:momcare/core/providers/app_mode_provider.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _StringAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  _StringAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) {
    throw FlutterError('Binary load is not used in this test: $key');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) {
      throw FlutterError('Missing asset: $key');
    }
    return value;
  }
}

void main() {
  test('pregnancy content parser validates week 0-42 coverage', () {
    final raw =
        '''
{
  "lastUpdated": "2026-09-12",
  "sourceRefs": ["WHO-ANC"],
  "weeks": ${List.generate(43, (index) => index)},
  "redFlags": ["Đi khám nếu có dấu hiệu bất thường"],
  "nutritionFocusByTrimester": {
    "0": "Chuẩn bị dinh dưỡng.",
    "1": "Dinh dưỡng tam cá nguyệt 1.",
    "2": "Dinh dưỡng tam cá nguyệt 2.",
    "3": "Dinh dưỡng tam cá nguyệt 3."
  }
}
''';

    final weeks = ContentPackService.parsePregnancyWeeks(raw);

    expect(weeks.keys, containsAll(List.generate(43, (index) => index)));
    expect(weeks[0]!.nutritionFocus, 'Chuẩn bị dinh dưỡng.');
    expect(weeks[42]!.redFlags, isNotEmpty);
    expect(weeks[42]!.lastUpdated, '2026-09-12');
  });

  test('pregnancy content loader falls back when asset is missing', () async {
    final weeks = await ContentPackService.loadPregnancyWeeks(
      _StringAssetBundle(const {}),
    );

    expect(weeks.length, 43);
    expect(weeks[0], isNotNull);
    expect(weeks[42], isNotNull);
  });

  test('nutrition parser keeps supplement comparison and avoid list', () {
    const raw = '''
{
  "guides": [
    {
      "id": "iron",
      "title": "Sắt",
      "category": "Tuần 8-42",
      "description": "Theo hướng dẫn bác sĩ.",
      "benefits": ["Hỗ trợ tạo máu"],
      "recommendedFoods": ["Thịt nạc"],
      "foodsToAvoid": ["Tự ý đổi liều"],
      "supplementComparison": "Thực phẩm và viên bổ sung có vai trò khác nhau."
    }
  ]
}
''';

    final guides = ContentPackService.parseNutritionGuides(raw);

    expect(guides, hasLength(1));
    expect(guides.first.benefits.last, contains('So sánh:'));
    expect(guides.first.foodsToAvoid, contains('Tự ý đổi liều'));
  });

  test('maternal habit completion resets naturally by date', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final habit = MaternalHabitModel(
      id: 'water',
      title: 'Uống đủ nước',
      category: 'Nước',
      description: 'Theo dõi nước',
      lastCompletedDate: yesterday,
      disclaimer: 'Theo nhu cầu cơ thể.',
    );

    expect(habit.isCompletedToday, isFalse);
    expect(
      habit.copyWith(lastCompletedDate: DateTime.now()).isCompletedToday,
      isTrue,
    );
  });

  test(
    'startup persistence keeps mode and defaults navigation to Home',
    () async {
      SharedPreferences.setMockInitialValues({'app_mode': 'pregnancy'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appModeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(appModeProvider), AppMode.pregnancy);
      expect(container.read(navigationIndexProvider), 0);
    },
  );
}
