/// Validators for health-related data inputs
/// Ensures medical data is within safe and realistic ranges
class HealthValidators {
  // Weight validation (kg)
  static const double minWeight = 30.0;
  static const double maxWeight = 300.0;

  // Blood pressure validation (mmHg)
  static const int minSystolic = 70;
  static const int maxSystolic = 250;
  static const int minDiastolic = 40;
  static const int maxDiastolic = 150;

  // Height validation (cm)
  static const double minHeight = 100.0;
  static const double maxHeight = 250.0;

  /// Parses a decimal number typed with either "." or the Vietnamese decimal
  /// comma (e.g. "55,5"). Returns null for empty or invalid input.
  static double? parseDecimal(String? value) {
    if (value == null) return null;
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  /// A health diary entry must contain at least one piece of information.
  static bool hasHealthLogContent({
    double? weight,
    int? systolicBP,
    int? diastolicBP,
    String? mood,
    List<String>? symptoms,
    String? notes,
  }) {
    return weight != null ||
        systolicBP != null ||
        diastolicBP != null ||
        (mood != null && mood.isNotEmpty) ||
        (symptoms != null && symptoms.isNotEmpty) ||
        (notes != null && notes.trim().isNotEmpty);
  }

  /// Validate weight input
  /// Returns error message if invalid, null if valid
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final weight = parseDecimal(value);
    if (weight == null) {
      return 'Vui lòng nhập số hợp lệ';
    }

    if (weight < minWeight || weight > maxWeight) {
      return 'Cân nặng phải trong khoảng $minWeight-$maxWeight kg';
    }

    return null;
  }

  /// Validate height input
  /// Returns error message if invalid, null if valid
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final height = parseDecimal(value);
    if (height == null) {
      return 'Vui lòng nhập số hợp lệ';
    }

    if (height < minHeight || height > maxHeight) {
      return 'Chiều cao phải trong khoảng $minHeight-$maxHeight cm';
    }

    return null;
  }

  /// Validate systolic blood pressure
  /// Returns error message if invalid, null if valid
  static String? validateSystolicBP(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final systolic = int.tryParse(value);
    if (systolic == null) {
      return 'Số không hợp lệ';
    }

    if (systolic < minSystolic || systolic > maxSystolic) {
      return 'Phải trong khoảng $minSystolic-$maxSystolic';
    }

    return null;
  }

  /// Validate diastolic blood pressure
  /// Returns error message if invalid, null if valid
  static String? validateDiastolicBP(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final diastolic = int.tryParse(value);
    if (diastolic == null) {
      return 'Số không hợp lệ';
    }

    if (diastolic < minDiastolic || diastolic > maxDiastolic) {
      return 'Phải trong khoảng $minDiastolic-$maxDiastolic';
    }

    return null;
  }

  /// Validate blood pressure pair (systolic must be > diastolic)
  /// Returns error message if invalid, null if valid
  static String? validateBloodPressurePair(
    String? systolicValue,
    String? diastolicValue,
  ) {
    // If either is empty, skip pair validation
    if (systolicValue == null ||
        systolicValue.isEmpty ||
        diastolicValue == null ||
        diastolicValue.isEmpty) {
      return null;
    }

    final systolic = int.tryParse(systolicValue);
    final diastolic = int.tryParse(diastolicValue);

    if (systolic == null || diastolic == null) {
      return null; // Individual validators will catch this
    }

    if (systolic <= diastolic) {
      return 'Huyết áp tâm thu phải lớn hơn tâm trương';
    }

    // Warn about unusual pulse pressure (difference > 60 or < 30)
    final pulsePressure = systolic - diastolic;
    if (pulsePressure > 60) {
      return 'Hiệu áp bất thường. Vui lòng kiểm tra lại chỉ số';
    }
    if (pulsePressure < 25) {
      return 'Hiệu áp quá hẹp. Vui lòng kiểm tra lại chỉ số';
    }

    return null;
  }

  /// Get blood pressure category for display
  static String getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return 'Bình thường';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Hơi cao';
    } else if (systolic < 140 || diastolic < 90) {
      return 'Cao độ 1';
    } else if (systolic < 180 || diastolic < 120) {
      return 'Cao độ 2';
    } else {
      return 'Cơn tăng huyết áp';
    }
  }

  /// Get weight status category based on BMI
  static String getWeightCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Thiếu cân';
    } else if (bmi < 25.0) {
      return 'Bình thường';
    } else if (bmi < 30.0) {
      return 'Thừa cân';
    } else {
      return 'Béo phì';
    }
  }
}
