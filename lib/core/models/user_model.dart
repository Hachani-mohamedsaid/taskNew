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
    this.isActive = true,
  });

  // Données statiques pour la démo
  static List<UserModel> get demoUsers => [
        UserModel(
          id: '1',
          email: 'admin@demo.com',
          displayName: 'Admin Principal',
          role: UserRole.admin,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastSeen: DateTime.now(),
        ),
        UserModel(
          id: '2',
          email: 'john@demo.com',
          displayName: 'John Doe',
          role: UserRole.member,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        UserModel(
          id: '3',
          email: 'jane@demo.com',
          displayName: 'Jane Smith',
          role: UserRole.member,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];
}
