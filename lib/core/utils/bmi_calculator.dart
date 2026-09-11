class BMICalculator {
  /// Calculate BMI (Body Mass Index)
  /// weight in kg, height in cm
  static double calculate({required double weight, required double height}) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  static String getCategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  /// Get recommended weight gain during pregnancy based on pre-pregnancy BMI
  /// Returns a map with min and max values in kg
  static Map<String, double> getRecommendedWeightGain(double preBMI) {
    if (preBMI < 18.5) {
      // Underweight
      return {'min': 12.5, 'max': 18.0};
    } else if (preBMI < 25) {
      // Normal weight
      return {'min': 11.5, 'max': 16.0};
    } else if (preBMI < 30) {
      // Overweight
      return {'min': 7.0, 'max': 11.5};
    } else {
      // Obese
      return {'min': 5.0, 'max': 9.0};
    }
  }

  /// Get BMI color indicator
  static String getBMIColor(double bmi) {
    if (bmi < 18.5) return '#64B5F6'; // Blue - Underweight
    if (bmi < 25) return '#81C784'; // Green - Normal
    if (bmi < 30) return '#FFB74D'; // Orange - Overweight
    return '#E57373'; // Red - Obese
  }

  /// Get health advice based on BMI
  static String getAdvice(double bmi) {
    if (bmi < 18.5) {
      return 'Bạn có thể cần tăng cân phù hợp hơn. Hãy trao đổi với nhân viên y tế về kế hoạch dinh dưỡng.';
    } else if (bmi < 25) {
      return 'Cân nặng của bạn đang trong khoảng phù hợp. Hãy duy trì ăn uống cân bằng và vận động phù hợp.';
    } else if (bmi < 30) {
      return 'Bạn có thể đang thừa cân nhẹ. Hãy cân nhắc chế độ ăn cân bằng và hỏi nhân viên y tế khi cần.';
    } else {
      return 'Hãy trao đổi với nhân viên y tế để có lời khuyên phù hợp về quản lý cân nặng trong thai kỳ.';
    }
  }

  /// Calculate expected weight at current week of pregnancy
  /// Returns estimated weight based on pre-pregnancy weight and week
  static double calculateExpectedWeight({
    required double prePregnancyWeight,
    required double preBMI,
    required int currentWeek,
  }) {
    if (currentWeek < 0 || currentWeek > 42) return prePregnancyWeight;

    final weightGain = getRecommendedWeightGain(preBMI);
    final avgWeightGain = (weightGain['min']! + weightGain['max']!) / 2;

    // Weight gain is typically minimal in first trimester
    if (currentWeek <= 13) {
      return prePregnancyWeight + (avgWeightGain * 0.1);
    }

    // Progressive weight gain in second and third trimester
    final weeksAfterFirst = currentWeek - 13;
    final remainingWeeks = 27; // Weeks from 14 to 40
    final weeklyGain = (avgWeightGain * 0.9) / remainingWeeks;

    return prePregnancyWeight +
        (avgWeightGain * 0.1) +
        (weeksAfterFirst * weeklyGain);
  }
}
