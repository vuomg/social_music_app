/// Utility functions for formatting time
class TimeFormat {
  /// Format Duration thành chuỗi mm:ss
  /// Nếu duration null hoặc zero, trả về "00:00"
  static String formatDuration(Duration? duration) {
    if (duration == null || duration.inSeconds < 0) {
      return '00:00';
    }
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

