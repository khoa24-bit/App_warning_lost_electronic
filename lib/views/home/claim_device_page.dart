import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/device_service.dart';
import '../../controllers/device_controller.dart';
import 'package:go_router/go_router.dart';

class ClaimDevicePage extends StatefulWidget {
  const ClaimDevicePage({super.key});

  @override
  State<ClaimDevicePage> createState() => _ClaimDevicePageState();
}

class _ClaimDevicePageState extends State<ClaimDevicePage> {
  final _codeCtrl = TextEditingController();
  final _svc = DeviceService();

  String? _errorText;
  bool _loading = false;

  Future<void> _claimDevice() async {
    final code = _codeCtrl.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập mã chia sẻ');
      return;
    }

    setState(() {
      _errorText = null;
      _loading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _svc.claimDeviceWithCode(uid, code);

      final devCtrl = context.read<DeviceController>();
      devCtrl.listenDevices(uid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiết bị đã được thêm thành công!')),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thêm thiết bị: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận thiết bị'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/choose-connect'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Nhập mã chia sẻ thiết bị (6 ký tự)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Mã chia sẻ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _errorText,
                    prefixIcon: const Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                child:SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text(
                      'Xác nhận',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: _loading ? null : _claimDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                ),
                // const SizedBox(height: 16),
                // TextButton.icon(
                //   icon: const Icon(Icons.arrow_back),
                //   label: const Text('Quay lại chọn kết nối'),
                //   onPressed: () => context.go('/choose-connect'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
