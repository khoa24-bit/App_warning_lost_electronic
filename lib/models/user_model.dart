class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime registeredAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.registeredAt,
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> data) => UserModel(
        uid: uid,
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        registeredAt: DateTime.fromMillisecondsSinceEpoch(data['registeredAt'] ?? 0),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'registeredAt': registeredAt.millisecondsSinceEpoch,
      };
}
