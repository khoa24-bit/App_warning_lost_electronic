import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/device_model.dart';
import '../services/device_service.dart';
import '../services/device_monitor_service.dart';

class DeviceController with ChangeNotifier {
  final DeviceService _svc = DeviceService();
  final DeviceMonitorService _monitorSvc = DeviceMonitorService();

  /* ================ STATE ================ */
  List<DeviceModel> _ownedDevices = [];
  List<DeviceModel> _sharedDevices = [];

  List<DeviceModel> get ownedDevices => _ownedDevices;
  List<DeviceModel> get sharedDevices => _sharedDevices;

  StreamSubscription? _ownSub;
  final Set<String> _monitoredKeys = {};

  /* ================ LẮNG NGHE DỮ LIỆU ================ */
  void listenDevices(String uid) {
    _ownSub?.cancel();

    // Thiết bị sở hữu
    _ownSub = _svc.getDevicesByUserId(uid).listen((owned) {
      _ownedDevices = owned;
      _setupMonitors();
      notifyListeners();
    });

    // Thiết bị chia sẻ
    reloadShared();
  }

  /// ✅ Hàm reload lại thiết bị chia sẻ (để dùng khi kéo refresh)
  Future<void> reloadShared() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      _sharedDevices = await _svc.getDevicesSharedToUser(uid);
      _setupMonitors();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading shared devices: $e');
    }
  }

  /* ================ THIẾT LẬP GIÁM SÁT ================ */
  void _setupMonitors() {
    for (final d in [..._ownedDevices, ..._sharedDevices]) {
      if (!d.enabled) continue;

      final key = '${d.owner}/${d.id}';
      if (_monitoredKeys.contains(key)) continue;

      _monitoredKeys.add(key);
      _monitorSvc.monitor(d.owner, d.id); // Giám sát kết nối thiết bị
    }
  }

  /* ================ CRUD ================ */
  Future<void> addDevice(DeviceModel d) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _svc.addDevice(uid, d);
    }
  }

  Future<void> toggle(DeviceModel d) async {
    await _svc.updateDevice(d.owner, d.copyWith(enabled: !d.enabled));
  }

  Future<void> delete(String deviceId, String ownerUid) =>
      _svc.deleteDevice(ownerUid, deviceId);

  Future<void> shareDevice({
    required String deviceId,
    required String ownerUid,
    required String guestUid,
    required String alias,
  }) =>
      _svc.shareDevice(
        ownerUid: ownerUid,
        deviceId: deviceId,
        guestUid: guestUid,
        alias: alias,
      );

  Future<void> unshareDevice({
    required String deviceId,
    required String ownerUid,
    required String guestUid,
  }) =>
      _svc.unshareDevice(
        ownerUid: ownerUid,
        deviceId: deviceId,
        guestUid: guestUid,
      );

  /* ================ CLEAN-UP ================ */
  @override
  void dispose() {
    _ownSub?.cancel();
    super.dispose();
  }
}
