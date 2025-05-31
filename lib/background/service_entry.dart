import 'dart:async';
import 'package:async/async.dart' show unawaited;                // unawaited()
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/* 1. AudioHandler —— phát file mp3 lặp vô hạn */
@pragma('vm:entry-point')
class AlarmAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  bool _prepared = false;

  Future<void> _prepare() async {
    if (_prepared) return;
    await _player.setAsset('assets/sounds/alarm.mp3');
    await _player.setLoopMode(LoopMode.one);
    _prepared = true;
  }

  Future<void> playLoop() async {
    await _prepare();
    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
    await AudioService.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() => stop();
}

/* 2. Hàm tiện ích gửi notification toàn màn hình */
Future<void> _showFullScreenNotification({
  required String title,
  required String body,
  required String payload,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();

  // Khởi tạo plugin nếu isolate chưa init
  const initSettings =
      InitializationSettings(android: AndroidInitializationSettings('ic_launcher'));
  await plugin.initialize(initSettings);

  // Đảm bảo channel tồn tại, IMPORTANCE_MAX
  const channel = AndroidNotificationChannel(
    'alarm_channel',
    'Alarm Background Service',
    description: 'Thông báo cảnh báo toàn màn hình',
    importance: Importance.max,
  );
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Gửi notification full-screen
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Background Service',
      channelDescription: 'Thông báo cảnh báo toàn màn hình',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ticker: 'ticker',
    ),
  );

  await plugin.show(999, title, body, details, payload: payload);
}

/* 3. Entry-point của isolate background-service */
@pragma('vm:entry-point')
Future<void> serviceEntryPoint(ServiceInstance service) async =>
    runZonedGuarded(() async {
      // Đăng ký binding (và plugin nếu Flutter 3.13+)
      WidgetsFlutterBinding.ensureInitialized();
      // DartPluginRegistrant.ensureInitialized(); // ← Bỏ ghi chú nếu class có sẵn trong SDK của bạn

      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: '🔊 Cảnh báo mất điện',
          content: 'Ứng dụng đang chạy nền để phát chuông.',
        );

        service.on('stopService').listen((_) async {
          await AudioService.stop();
          service.stopSelf();
        });
      }

      // Khởi AudioService & phát chuông
      final handler = await AudioService.init(
        builder: () => AlarmAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'alarm_channel',
          androidNotificationChannelName: 'Alarm Background Service',
          androidNotificationOngoing: true,
        ),
      ) as AlarmAudioHandler;

      unawaited(handler.playLoop());

      // Gửi notification toàn màn hình
      await _showFullScreenNotification(
        title: '⚠️ Thiết bị mất kết nối',
        body: 'Chạm để tắt báo động',
        payload: 'open_alert',
      );

      service.invoke('log', {'msg': '🔁 Alarm background service started'});
    }, (e, st) {
      service.invoke('log', {'error': e.toString(), 'stack': st.toString()});
    });
