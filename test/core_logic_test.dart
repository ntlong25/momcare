import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/services/health_service.dart';
import 'package:momcare/core/utils/bmi_calculator.dart';
import 'package:momcare/core/utils/health_validators.dart';
import 'package:momcare/core/services/notification_service.dart';
import 'package:momcare/core/utils/date_picker_utils.dart';
import 'package:momcare/core/utils/nutrition_filter.dart';

void main() {
  MenstrualCycleModel cycle({
    required String id,
    required DateTime startDate,
    int? cycleLengthDays,
  }) {
    return MenstrualCycleModel(
      id: id,
      startDate: startDate,
      cycleLengthDays: cycleLengthDays,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('Pregnancy calculations', () {
    test('calculates current pregnancy week from last period date', () {
      final lastPeriodDate = DateTime.now().subtract(
        const Duration(days: 15 * 7 + 2),
      );
      final pregnancy = PregnancyModel(
        id: 'pregnancy-1',
        dueDate: lastPeriodDate.add(const Duration(days: 280)),
        lastPeriodDate: lastPeriodDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pregnancy.currentWeek, 15);
      expect(pregnancy.trimester, 'Tam cá nguyệt 2');
    });

    test('calculates BMI and recommended pregnancy weight gain', () {
      final pregnancy = PregnancyModel(
        id: 'pregnancy-2',
        dueDate: DateTime.now().add(const Duration(days: 180)),
        prePregnancyWeight: 60,
        height: 165,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pregnancy.bmi, closeTo(22.04, 0.01));
      expect(BMICalculator.getCategory(pregnancy.bmi!), 'Bình thường');
      expect(BMICalculator.getRecommendedWeightGain(pregnancy.bmi!), {
        'min': 11.5,
        'max': 16.0,
      });
    });
  });

  group('Health validators', () {
    test('accepts realistic weight and blood pressure values', () {
      expect(HealthValidators.validateWeight('62.5'), isNull);
      expect(HealthValidators.validateSystolicBP('120'), isNull);
      expect(HealthValidators.validateDiastolicBP('80'), isNull);
      expect(HealthValidators.validateBloodPressurePair('120', '80'), isNull);
    });

    test('rejects invalid weight and blood pressure values', () {
      expect(HealthValidators.validateWeight('abc'), isNotNull);
      expect(HealthValidators.validateWeight('20'), isNotNull);
      expect(HealthValidators.validateSystolicBP('60'), isNotNull);
      expect(HealthValidators.validateDiastolicBP('180'), isNotNull);
      expect(
        HealthValidators.validateBloodPressurePair('80', '90'),
        'Huyết áp tâm thu phải lớn hơn tâm trương',
      );
    });
  });

  group('Cycle and ovulation predictions', () {
    test('predicts next period, ovulation date, and fertile window', () {
      final today = DateTime(2026, 3, 1);
      final cycles = [
        cycle(
          id: 'cycle-1',
          startDate: DateTime(2026, 1, 1),
          cycleLengthDays: 28,
        ),
        cycle(
          id: 'cycle-2',
          startDate: DateTime(2026, 1, 29),
          cycleLengthDays: 28,
        ),
        cycle(
          id: 'cycle-3',
          startDate: DateTime(2026, 2, 26),
          cycleLengthDays: 28,
        ),
      ];

      expect(HealthService.calculateAverageCycleLength(cycles), 28);
      expect(HealthService.areCyclesRegular(cycles), isTrue);
      expect(
        HealthService.predictNextPeriod(cycles, today: today),
        DateTime(2026, 3, 26),
      );
      expect(
        HealthService.predictNextOvulation(cycles, today: today),
        DateTime(2026, 3, 12),
      );

      final fertileWindow = HealthService.predictFertileWindow(
        cycles,
        today: today,
      );

      expect(fertileWindow, hasLength(6));
      expect(fertileWindow!.first, DateTime(2026, 3, 7));
      expect(fertileWindow.last, DateTime(2026, 3, 12));
    });
  });

  group('Phase 12 cycle regressions', () {
    test('fewer than 3 cycles reports insufficient data, not irregular', () {
      expect(
        HealthService.cycleRegularity(const []),
        CycleRegularity.insufficientData,
      );
      expect(
        HealthService.cycleRegularity([
          cycle(id: 'a', startDate: DateTime(2026, 1, 1)),
        ]),
        CycleRegularity.insufficientData,
      );
      expect(HealthService.areCyclesRegular(const []), isFalse);
    });

    test('older period entered later never yields negative lengths', () {
      // Entered newest first, with stale stored lengths (incl. negative).
      final cycles = [
        cycle(id: 'new', startDate: DateTime(2026, 3, 1), cycleLengthDays: 30),
        cycle(
          id: 'old',
          startDate: DateTime(2026, 1, 30),
          cycleLengthDays: -30,
        ),
        cycle(id: 'mid', startDate: DateTime(2026, 3, 29)),
      ];

      expect(HealthService.cycleLengths(cycles), [30, 28]);
      expect(HealthService.calculateAverageCycleLength(cycles), 29);

      final recomputed = HealthService.withRecomputedCycleLengths(cycles);
      expect(recomputed.map((c) => c.id), ['old', 'new', 'mid']);
      expect(recomputed.map((c) => c.cycleLengthDays), [null, 30, 28]);
    });

    test('next period prediction rolls forward past today', () {
      final cycles = [
        cycle(id: 'a', startDate: DateTime(2026, 1, 1)),
        cycle(id: 'b', startDate: DateTime(2026, 1, 29)),
      ];
      final today = DateTime(2026, 4, 10);
      final next = HealthService.predictNextPeriod(cycles, today: today)!;

      expect(next.isBefore(today), isFalse);
      expect(next, DateTime(2026, 4, 23));
      expect(
        HealthService.predictNextPeriod(cycles, today: DateTime(2026, 2, 1)),
        DateTime(2026, 2, 26),
      );
    });

    test('health sync builds idempotent cycles with stable ids', () {
      final days = [
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 2, 9),
        DateTime(2026, 1, 3, 7),
        DateTime(2026, 1, 29, 10),
        DateTime(2026, 1, 30, 11),
      ];
      final first = HealthService.buildCyclesFromPeriodDays(days);
      final second = HealthService.buildCyclesFromPeriodDays(
        days.reversed.toList(),
      );

      expect(first, hasLength(2));
      expect(first.map((c) => c.id), [
        'health_2026-01-01',
        'health_2026-01-29',
      ]);
      expect(second.map((c) => c.id), first.map((c) => c.id));
      expect(first.first.periodLengthDays, 3);
      expect(first.last.cycleLengthDays, 28);
    });
  });

  group('Phase 12 pregnancy date consistency', () {
    test('due date and LMP are linked by 280 days', () {
      final lmp = DateTime(2026, 3, 1);
      final due = PregnancyModel.dueDateFromLastPeriod(lmp);

      expect(due, DateTime(2026, 12, 6));
      expect(PregnancyModel.lastPeriodFromDueDate(due), lmp);
    });

    test('current week and days left agree even with inconsistent LMP', () {
      final now = DateTime(2026, 6, 1, 15, 30);
      final due = DateTime(2026, 10, 1);
      final pregnancy = PregnancyModel(
        id: 'p',
        dueDate: due,
        // Stale, inconsistent LMP must not change the week.
        lastPeriodDate: DateTime(2025, 1, 1),
        createdAt: now,
        updatedAt: now,
      );

      final daysLeft = pregnancy.daysUntilDueAt(now);
      final week = pregnancy.currentWeekAt(now);

      expect(daysLeft, 122);
      expect(week, ((280 - daysLeft) / 7).floor());
    });
  });

  group('Phase 12 health diary input', () {
    test('accepts Vietnamese decimal comma', () {
      expect(HealthValidators.parseDecimal('55,5'), 55.5);
      expect(HealthValidators.parseDecimal(' 62.25 '), 62.25);
      expect(HealthValidators.parseDecimal(''), isNull);
      expect(HealthValidators.validateWeight('55,5'), isNull);
      expect(HealthValidators.validateHeight('160,5'), isNull);
    });

    test('rejects a completely empty entry', () {
      expect(HealthValidators.hasHealthLogContent(), isFalse);
      expect(
        HealthValidators.hasHealthLogContent(symptoms: const [], notes: '  '),
        isFalse,
      );
      expect(HealthValidators.hasHealthLogContent(weight: 55.5), isTrue);
      expect(HealthValidators.hasHealthLogContent(notes: 'Mệt'), isTrue);
    });
  });

  group('Phase 12 nutrition filter', () {
    test('trimester chips match week-range categories', () {
      expect(NutritionFilter.matches('Tuần 0-12', 'Tam cá nguyệt 1'), isTrue);
      expect(NutritionFilter.matches('Tuần 0-12', 'Tam cá nguyệt 2'), isFalse);
      expect(NutritionFilter.matches('Tuần 8-42', 'Tam cá nguyệt 3'), isTrue);
      expect(NutritionFilter.matches('Tuần 13-42', 'Tam cá nguyệt 1'), isTrue);
      expect(
        NutritionFilter.matches('Tam cá nguyệt 2', 'Tam cá nguyệt 2'),
        isTrue,
      );
    });

    test('chips without content are hidden', () {
      final chips = NutritionFilter.chipsFor([
        'Tuần 0-12',
        'Tuần 8-42',
        'Tuần 13-42',
        'Tuần 0-42',
      ]);

      expect(chips, [
        'Tất cả',
        'Tam cá nguyệt 1',
        'Tam cá nguyệt 2',
        'Tam cá nguyệt 3',
      ]);
      expect(chips, isNot(contains('Ăn dặm')));
      expect(chips, isNot(contains('Sau sinh')));
    });
  });

  group('Phase 12 notifications', () {
    test('stable notification ids are deterministic and positive', () {
      final a = NotificationService.stableId('habit:water');
      expect(a, NotificationService.stableId('habit:water'));
      expect(a, isNot(NotificationService.stableId('habit:iron')));
      expect(a, greaterThanOrEqualTo(0));
      expect(a, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('daily reminder starts at the next occurrence', () {
      final now = DateTime(2026, 5, 1, 10, 0);
      expect(
        NotificationService.nextInstanceOf(9, 0, now: now),
        DateTime(2026, 5, 2, 9, 0),
      );
      expect(
        NotificationService.nextInstanceOf(20, 30, now: now),
        DateTime(2026, 5, 1, 20, 30),
      );
    });
  });

  group('Phase 12 date pickers', () {
    test('initial date is clamped into the picker range', () {
      final first = DateTime(2026, 5, 1);
      final last = DateTime(2026, 12, 31);
      expect(
        DatePickerUtils.clampInitial(DateTime(2026, 1, 1), first, last),
        first,
      );
      expect(
        DatePickerUtils.clampInitial(DateTime(2027, 6, 1), first, last),
        last,
      );
      expect(
        DatePickerUtils.clampInitial(DateTime(2026, 6, 1, 13), first, last),
        DateTime(2026, 6, 1),
      );
    });
  });
}
