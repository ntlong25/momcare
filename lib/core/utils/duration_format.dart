/// Duration text for the counter tools (Phase 20, B10).
library;

String _two(int value) => value.toString().padLeft(2, '0');

/// Stopwatch text: `mm:ss`, or `h:mm:ss` from one hour.
/// Negative durations show as `00:00`.
String formatClock(Duration duration) {
  final total = duration.isNegative ? 0 : duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  if (hours > 0) return '$hours:${_two(minutes)}:${_two(seconds)}';
  return '${_two(minutes)}:${_two(seconds)}';
}

/// Rounded-down minutes: "dưới 1 phút", "25 phút", "1 giờ 5 phút".
String formatMinutes(Duration duration) {
  final minutes = duration.isNegative ? 0 : duration.inMinutes;
  if (minutes < 1) return 'dưới 1 phút';
  if (minutes < 60) return '$minutes phút';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours giờ' : '$hours giờ $rest phút';
}
