import '../../core/data/content_pack_service.dart';
import '../../core/models/daily_item_model.dart';

/// Guidance text for the counter tools, reused from the daily tips content
/// (`assets/content/daily/daily_tips.json`) with built-in fallbacks.
class ToolGuidance {
  static const String kickTitle = 'Theo dõi thai máy mỗi ngày';
  static const String fiveOneOneTitle = 'Quy tắc 5-1-1';
  static const String whenToGoTitle = 'Khi nào đến viện';

  static const String kickFallback =
      'Từ tuần 28, để ý cử động thai mỗi ngày. Thai máy giảm rõ hoặc không '
      'thấy là lý do đi khám ngay, không chờ đến hôm sau.';
  static const String fiveOneOneFallback =
      'Một hướng dẫn thường dùng: cơn co cách nhau 5 phút, mỗi cơn 1 phút, '
      'kéo dài 1 giờ thì đến viện. Hãy hỏi bác sĩ về hướng dẫn riêng của bạn.';
  static const String whenToGoFallback =
      'Đến viện khi vỡ ối, ra máu, thai máy giảm, đau bụng liên tục hoặc cơn '
      'co đều theo hướng dẫn của bác sĩ.';

  /// Same warning as the "Cơn co tử cung đều đặn trước 37 tuần" sign in
  /// `pregnant_warning_signs.json`.
  static const String under37Weeks =
      'Nếu chưa đủ 37 tuần mà có cơn co tử cung đều đặn, hãy đi khám ngay.';

  static String kickGuidance([DailyPack? pack]) =>
      _body(pack, kickTitle, kickFallback);

  static String fiveOneOne([DailyPack? pack]) =>
      _body(pack, fiveOneOneTitle, fiveOneOneFallback);

  static String whenToGo([DailyPack? pack]) =>
      _body(pack, whenToGoTitle, whenToGoFallback);

  static String _body(DailyPack? pack, String title, String fallback) {
    final items = (pack ?? ContentPackService.dailyTipsPack).items;
    for (final item in items) {
      if (item.title == title && item.body.trim().isNotEmpty) {
        return item.body.trim();
      }
    }
    return fallback;
  }
}
