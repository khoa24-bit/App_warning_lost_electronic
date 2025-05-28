import 'package:flutter/material.dart';
import '../services/device_monitor_service.dart';

class AlarmProvider with ChangeNotifier {
  AlarmEvent? _current;
  AlarmEvent? get current => _current;

  bool get hasAlarm => _current != null;

  final DeviceMonitorService _monitorService = DeviceMonitorService();

  AlarmProvider() {
    // Lắng nghe luồng báo động từ dịch vụ giám sát thiết bị
    _monitorService.alarmStream.listen(
      (event) {
        _current = event;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[AlarmProvider] Error from alarmStream: $error');
      },
    );
  }

  /// Tắt và reset cảnh báo hiện tại
  Future<void> dismiss() async {
    if (_current != null) {
      try {
        await _monitorService.silenceAndDisable(_current!);
        _current = null;
        notifyListeners();
      } catch (e) {
        debugPrint('[AlarmProvider] Error while dismissing alarm: $e');
      }
    }
  }

  /// Bỏ qua cảnh báo mà không gọi đến service
  void reset() {
    if (_current != null) {
      _current = null;
      notifyListeners();
    }
  }
}
