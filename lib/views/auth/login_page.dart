import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final e = TextEditingController();
  final p = TextEditingController();
  String? err;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tên app/logo
              const Text(
                'Power Alert',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 32),

              // Email
              TextField(
                controller: e,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: p,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),

              // Hiển thị lỗi
              if (err != null) ...[
                const SizedBox(height: 12),
                Text(
                  err!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 24),

              // Nút đăng nhập
              ElevatedButton(
                onPressed: () async {
                  final res = await context.read<AuthController>().login(e.text, p.text);
                  if (res != null) {
                    setState(() => err = res);
                  } else {
                    context.go('/home');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đăng nhập'),
              ),
              const SizedBox(height: 12),

              // Nút Google
              ElevatedButton.icon(
  onPressed: () async {
    final res = await context.read<AuthController>().loginWithGoogle();
    if (res != null) {
      setState(() => err = res);
    } else {
      context.go('/home');
    }
  },
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    side: const BorderSide(color: Colors.grey),
  ),
  icon: Image.asset(
    'assets/google_logo.png',
    height: 24,
    width: 24,
  ),
  label: const Text(
    'Đăng nhập bằng Google',
    style: TextStyle(fontWeight: FontWeight.w600),
  ),
),


              const SizedBox(height: 16),

              // Đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?'),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Đăng ký ngay'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
