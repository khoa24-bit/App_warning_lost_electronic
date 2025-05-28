import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_model.dart';

class DeviceService {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _codeRef = FirebaseDatabase.instance.ref('shared_codes');

  /* ----------------------------------------------------------------------
   *  1. Lấy danh sách thiết bị của user đang đăng nhập (realtime)
   * -------------------------------------------------------------------- */
  Stream<List<DeviceModel>> getDevicesByUserId(String uid) {
    final devicesRef = _userRef.child(uid).child('devices');
    return devicesRef.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return <DeviceModel>[];

      return raw.entries.map((e) {
        final id = e.key;
        final map = Map<String, dynamic>.from(e.value);
        map['owner'] = uid;
        return DeviceModel.fromMap(id, map);
      }).toList();
    });
  }

Future<void> updateLastSeen(String ownerUid, String deviceId) async {
  await _userRef
      .child(ownerUid)
      .child('devices')
      .child(deviceId)
      .update({'lastSeen': DateTime.now().millisecondsSinceEpoch});
}
  /* ----------------------------------------------------------------------
   *  2. CRUD thiết bị (chỉ chủ sở hữu)
   * -------------------------------------------------------------------- */
  Future<void> addDevice(String ownerUid, DeviceModel device) async {
    await _userRef.child(ownerUid).child('devices').child(device.id).set(device.toMap());
  }

  Future<void> updateDevice(String ownerUid, DeviceModel device) async {
    await _userRef.child(ownerUid).child('devices').child(device.id).update(device.toMap());
  }

  Future<void> deleteDevice(String ownerUid, String deviceId) async {
    // Xoá thiết bị
    await _userRef.child(ownerUid).child('devices').child(deviceId).remove();

    // Xoá mã chia sẻ liên quan
    final codeSnap = await _codeRef.orderByChild('deviceId').equalTo(deviceId).get();
    for (var c in codeSnap.children) {
      await _codeRef.child(c.key!).remove();
    }
  }

  /* ----------------------------------------------------------------------
   *  3. Chia sẻ thủ công thiết bị với người khác
   * -------------------------------------------------------------------- */
  Future<void> shareDevice({
    required String ownerUid,
    required String deviceId,
    required String guestUid,
    required String alias,
  }) async {
    await _userRef
        .child(ownerUid)
        .child('devices')
        .child(deviceId)
        .child('sharedWith')
        .child(guestUid)
        .set({'alias': alias});
  }

  Future<void> unshareDevice({
    required String ownerUid,
    required String deviceId,
    required String guestUid,
  }) async {
    await _userRef
        .child(ownerUid)
        .child('devices')
        .child(deviceId)
        .child('sharedWith')
        .child(guestUid)
        .remove();
  }

  Future<void> revokeAllShares({
    required String ownerUid,
    required String deviceId,
  }) async {
    await _userRef
        .child(ownerUid)
        .child('devices')
        .child(deviceId)
        .child('sharedWith')
        .remove();
  }

  /* ----------------------------------------------------------------------
   *  4. Mã chia sẻ (code 6-ký-tự)
   * -------------------------------------------------------------------- */
  Future<String> createShareCode(String ownerUid, String deviceId) async {
    final existing = await _codeRef.orderByChild('deviceId').equalTo(deviceId).limitToFirst(1).get();
    if (existing.exists) return existing.children.first.key!;

    String code;
    do {
      code = DeviceModel.randomCode(); // sinh code ABC123
    } while ((await _codeRef.child(code).get()).exists);

    await _codeRef.child(code).set({
      'ownerUid': ownerUid,
      'deviceId': deviceId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    return code;
  }

  Future<void> claimDeviceWithCode(String guestUid, String code) async {
    final snap = await _codeRef.child(code).get();
    if (!snap.exists) throw 'Mã không hợp lệ hoặc đã bị xoá';

    final data = Map<String, dynamic>.from(snap.value as Map);
    final ownerUid = data['ownerUid'] as String;
    final deviceId = data['deviceId'] as String;

    await shareDevice(
      ownerUid: ownerUid,
      deviceId: deviceId,
      guestUid: guestUid,
      alias: 'Đã chia sẻ',
    );
  }

  /* ----------------------------------------------------------------------
   *  5. Lấy 1 thiết bị chi tiết
   * -------------------------------------------------------------------- */
  Future<DeviceModel?> getDeviceById({
    required String ownerUid,
    required String deviceId,
  }) async {
    final snap = await _userRef.child(ownerUid).child('devices').child(deviceId).get();
    if (!snap.exists || snap.value is! Map) return null;

    final map = Map<String, dynamic>.from(snap.value as Map);
    map['owner'] = ownerUid;
    return DeviceModel.fromMap(deviceId, map);
  }

  Future<DeviceModel?> getDeviceByIdSimple(String deviceId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await _userRef.child(uid).child('devices').child(deviceId).get();
    if (!snap.exists || snap.value is! Map) return null;

    final map = Map<String, dynamic>.from(snap.value as Map);
    map['owner'] = uid;
    return DeviceModel.fromMap(deviceId, map);
  }

  /* ----------------------------------------------------------------------
   *  6. Lấy danh sách thiết bị được chia sẻ cho user hiện tại
   * -------------------------------------------------------------------- */
  Future<List<DeviceModel>> getDevicesSharedToUser(String guestUid) async {
    final userSnap = await _userRef.get();
    List<DeviceModel> sharedDevices = [];

    for (final user in userSnap.children) {
      final ownerUid = user.key!;
      final deviceSnap = await _userRef.child(ownerUid).child('devices').get();

      for (final device in deviceSnap.children) {
        final deviceId = device.key!;
        final data = Map<String, dynamic>.from(device.value as Map);
        if ((data['sharedWith'] ?? {}).containsKey(guestUid)) {
          data['owner'] = ownerUid;
          sharedDevices.add(DeviceModel.fromMap(deviceId, data));
        }
      }
    }

    return sharedDevices;
  }

  /* ----------------------------------------------------------------------
   *  7. Lấy danh sách người được chia sẻ 1 thiết bị
   * -------------------------------------------------------------------- */
  Future<Map<String, String>> getSharedUsers({
    required String ownerUid,
    required String deviceId,
  }) async {
    final snap = await _userRef
        .child(ownerUid)
        .child('devices')
        .child(deviceId)
        .child('sharedWith')
        .get();

    if (!snap.exists || snap.value is! Map) return {};

    final data = Map<String, dynamic>.from(snap.value as Map);
    return data.map((uid, value) => MapEntry(uid, value['alias'] ?? ''));
  }
}
