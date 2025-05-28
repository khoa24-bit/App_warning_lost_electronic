import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';

// ==== View Pages ====
import '../views/auth/login_page.dart';
import '../views/auth/register_page.dart';
import '../views/home/home_page.dart';
import '../views/home/add_device_page.dart';
import '../views/home/device_detail_page.dart';
import '../views/profile/profile_page.dart';
import '../views/home/main_shell.dart';
import '../views/home/choose_connect_page.dart';
import '../views/home/claim_device_page.dart';
import '../views/home/device_alert_screen.dart';

class AppRouter {
  /// `router` sẽ được gọi trong `main.dart`
  static late final GoRouter router;

  /// Khởi tạo GoRouter với controller để lắng nghe login/logout
  static GoRouter create(AuthController auth) {
    return GoRouter(
      initialLocation: '/login',
      debugLogDiagnostics: true,
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.user != null;
        final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';

        if (!loggedIn && !isAuthRoute) return '/login';
        if (loggedIn && isAuthRoute) return '/home';
        return null;
      },
      routes: [
        /// ---------- Auth ----------
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterPage(),
        ),
         GoRoute(
              path: '/device-alert',
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                return DeviceAlertScreen(
                  uid: extra['uid'] ?? '',
                  deviceId: extra['deviceId'] ?? '',
                  deviceName: extra['deviceName'] ?? '',
                );
              },
            ),

        /// ---------- Shell + BottomNav ----------
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(
              child: child,
              location: state.matchedLocation,
            );
          },
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomePage()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
            GoRoute(path: '/choose-connect', builder: (_, __) => const ChooseConnectPage()),
            GoRoute(path: '/add-device', builder: (_, __) => const AddDevicePage()),
            GoRoute(path: '/claim-device', builder: (_, __) => const ClaimDevicePage()),

            GoRoute(
              path: '/devices/:id',
              builder: (_, state) {
                final deviceId = state.pathParameters['id']!;
                return DeviceDetailPage(deviceId: deviceId);
              },
            ),
           
          ],
        ),
      ],
    );
  }
}
