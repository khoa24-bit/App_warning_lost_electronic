// lib/views/home/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/device_controller.dart';
import '../../models/device_model.dart';
import '../../services/device_monitor_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/*─────────────────────────────────────────────────────────*/
class _HomePageState extends State<HomePage> {
  bool _initDone = false;

  final _monitor = DeviceMonitorService();
  final Set<String> _monitoredDeviceIds = <String>{};

  StreamSubscription<AlarmEvent>? _alarmSub;

  /*──────── init / dispose ────────*/
  @override
  void initState() {
    super.initState();

    // Nghe AlarmEvent chỉ một lần
    _alarmSub = _monitor.alarmStream.listen((ev) {
      if (!mounted) return;

      // Điều hướng sang màn hình cảnh báo
      context.push('/device-alert', extra: <String, String>{
        'uid'        : ev.uid,
        'deviceId'   : ev.deviceId,
        'deviceName' : ev.deviceName,
      });
    });
  }

  @override
  void dispose() {
    _alarmSub?.cancel();
    super.dispose();
  }

  /*──────── lifecycle fetch profile + devices ────────*/
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth     = context.read<AuthController>();
    final userCtrl = context.read<UserController>();
    final devCtrl  = context.read<DeviceController>();

    if (!_initDone && auth.user != null && userCtrl.profile == null) {
      _initDone = true;
      userCtrl.fetch(auth.user!.uid, devCtrl);
    }
  }

  Future<void> _pullRefresh(DeviceController devCtrl) => devCtrl.reloadShared();

  /*────────────────────────── UI ─────────────────────────*/
  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthController>();
    final userCtrl = context.watch<UserController>();
    final devCtrl  = context.watch<DeviceController>();

    if (auth.user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    final profile       = userCtrl.profile;
    final ownedDevices  = devCtrl.ownedDevices;
    final sharedDevices = devCtrl.sharedDevices;

    // Loading lần đầu
    if (profile == null && !_initDone) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /*──  Theo dõi thiết bị sở hữu  ──*/
    for (final d in ownedDevices) {
      if (_monitoredDeviceIds.add(d.id)) {
        _monitor.monitorDeviceConnection(
          auth.user!.uid,
          d.id,
          d.name,
          context,
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        title: const Text(
          'Thiết bị của bạn',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: RefreshIndicator(
          onRefresh: () => _pullRefresh(devCtrl),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _UserHeader(
                profileName :
                    profile?.name ?? auth.displayNameFromDB ?? 'Chưa đặt tên',
                profileEmail: profile?.email ?? auth.user!.email ?? '',
              ),
              const SizedBox(height: 12),

              // ---------- Thiết bị của tôi ----------
              const _SectionHeader(title: 'Thiết bị của tôi'),
              if (ownedDevices.isEmpty)
                const _EmptyHint(text: 'Chưa có thiết bị nào.')
              else
                ...ownedDevices.map(_DeviceCard.new),

              const SizedBox(height: 20),

              // ---------- Thiết bị được chia sẻ ----------
              const _SectionHeader(title: 'Thiết bị được chia sẻ'),
              if (sharedDevices.isEmpty)
                const _EmptyHint(text: 'Không có thiết bị nào được chia sẻ.')
              else
                ...sharedDevices.map((d) => _DeviceCard(d, shared: true)),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

/*───────────────────────── Sub-widgets ─────────────────────────*/

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.profileName,
    required this.profileEmail,
  });

  final String profileName;
  final String profileEmail;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        title: Text(
          profileName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(profileEmail),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text('• $text', style: TextStyle(color: Colors.grey[600])),
      );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard(this.d, {this.shared = false});
  final DeviceModel d;
  final bool shared;

  Widget _statusDot() => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: d.status == 'online' ? Colors.green : Colors.red,
          shape: BoxShape.circle,
        ),
      );

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        color: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: _statusDot(),
          title: Text(
            d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'ID: ${d.id} • ${d.location}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: shared ? const Icon(Icons.person_2) : null,
          onTap: () => context.go('/devices/${d.id}'),
        ),
      );
}
