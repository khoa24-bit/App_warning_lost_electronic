import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import './views/auth/login_page.dart';    // tuỳ bạn đặt tên
import './views/profile/profile_page.dart'; // hoặc HomePage của bạn

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.user == null) {
      return const LoginPage(); // 👉 Trang đăng nhập
    } else {
      return const ProfilePage(); // 👉 Hoặc màn chính
    }
  }
}
