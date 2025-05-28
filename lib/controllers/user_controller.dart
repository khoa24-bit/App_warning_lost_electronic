import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import 'device_controller.dart'; // Thêm import này

class UserController with ChangeNotifier {
  final _db = FirebaseDatabase.instance.ref('users');
  UserModel? profile;

  Future<void> fetch(String uid, DeviceController devCtrl) async {
    final snapshot = await _db.child(uid).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      profile = UserModel.fromMap(uid, data);

      devCtrl.listenDevices(uid); // ✅ Gọi lấy thiết bị sau khi có user

      notifyListeners();
    } else {
      print("⚠️ Không tìm thấy user với uid: $uid");
    }
  }

  void logout() {
    profile = null;
    notifyListeners();
  }
}
