// lib/services/device_monitor_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/device_model.dart';
import '../services/device_service.dart';

/*════════════ 1. AlarmEvent ════════════*/
class AlarmEvent {
  final String uid, deviceId, deviceName;
  AlarmEvent(this.uid, this.deviceId, this.deviceName);
  String get message => 'Thiết bị “$deviceName” mất kết nối!';
}

/*════════════ 2. Singleton Service ════════════*/
class DeviceMonitorService {
  static final DeviceMonitorService _inst = DeviceMonitorService._internal();
  factory DeviceMonitorService() => _inst;
  DeviceMonitorService._internal() { _initNotification(); }

  final _deviceSvc = DeviceService();
  final _player    = AudioPlayer();
  final _notif     = FlutterLocalNotificationsPlugin();

  final _alarmCtrl = StreamController<AlarmEvent>.broadcast();
  Stream<AlarmEvent> get alarmStream => _alarmCtrl.stream;

  final Map<String, bool> _alerted = {};

  /*── 2.1 Notification ──*/
  Future<void> _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: android));
  }

  Future<void> _showNotification(String msg) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'device_channel','Thiết bị',
        importance: Importance.max, priority: Priority.high, playSound: true),
    );
    await _notif.show(0, 'Cảnh báo thiết bị', msg, details);
  }

  /*── 2.2 Âm thanh ──*/
  Future<void> _playAlarm() => _player.play(AssetSource('sounds/alarm.mp3'));
  Future<void> stopAlarm()  => _player.stop();

  /*──────── 3. Theo dõi thiết bị ────────*/
  void monitor(String uid,String deviceId,{String? fallbackName,BuildContext? context}) {
    final ref = FirebaseDatabase.instance.ref('users/$uid/devices/$deviceId');
    ref.keepSynced(true);

    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic,dynamic>?; 
      if (data == null) return;

      final enabled  = data['enabled'] as bool? ?? false;
      final lastSeen = data['lastSeen'] as int? ?? 0;      // millis
      final name     = data['name']    as String? ?? fallbackName ?? deviceId;

      final nowMs    = DateTime.now().millisecondsSinceEpoch;
      final isOffline= (nowMs - lastSeen) > 60*1000;       // >60s

      final key = '$uid/$deviceId';

      if (!enabled) {              // người dùng tắt công-tắc
        _alerted.remove(key);
        stopAlarm();
        return;
      }

      if (isOffline) {
        if (_alerted[key] == true) return;
        _alerted[key] = true;

        _playAlarm();
        _showNotification('Thiết bị “$name” mất kết nối!');
        _alarmCtrl.add(AlarmEvent(uid, deviceId, name));

        if (context!=null && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Thiết bị “$name” mất kết nối!')));
        }
      } else {                     // online trở lại
        _alerted.remove(key);
        stopAlarm();
      }
    });
  }

  /*── Alias ─*/
  void monitorDeviceConnection(String uid,String deviceId,[String? n,BuildContext? c])
        => monitor(uid,deviceId,fallbackName:n,context:c);

  /*── 4. Dừng chuông + disable thiết bị ─*/
  Future<void> silenceAndDisable(AlarmEvent ev) async {
    await stopAlarm();
    await _deviceSvc.updateDevice(
      ev.uid,
      DeviceModel(
        id:ev.deviceId, name:ev.deviceName, location:'',
        owner:ev.uid,  enabled:false, status:'offline',
        lastSeen:DateTime.now().millisecondsSinceEpoch,
        createdAt:DateTime.now().millisecondsSinceEpoch,
        sharedWith:const {}),
    );
    _alerted.remove('${ev.uid}/${ev.deviceId}');
  }

  void dispose(){
    _alarmCtrl.close();
    _player.dispose();
  }
}
