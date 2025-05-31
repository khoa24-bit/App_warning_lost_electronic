import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';             // để dùng unawaited
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'background/service_entry.dart';
import 'routes/app_router.dart';
import 'app.dart';

// Controllers & Providers
import 'controllers/auth_controller.dart';
import 'controllers/device_controller.dart';
import 'controllers/user_controller.dart';
import 'providers/alarm_provider.dart';

/// 👉 Callback cho iOS background isolate
@pragma('vm:entry-point')
Future<bool> _iosBackground(ServiceInstance _) async => true;

late final FlutterLocalNotificationsPlugin _localNotif;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('✅ Firebase initialized');

  // 2️⃣ Tạo router
  final auth = AuthController();
  AppRouter.router = AppRouter.create(auth);

  // 3️⃣ Chạy UI + lắng nghe AlarmProvider
  runApp(
    ChangeNotifierProvider<AlarmProvider>(
      create: (_) => AlarmProvider(),
      child: Consumer<AlarmProvider>(
        builder: (_, alarmProv, __) {
          // Khi đang foreground và có alarm
          if (alarmProv.hasAlarm) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppRouter.router.push('/device-alert', extra: {
                'uid': alarmProv.current!.owner,
                'deviceId': alarmProv.current!.deviceId,
                'deviceName': alarmProv.current!.name,
              });
              alarmProv.reset();
            });
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider(create: (_) => DeviceController()),
              ChangeNotifierProxyProvider2<AuthController, DeviceController,
                  UserController>(
                create: (_) => UserController(),
                update: (_, a, dev, user) {
                  user ??= UserController();
                  final uid = a.user?.uid;
                  if (uid != null) user.fetch(uid, dev);
                  return user;
                },
              ),
            ],
            child: const MyApp(),
          );
        },
      ),
    ),
  );

  // 4️⃣ Xin quyền + khởi tạo background service sau khi UI dựng
  unawaited(_bootstrapBackgroundTasks());
}

/// ================== BOOTSTRAP ==================
Future<void> _bootstrapBackgroundTasks() async {
  try {
    await _requestNotificationPermission();
    await _initLocalNotification();
    await _initializeBackgroundService();
  } catch (e, st) {
    debugPrint('❌ Bootstrap error: $e\n$st');
  }
}

/// 📣 Quyền thông báo (Android 13 + / iOS)
Future<void> _requestNotificationPermission() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    if (!(await Permission.notification.request()).isGranted) {
      debugPrint('⚠️ Notification permission denied');
    }
  }
}

/// ▒▒ Khởi tạo FlutterLocalNotifications + callback ▒▒
Future<void> _initLocalNotification() async {
  _localNotif = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  await _localNotif.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (resp) {
      // payload từ service_entry là "open_alert"
      if ((resp.payload ?? '') == 'open_alert') {
        AppRouter.router.push('/device-alert');
      }
    },
  );

  // Tạo channel (Android) nếu chưa có
  await _localNotif
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'alarm_channel',
        'Alarm Background Service',
        description: 'Thông báo khi chạy nền để phát chuông cảnh báo',
        importance: Importance.high,
      ));
}

/// ▒▒ Khởi động background service ▒▒
Future<void> _initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: serviceEntryPoint,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'alarm_channel',
      initialNotificationTitle: '🔊 Cảnh báo mất điện',
      initialNotificationContent: 'Ứng dụng đang phát chuông cảnh báo…',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.mediaPlayback],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: serviceEntryPoint,
      onBackground: _iosBackground,
    ),
  );

  await service.startService();
  debugPrint('✅ Background service started');
}
