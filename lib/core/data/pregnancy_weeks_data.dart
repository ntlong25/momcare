class PregnancyWeekData {
  final int week;
  final String babySize;
  final String babyWeight;
  final String babyLength;
  final String development;
  final List<String> motherChanges;
  final List<String> tips;

  PregnancyWeekData({
    required this.week,
    required this.babySize,
    required this.babyWeight,
    required this.babyLength,
    required this.development,
    required this.motherChanges,
    required this.tips,
  });
}

class PregnancyWeeksDatabase {
  static PregnancyWeekData getWeekData(int week) {
    if (week < 1 || week > 42) {
      return _weeks[0]!;
    }
    return _weeks[week] ?? _getDefaultWeekData(week);
  }

  static PregnancyWeekData _getDefaultWeekData(int week) {
    return PregnancyWeekData(
      week: week,
      babySize: getBabySizeComparison(week),
      babyWeight: '${week * 50}g',
      babyLength: '${week * 1.2}cm',
      development: 'Your baby is growing and developing each day.',
      motherChanges: ['Body is adapting to pregnancy'],
      tips: ['Stay healthy and attend regular checkups'],
    );
  }

  static final Map<int, PregnancyWeekData> _weeks = {
    0: PregnancyWeekData(
      week: 0,
      babySize: 'Poppy seed',
      babyWeight: '< 1g',
      babyLength: '< 1mm',
      development: 'Your pregnancy journey is just beginning!',
      motherChanges: ['Preparing for conception'],
      tips: ['Take prenatal vitamins', 'Maintain a healthy lifestyle'],
    ),
    1: PregnancyWeekData(
      week: 1,
      babySize: 'Poppy seed',
      babyWeight: '< 1g',
      babyLength: '< 1mm',
      development: 'Fertilization week! Your baby is just a cluster of cells.',
      motherChanges: ['No visible changes yet'],
      tips: ['Start taking folic acid', 'Avoid alcohol and smoking'],
    ),
    4: PregnancyWeekData(
      week: 4,
      babySize: 'Poppy seed',
      babyWeight: '< 1g',
      babyLength: '2mm',
      development: 'The embryo has implanted in your uterus. Major organs are beginning to form.',
      motherChanges: ['Missed period', 'Early pregnancy symptoms may start'],
      tips: ['Take a pregnancy test', 'Schedule your first prenatal visit'],
    ),
    8: PregnancyWeekData(
      week: 8,
      babySize: 'Raspberry',
      babyWeight: '1g',
      babyLength: '1.6cm',
      development: 'Baby\'s heart is beating, and tiny arms and legs are forming. Facial features are developing.',
      motherChanges: ['Morning sickness', 'Breast tenderness', 'Fatigue'],
      tips: ['Eat small, frequent meals', 'Stay hydrated', 'Rest when needed'],
    ),
    12: PregnancyWeekData(
      week: 12,
      babySize: 'Plum',
      babyWeight: '14g',
      babyLength: '5.4cm',
      development: 'All major organs are formed. Baby can make sucking movements and is starting to move.',
      motherChanges: ['End of first trimester', 'Morning sickness may ease', 'Energy returning'],
      tips: ['Continue prenatal vitamins', 'Consider maternity clothes', 'Stay active'],
    ),
    16: PregnancyWeekData(
      week: 16,
      babySize: 'Avocado',
      babyWeight: '100g',
      babyLength: '11.6cm',
      development: 'Baby can hear sounds and is developing reflexes. Facial expressions are forming.',
      motherChanges: ['Baby bump showing', 'Possible quickening (feeling baby move)'],
      tips: ['Talk and sing to your baby', 'Start prenatal yoga', 'Moisturize belly skin'],
    ),
    20: PregnancyWeekData(
      week: 20,
      babySize: 'Banana',
      babyWeight: '300g',
      babyLength: '25cm',
      development: 'Halfway there! Baby can hear your voice and is developing sleep patterns.',
      motherChanges: ['Definite baby movements', 'Round ligament pain', 'Skin changes'],
      tips: ['Get anatomy scan', 'Start thinking about baby names', 'Prepare nursery'],
    ),
    24: PregnancyWeekData(
      week: 24,
      babySize: 'Corn',
      babyWeight: '600g',
      babyLength: '30cm',
      development: 'Baby\'s lungs are developing. Taste buds are forming and baby can hear outside sounds.',
      motherChanges: ['Visible baby kicks', 'Backache', 'Braxton Hicks contractions may start'],
      tips: ['Take childbirth classes', 'Do pelvic floor exercises', 'Sleep on your side'],
    ),
    28: PregnancyWeekData(
      week: 28,
      babySize: 'Eggplant',
      babyWeight: '1kg',
      babyLength: '37cm',
      development: 'Third trimester begins! Baby can blink eyes and is adding fat layers.',
      motherChanges: ['Increased urination', 'Shortness of breath', 'Swelling in feet'],
      tips: ['Start thinking about birth plan', 'Pack hospital bag', 'Count baby kicks'],
    ),
    32: PregnancyWeekData(
      week: 32,
      babySize: 'Squash',
      babyWeight: '1.7kg',
      babyLength: '42cm',
      development: 'Baby is practicing breathing and has developed all five senses.',
      motherChanges: ['Larger belly', 'Difficulty sleeping', 'Frequent urination'],
      tips: ['Monitor baby movements', 'Prepare for maternity leave', 'Rest frequently'],
    ),
    36: PregnancyWeekData(
      week: 36,
      babySize: 'Romaine lettuce',
      babyWeight: '2.6kg',
      babyLength: '47cm',
      development: 'Baby is nearly ready! Lungs are maturing and baby is dropping into birth position.',
      motherChanges: ['Baby dropping', 'Increased pelvic pressure', 'Easier breathing'],
      tips: ['Weekly doctor visits', 'Finalize birth plan', 'Install car seat'],
    ),
    40: PregnancyWeekData(
      week: 40,
      babySize: 'Watermelon',
      babyWeight: '3.4kg',
      babyLength: '51cm',
      development: 'Full term! Baby is ready to meet you. Could arrive any day now.',
      motherChanges: ['Contractions', 'Possible water breaking', 'Cervix dilating'],
      tips: ['Watch for labor signs', 'Stay calm and rest', 'Have hospital bag ready'],
    ),
  };

