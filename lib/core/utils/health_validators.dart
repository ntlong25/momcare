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

  /// Validate weight input
  /// Returns error message if invalid, null if valid
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }

    if (weight < minWeight || weight > maxWeight) {
      return 'Weight must be between $minWeight-$maxWeight kg';
    }

    return null;
  }

  /// Validate height input
  /// Returns error message if invalid, null if valid
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid number';
    }

    if (height < minHeight || height > maxHeight) {
      return 'Height must be between $minHeight-$maxHeight cm';
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
      return 'Invalid number';
    }

    if (systolic < minSystolic || systolic > maxSystolic) {
      return 'Must be $minSystolic-$maxSystolic';
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
      return 'Invalid number';
    }

    if (diastolic < minDiastolic || diastolic > maxDiastolic) {
      return 'Must be $minDiastolic-$maxDiastolic';
    }

    return null;
  }

  /// Validate blood pressure pair (systolic must be > diastolic)
  /// Returns error message if invalid, null if valid
  static String? validateBloodPressurePair(String? systolicValue, String? diastolicValue) {
    // If either is empty, skip pair validation
    if (systolicValue == null || systolicValue.isEmpty ||
        diastolicValue == null || diastolicValue.isEmpty) {
      return null;
    }

    final systolic = int.tryParse(systolicValue);
    final diastolic = int.tryParse(diastolicValue);

    if (systolic == null || diastolic == null) {
      return null; // Individual validators will catch this
    }

    if (systolic <= diastolic) {
      return 'Systolic must be greater than diastolic';
    }

    // Warn about unusual pulse pressure (difference > 60 or < 30)
    final pulsePressure = systolic - diastolic;
    if (pulsePressure > 60) {
      return 'Unusual pulse pressure. Please verify values';
    }
    if (pulsePressure < 25) {
      return 'Pulse pressure too narrow. Please verify values';
    }

    return null;
  }

  /// Get blood pressure category for display
  static String getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Elevated';
    } else if (systolic < 140 || diastolic < 90) {
      return 'High (Stage 1)';
    } else if (systolic < 180 || diastolic < 120) {
      return 'High (Stage 2)';
    } else {
      return 'Hypertensive Crisis';
    }
  }

  /// Get weight status category based on BMI
  static String getWeightCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25.0) {
      return 'Normal';
    } else if (bmi < 30.0) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
}
