import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'controllers/auth_controller.dart';
import 'controllers/device_controller.dart';
import 'controllers/user_controller.dart';
import 'providers/alarm_provider.dart'; // 🆕 Import AlarmProvider
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // AuthController cần khởi tạo sớm để tạo router
  final authController = AuthController();
  AppRouter.router = AppRouter.create(authController);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<DeviceController>(
          create: (_) => DeviceController(),
        ),
        ChangeNotifierProxyProvider2<AuthController, DeviceController, UserController>(
          create: (_) => UserController(),
          update: (_, auth, deviceCtrl, userCtrl) {
            userCtrl ??= UserController();
            final uid = auth.user?.uid;
            if (uid != null) {
              userCtrl.fetch(uid, deviceCtrl);
            }
            return userCtrl;
          },
        ),
        ChangeNotifierProvider<AlarmProvider>( // 🆕 Khởi tạo AlarmProvider
          create: (_) => AlarmProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
