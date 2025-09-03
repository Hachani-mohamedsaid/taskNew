import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, prestataire, member, guest }

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.role,
    required this.createdAt,
    required this.lastSeen,
    this.isActive = true, String? photoUrl,
  });

  /// ✅ Méthode copyWith
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
    );
  }

  /// ✅ Conversion depuis Firestore
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.member,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastSeen: (json['lastSeen'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// ✅ Conversion vers Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'isActive': isActive,
    };
  }
}
