import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceAlertScreen extends StatelessWidget {
  final String uid;
  final String deviceId;
  final String deviceName;

  const DeviceAlertScreen({
    super.key,
    required this.uid,
    required this.deviceId,
    required this.deviceName,
  });

  Future<void> _turnOffDevice(BuildContext context) async {
    final ref = FirebaseDatabase.instance.ref("users/$uid/devices/$deviceId");
    await ref.update({'enabled': false});

    Navigator.of(context).pop(); // Thoát màn hình cảnh báo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Cảnh báo thiết bị'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Thiết bị "$deviceName" mất kết nối!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.power_settings_new),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => _turnOffDevice(context),
                  label: const Text('Tắt báo động & thiết bị'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
