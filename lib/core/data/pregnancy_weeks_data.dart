class PregnancyWeekData {
  final int week;
  final String babySize;
  final String babyWeight;
  final String babyLength;
  final String development;
  final List<String> motherChanges;
  final List<String> tips;
  final List<String> redFlags;
  final String nutritionFocus;
  final List<String> sourceRefs;
  final String lastUpdated;

  PregnancyWeekData({
    required this.week,
    required this.babySize,
    required this.babyWeight,
    required this.babyLength,
    required this.development,
    required this.motherChanges,
    required this.tips,
    this.redFlags = const [],
    this.nutritionFocus = '',
    this.sourceRefs = const [],
    this.lastUpdated = '2026-09-12',
  });
}

class PregnancyWeeksDatabase {
  static Map<int, PregnancyWeekData>? _contentPackWeeks;

  static void setContentPack(Map<int, PregnancyWeekData> weeks) {
    _contentPackWeeks = weeks;
  }

  static PregnancyWeekData getWeekData(int week) {
    final contentPackWeeks = _contentPackWeeks;
    if (contentPackWeeks != null) {
      return contentPackWeeks[week.clamp(0, 42)] ?? contentPackWeeks[0]!;
    }

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
      babyLength: '${(week * 1.2).toStringAsFixed(1)}cm',
      development:
          'Thai nhi tiếp tục phát triển từng ngày. Các mốc có thể khác nhau tùy từng thai kỳ.',
      motherChanges: ['Cơ thể mẹ đang thích nghi với thai kỳ'],
      tips: ['Duy trì thói quen lành mạnh và đi khám thai theo lịch hẹn'],
    );
  }

  static final Map<int, PregnancyWeekData> _weeks = {
    0: PregnancyWeekData(
      week: 0,
      babySize: 'hạt anh túc',
      babyWeight: '< 1g',
      babyLength: '< 1mm',
      development: 'Hành trình thai kỳ đang bắt đầu.',
      motherChanges: ['Cơ thể đang chuẩn bị cho quá trình thụ thai'],
      tips: [
        'Trao đổi với bác sĩ về vitamin trước sinh',
        'Duy trì lối sống lành mạnh',
      ],
    ),
    1: PregnancyWeekData(
      week: 1,
      babySize: 'hạt anh túc',
      babyWeight: '< 1g',
      babyLength: '< 1mm',
      development:
          'Đây là giai đoạn rất sớm. Phôi thai mới bắt đầu hình thành ở cấp độ tế bào.',
      motherChanges: ['Thường chưa có thay đổi rõ rệt'],
      tips: ['Có thể hỏi bác sĩ về axit folic', 'Tránh rượu bia và thuốc lá'],
    ),
    4: PregnancyWeekData(
      week: 4,
      babySize: 'hạt anh túc',
      babyWeight: '< 1g',
      babyLength: '2mm',
      development:
          'Phôi thai có thể đã làm tổ. Các cơ quan quan trọng bắt đầu hình thành ở giai đoạn rất sớm.',
      motherChanges: ['Trễ kinh', 'Có thể bắt đầu có dấu hiệu thai kỳ sớm'],
      tips: ['Dùng que thử thai nếu nghi ngờ', 'Đặt lịch khám thai đầu tiên'],
    ),
    8: PregnancyWeekData(
      week: 8,
      babySize: 'quả mâm xôi',
      babyWeight: '1g',
      babyLength: '1.6cm',
      development:
          'Tim thai và các chi nhỏ đang phát triển. Khuôn mặt bắt đầu có những nét đầu tiên.',
      motherChanges: ['Ốm nghén', 'Căng tức ngực', 'Mệt mỏi'],
      tips: ['Ăn bữa nhỏ, thường xuyên', 'Uống đủ nước', 'Nghỉ ngơi khi cần'],
    ),
    12: PregnancyWeekData(
      week: 12,
      babySize: 'quả mận',
      babyWeight: '14g',
      babyLength: '5.4cm',
      development:
          'Nhiều cơ quan chính đã hình thành. Bé bắt đầu có các cử động nhỏ, dù mẹ có thể chưa cảm nhận rõ.',
      motherChanges: [
        'Gần kết thúc tam cá nguyệt 1',
        'Ốm nghén có thể giảm',
        'Năng lượng có thể cải thiện',
      ],
      tips: [
        'Tiếp tục lịch khám thai',
        'Chọn quần áo thoải mái',
        'Vận động nhẹ nếu được bác sĩ đồng ý',
      ],
    ),
    16: PregnancyWeekData(
      week: 16,
      babySize: 'quả bơ',
      babyWeight: '100g',
      babyLength: '11.6cm',
      development:
          'Bé tiếp tục phát triển phản xạ và có thể bắt đầu phản ứng với âm thanh.',
      motherChanges: [
        'Bụng có thể rõ hơn',
        'Một số mẹ bắt đầu cảm nhận thai máy nhẹ',
      ],
      tips: [
        'Trò chuyện nhẹ nhàng với bé',
        'Cân nhắc yoga bầu nếu phù hợp',
        'Dưỡng ẩm vùng bụng nếu da căng',
      ],
    ),
    20: PregnancyWeekData(
      week: 20,
      babySize: 'quả chuối',
      babyWeight: '300g',
      babyLength: '25cm',
      development:
          'Bạn đang đi được khoảng nửa hành trình. Bé tiếp tục phát triển giác quan và nhịp sinh hoạt.',
      motherChanges: [
        'Thai máy rõ hơn',
        'Có thể đau dây chằng tròn',
        'Có thể thay đổi da',
      ],
      tips: [
        'Khám siêu âm hình thái theo lịch',
        'Chuẩn bị câu hỏi cho bác sĩ',
        'Tiếp tục theo dõi sức khỏe',
      ],
    ),
    24: PregnancyWeekData(
      week: 24,
      babySize: 'bắp ngô',
      babyWeight: '600g',
      babyLength: '30cm',
      development:
          'Phổi và vị giác của bé tiếp tục phát triển. Bé có thể phản ứng với âm thanh bên ngoài.',
      motherChanges: ['Thai máy rõ', 'Đau lưng', 'Có thể có cơn gò sinh lý'],
      tips: [
        'Tìm hiểu lớp tiền sản',
        'Tập cơ sàn chậu nếu phù hợp',
        'Ưu tiên tư thế ngủ nghiêng',
      ],
    ),
    28: PregnancyWeekData(
      week: 28,
      babySize: 'quả cà tím',
      babyWeight: '1kg',
      babyLength: '37cm',
      development:
          'Bước vào tam cá nguyệt 3. Bé tiếp tục tích lũy mỡ và phát triển khả năng nhắm mở mắt.',
      motherChanges: [
        'Đi tiểu thường xuyên hơn',
        'Có thể hụt hơi',
        'Có thể phù chân',
      ],
      tips: [
        'Trao đổi về kế hoạch sinh',
        'Chuẩn bị túi đi sinh',
        'Theo dõi thai máy theo hướng dẫn bác sĩ',
      ],
    ),
    32: PregnancyWeekData(
      week: 32,
      babySize: 'bí đỏ nhỏ',
      babyWeight: '1.7kg',
      babyLength: '42cm',
      development:
          'Bé luyện tập các chuyển động hô hấp và các giác quan tiếp tục hoàn thiện.',
      motherChanges: ['Bụng lớn hơn', 'Khó ngủ hơn', 'Đi tiểu thường xuyên'],
      tips: [
        'Theo dõi cử động thai',
        'Sắp xếp nghỉ thai sản',
        'Nghỉ ngơi nhiều hơn',
      ],
    ),
    36: PregnancyWeekData(
      week: 36,
      babySize: 'bó xà lách',
      babyWeight: '2.6kg',
      babyLength: '47cm',
      development:
          'Bé gần sẵn sàng chào đời. Phổi tiếp tục hoàn thiện và bé có thể dần xuống thấp hơn.',
      motherChanges: [
        'Bụng có thể tụt thấp',
        'Áp lực vùng chậu tăng',
        'Dễ thở hơn ở một số mẹ',
      ],
      tips: [
        'Đi khám hằng tuần theo lịch',
        'Hoàn thiện kế hoạch sinh',
        'Chuẩn bị phương án di chuyển khi sinh',
      ],
    ),
    40: PregnancyWeekData(
      week: 40,
      babySize: 'quả dưa hấu',
      babyWeight: '3.4kg',
      babyLength: '51cm',
      development:
          'Thai kỳ đã đủ tháng. Bé có thể chào đời trong thời gian gần đây.',
      motherChanges: ['Cơn co', 'Có thể vỡ ối', 'Cổ tử cung có thể thay đổi'],
      tips: [
        'Theo dõi dấu hiệu chuyển dạ',
        'Giữ bình tĩnh và nghỉ ngơi',
        'Chuẩn bị túi đi sinh',
      ],
    ),
  };

  static List<String> getAllWeekTips() {
    return [
      'Uống đủ nước mỗi ngày',
      'Nghỉ ngơi và ngủ đủ',
      'Ăn đa dạng rau, trái cây và nguồn đạm phù hợp',
      'Dùng vitamin trước sinh theo hướng dẫn của bác sĩ',
      'Vận động nhẹ nếu được bác sĩ đồng ý',
      'Thực hành thư giãn để giảm căng thẳng',
      'Trò chuyện nhẹ nhàng với bé',
      'Theo dõi thai máy theo hướng dẫn',
      'Đi khám thai đúng lịch',
      'Tìm nhóm hỗ trợ hoặc người thân để chia sẻ khi cần',
    ];
  }

  static String getBabySizeComparison(int week) {
    final comparisons = {
      1: 'hạt anh túc',
      4: 'hạt anh túc',
      5: 'hạt vừng',
      6: 'hạt đậu lăng',
      7: 'quả việt quất',
      8: 'quả mâm xôi',
      9: 'quả nho',
      10: 'quả quất',
      11: 'quả sung',
      12: 'quả mận',
      13: 'quả đào',
      14: 'quả chanh',
      15: 'quả táo',
      16: 'quả bơ',
      17: 'quả lê',
      18: 'khoai lang',
      19: 'quả xoài',
      20: 'quả chuối',
      21: 'củ cà rốt',
      22: 'quả đu đủ',
      23: 'quả bưởi',
      24: 'bắp ngô',
      25: 'bông cải trắng',
      26: 'xà lách',
      27: 'bắp cải',
      28: 'quả cà tím',
      29: 'bí hồ lô',
      30: 'quả dưa leo',
      31: 'quả dừa',
      32: 'bí đỏ nhỏ',
      33: 'quả dứa',
      34: 'dưa lưới',
      35: 'dưa vàng',
      36: 'bó xà lách',
      37: 'cải cầu vồng',
      38: 'tỏi tây',
      39: 'bí ngô',
      40: 'quả dưa hấu',
    };
    return comparisons[week] ?? 'em bé';
  }
}