  static List<String> getAllWeekTips() {
    return [
      'Stay hydrated - drink 8-10 glasses of water daily',
      'Get plenty of rest and sleep',
      'Eat a balanced diet rich in fruits and vegetables',
      'Take your prenatal vitamins every day',
      'Exercise regularly with doctor approval',
      'Avoid stress and practice relaxation techniques',
      'Talk to your baby - they can hear you!',
      'Track your baby\'s movements daily',
      'Attend all prenatal appointments',
      'Join a support group for expectant mothers',
    ];
  }

  static String getBabySizeComparison(int week) {
    final comparisons = {
      1: 'Poppy seed',
      4: 'Poppy seed',
      5: 'Sesame seed',
      6: 'Lentil',
      7: 'Blueberry',
      8: 'Raspberry',
      9: 'Grape',
      10: 'Kumquat',
      11: 'Fig',
      12: 'Plum',
      13: 'Peach',
      14: 'Lemon',
      15: 'Apple',
      16: 'Avocado',
      17: 'Pear',
      18: 'Sweet potato',
      19: 'Mango',
      20: 'Banana',
      21: 'Carrot',
      22: 'Papaya',
      23: 'Grapefruit',
      24: 'Corn',
      25: 'Cauliflower',
      26: 'Lettuce',
      27: 'Cabbage',
      28: 'Eggplant',
      29: 'Butternut squash',
      30: 'Cucumber',
      31: 'Coconut',
      32: 'Squash',
      33: 'Pineapple',
      34: 'Cantaloupe',
      35: 'Honeydew',
      36: 'Romaine lettuce',
      37: 'Swiss chard',
      38: 'Leek',
      39: 'Pumpkin',
      40: 'Watermelon',
    };
    return comparisons[week] ?? 'Baby';
  }
}
