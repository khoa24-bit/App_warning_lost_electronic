import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl       = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Bạn chưa đăng nhập');

      final deviceId   = _idCtrl.text.trim();
      final name       = _nameCtrl.text.trim();
      final location   = _locationCtrl.text.trim();
      final createdAt  = DateTime.now().millisecondsSinceEpoch;

      final ref = FirebaseDatabase.instance
          .ref('users/$uid/devices/$deviceId');

      final exists = await ref.get();
      if (exists.exists) throw Exception('ID thiết bị đã tồn tại');

      await ref.set({
        'name'     : name,
        'location' : location,
        'enabled'  : false,
        'status'   : 'offline',
        'createdAt': createdAt,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm thiết bị thành công!')),
        );

        await Future.delayed(Duration.zero);
        context.go('/devices/$deviceId');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thiết bị'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/choose-connect'),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Nhập thông tin thiết bị',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 20),

              // Mã thiết bị
              TextFormField(
                controller: _idCtrl,
                decoration: InputDecoration(
                  labelText: 'Mã thiết bị',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Không bỏ trống ID' : null,
              ),
              const SizedBox(height: 16),

              // Tên thiết bị
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên thiết bị',
                  prefixIcon: const Icon(Icons.devices),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Không bỏ trống tên' : null,
              ),
              const SizedBox(height: 16),

              // Vị trí
              TextFormField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Vị trí sử dụng',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Không bỏ trống vị trí' : null,
              ),
              const SizedBox(height: 28),

              // Nút lưu
              Center(
  child: SizedBox(
    width: 200, // 👈 bạn có thể chỉnh kích thước tại đây
    child: ElevatedButton.icon(
      icon: const Icon(Icons.save),
      label: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Text('Lưu thiết bị'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _loading ? null : _save,
    ),
  ),
),

            ],
          ),
        ),
      ),
    );
  }
}
