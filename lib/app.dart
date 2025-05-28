import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'providers/alarm_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Lắng nghe AlarmProvider
        final alarm = context.watch<AlarmProvider>().current;
        if (alarm != null) {
          Future.microtask(() {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('⚠️ Cảnh báo thiết bị'),
                content: Text('Phát hiện sự cố: ${alarm.message}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      context.read<AlarmProvider>().dismiss();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Đã hiểu'),
                  ),
                ],
              ),
            );
          });
        }

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Power Alert',
          routerConfig: AppRouter.router,
          theme: ThemeData(
            useMaterial3: true,
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: const Color(0xFFF9F1FF),
            fontFamily: 'Roboto',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontSize: 16),
              titleLarge: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
        );
      },
    );
  }
}
