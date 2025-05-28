import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

/// Model đại diện cho một thiết bị được giám sát.
class DeviceModel {
  final String id;
  final String name;
  final String location;
  final String owner;
  final bool enabled;
  final String status;
  final int lastSeen; // millisecondsSinceEpoch
  final int createdAt; // millisecondsSinceEpoch
  final Map<String, dynamic> sharedWith;

  DeviceModel({
    required this.id,
    required this.name,
    required this.location,
    required this.owner,
    required this.enabled,
    required this.status,
    required this.lastSeen,
    required this.createdAt,
    required this.sharedWith,
  });

  /// Khởi tạo từ Map dữ liệu từ Firebase.
  factory DeviceModel.fromMap(String id, Map<String, dynamic> data) {
    return DeviceModel(
      id        : id,
      name      : data['name'] ?? '',
      location  : data['location'] ?? '',
      owner     : data['owner'] ?? '',
      enabled   : data['enabled'] ?? false,
      status    : data['status'] ?? 'offline',
      lastSeen  : (data['lastSeen'] as num?)?.toInt() ?? 0,
      createdAt : (data['createdAt'] as num?)?.toInt() ?? 0,
      sharedWith: Map<String, dynamic>.from(data['sharedWith'] ?? {}),
    );
  }

  /// Khởi tạo từ DataSnapshot của Firebase Realtime Database.
  factory DeviceModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return DeviceModel.fromMap(snapshot.key ?? '', data);
  }

  /// Chuyển đổi thành Map để ghi lên Firebase.
  Map<String, dynamic> toMap() {
    return {
      'name'      : name,
      'location'  : location,
      'owner'     : owner,
      'enabled'   : enabled,
      'status'    : status,
      'lastSeen'  : lastSeen,
      'createdAt' : createdAt,
      'sharedWith': sharedWith,
    };
  }

  /// Tạo một bản sao với các trường cập nhật (nếu có).
  DeviceModel copyWith({
    String? name,
    String? location,
    String? owner,
    bool? enabled,
    String? status,
    int? lastSeen,
    int? createdAt,
    Map<String, dynamic>? sharedWith,
  }) {
    return DeviceModel(
      id        : id,
      name      : name       ?? this.name,
      location  : location   ?? this.location,
      owner     : owner      ?? this.owner,
      enabled   : enabled    ?? this.enabled,
      status    : status     ?? this.status,
      lastSeen  : lastSeen   ?? this.lastSeen,
      createdAt : createdAt  ?? this.createdAt,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  /// Clone với ID mới, giữ nguyên dữ liệu.
  DeviceModel cloneWithId(String newId) {
    return DeviceModel(
      id        : newId,
      name      : name,
      location  : location,
      owner     : owner,
      enabled   : enabled,
      status    : status,
      lastSeen  : lastSeen,
      createdAt : createdAt,
      sharedWith: Map<String, dynamic>.from(sharedWith),
    );
  }

  /// Tạo mã code ngẫu nhiên (6 ký tự, bỏ I, O, 0, 1).
  static String randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Thiết bị đang online nếu status là 'online'.
  bool get isOnline => status == 'online';

  /// Kiểm tra xem thiết bị đã offline quá lâu chưa.
  bool isOfflineTooLong(Duration duration) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return status == 'offline' && (now - lastSeen) > duration.inMilliseconds;
  }

  @override
  String toString() => 'Device($id, $status, lastSeen=$lastSeen)';

  @override
  bool operator ==(Object other) => other is DeviceModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
