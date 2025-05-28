import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/device_model.dart';
import '../../services/device_service.dart';
import 'package:go_router/go_router.dart';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late Future<DeviceModel?> _deviceF;
  final _svc = DeviceService();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _sharing = false;
  String? _shareCode;

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  void _loadDevice() {
    _deviceF = _svc.getDeviceByIdSimple(widget.deviceId);
  }

  Future<void> _toggleDevice(DeviceModel d, bool value) async {
    try {
      await _svc.updateDevice(d.owner, d.copyWith(enabled: value));
      setState(_loadDevice);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: $e')),
      );
    }
  }

  Future<void> _share(DeviceModel d) async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _shareCode = null;
    });

    try {
      final code = await _svc.createShareCode(d.owner, d.id);
      if (!mounted) return;
      setState(() => _shareCode = code);
    } catch (e) {
      debugPrint('createShareCode error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được mã chia sẻ: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _buildDeviceInfo(DeviceModel d) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔌 ${d.name}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('📍 Vị trí: ${d.location}', style: const TextStyle(fontSize: 16)),
            Text(
              '📶 Trạng thái: ${d.status == "online" ? "🟢 Online" : "⚫ Offline"}',
              style: const TextStyle(fontSize: 16),
            ),
            Text('💡 Công tắc: ${d.enabled ? "Bật" : "Tắt"}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerControls(DeviceModel d) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Bật công tắc thiết bị'),
              value: d.enabled,
              onChanged: (v) => _toggleDevice(d, v),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Chia sẻ thiết bị'),
              onPressed: _sharing ? null : () => _share(d),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (_shareCode != null) ...[
              const SizedBox(height: 16),
              Text('Mã chia sẻ:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                _shareCode!,
                style: const TextStyle(
                    fontSize: 20, color: Colors.blue, letterSpacing: 1.5),
              ),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _shareCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã chia sẻ')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Sao chép mã'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thiết bị'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: FutureBuilder<DeviceModel?>(
        future: _deviceF,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data == null) {
            return const Center(child: Text('Không tìm thấy thiết bị'));
          }

          final device = snap.data!;
          final isOwner = device.owner == _uid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeviceInfo(device),
                const SizedBox(height: 16),
                isOwner
                    ? _buildOwnerControls(device)
                    : const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '⚠️ Bạn không có quyền điều khiển thiết bị này',
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
