import 'package:cloud_firestore/cloud_firestore.dart';
    import 'package:collaborative_task_manager/core/models/ProjectStatus.dart';
    import 'package:firebase_auth/firebase_auth.dart';
    import 'package:flutter/material.dart';
    import '../models/user_model.dart';
    import '../models/project_model.dart';

    class FirebaseService {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      Future<UserCredential> createUserWithEmailAndPassword(
        String email,
        String password,
      ) async {
        try {
          return await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          throw _handleAuthException(e);
        }
      }

      Future<void> saveUserData({
        required String userId,
        required String email,
        required String firstName,
        required String lastName,
        required String role,
        String? profileImageUrl,
      }) async {
        try {
          await _firestore.collection('users').doc(userId).set({
            'id': userId,
            'email': email,
            'firstName': firstName,
            'lastName': lastName,
            'displayName': '$firstName $lastName',
            'role': role,
            if (profileImageUrl != null) 'photoURL': profileImageUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
            'isActive': true,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving user data: ${e.toString()}');
          rethrow;
        }
      }

 Future<List<UserModel>> getAllUsers() async {
  try {
    final querySnapshot = await _firestore.collection('users').get();
    final users = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return UserModel(
        id: data['id'] ?? doc.id,
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? '',
        photoURL: data['photoURL'],
        role: _parseUserRole(data['role']),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data['isActive'] ?? true,
      );
    }).toList();

    // 🔹 Debug print de la liste
    debugPrint('Liste des utilisateurs : ${users.map((u) => u.displayName).toList()}');

    return users;
  } catch (e) {
    debugPrint('Erreur récupération users : $e');
    return [];
  }
}


      Future<Map<String, dynamic>> getProjectStats(String userId) async {
        try {
          final projects = await _firestore
              .collection('projects')
              .where('members', arrayContains: userId)
              .get();

          int totalProjects = projects.docs.length;
          int activeTasks = 0;
          int completedTasks = 0;
          int overdueTasks = 0;

          for (var project in projects.docs) {
            final tasks = await _firestore
                .collection('projects')
                .doc(project.id)
                .collection('tasks')
                .get();

            for (var task in tasks.docs) {
              final data = task.data();
              if (data['isCompleted'] == true) {
                completedTasks++;
              } else if (data['dueDate'] != null &&
                  (data['dueDate'] as Timestamp)
                      .toDate()
                      .isBefore(DateTime.now())) {
                overdueTasks++;
              } else {
                activeTasks++;
              }
            }
          }

          return {
            'totalProjects': totalProjects,
            'activeTasks': activeTasks,
            'completedTasks': completedTasks,
            'overdueTasks': overdueTasks,
            'completionPercentage': totalProjects > 0
                ? (completedTasks / (completedTasks + activeTasks + overdueTasks)) *
                    100
                : 0,
          };
        } catch (e) {
          debugPrint('Error fetching project stats: ${e.toString()}');
          return {
            'totalProjects': 0,
            'activeTasks': 0,
            'completedTasks': 0,
            'overdueTasks': 0,
            'completionPercentage': 0,
          };
        }
      }

      Future<List<ProjectModel>> getUserProjects(String userId) async {
        try {
          final query = await _firestore
              .collection('projects')
              .where('members', arrayContains: userId)
              .orderBy('createdAt', descending: true)
              .get();

          return query.docs.map((doc) {
            final data = doc.data();
            return ProjectModel(
              id: doc.id,
              name: data['name'] ?? 'Sans nom',
              description: data['description'] ?? '',
              status: _parseProjectStatus(data['status']),
              startDate:
                  (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              endDate: (data['endDate'] as Timestamp?)?.toDate(),
              createdBy: data['createdBy'] ?? '',
              assignedUsers: List<String>.from(data['assignedUsers'] ?? []),
              progress: data['progress'] ?? 0,
              priority: data['priority'] ?? 'medium',
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              updatedAt:
                  (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              members: List<String>.from(data['members'] ?? []),
              ownerId: data['ownerId'],
            );
          }).toList();
        } catch (e) {
          debugPrint('Error fetching user projects: ${e.toString()}');
          return [];
        }
      }

      Future<List<Map<String, dynamic>>> getRecentTasks(String userId,
          {int limit = 5}) async {
        try {
          final query = await _firestore
              .collectionGroup('tasks')
              .where('assignedTo', isEqualTo: userId)
              .orderBy('dueDate', descending: false)
              .limit(limit)
              .get();

          return query.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'projectId': doc.reference.parent.parent?.id,
              'title': data['title'] ?? 'Sans titre',
              'description': data['description'] ?? '',
              'isCompleted': data['isCompleted'] ?? false,
              'dueDate': (data['dueDate'] as Timestamp?)?.toDate(),
              'priority': data['priority'] ?? 'medium',
            };
          }).toList();
        } catch (e) {
          debugPrint('Error fetching recent tasks: ${e.toString()}');
          return [];
        }
      }

      /// Ajout dynamique d'un projet avec membres (clients)
      Future<void> createProject({
  required String name,
  required String description,
  required String ownerId,
  List<String> members = const [],
  ProjectStatus status = ProjectStatus.active,
  String priority = 'medium',
  DateTime? startDate,
  DateTime? endDate,
}) async {
  try {
    final docRef = _firestore.collection('projects').doc();

    debugPrint(
        'Enregistrement Firestore: id=${docRef.id}, name=$name, ownerId=$ownerId, members=$members');

    await docRef.set({
      'id': docRef.id, // 🔑 on stocke l’ID dans le doc
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'createdBy': ownerId,
      'members': members,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': status.toString().split('.').last,
      'priority': priority,
      'startDate': startDate != null
          ? Timestamp.fromDate(startDate)
          : FieldValue.serverTimestamp(),
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'assignedUsers': members,
      'progress': 0,
    });

    debugPrint('Projet ajouté avec succès dans Firestore');
  } catch (e, stack) {
    debugPrint('Erreur Firestore lors de l\'ajout du projet: $e\n$stack');
    rethrow;
  }
}


      Future<List<Map<String, dynamic>>> getClients() async {
        final snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'client')
            .get();
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'displayName': data['displayName'] ?? '',
            'email': data['email'] ?? '',
          };
        }).toList();
      }

      Future<void> createTask({
        required String projectId,
        required String title,
        required String description,
        required String assignedTo,
        String priority = 'medium',
        DateTime? dueDate,
      }) async {
        try {
          await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('tasks')
              .add({
            'title': title,
            'description': description,
            'assignedTo': assignedTo,
            'priority': priority,
            'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
            'isCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Error creating task: ${e.toString()}');
          rethrow;
        }
      }

      UserRole _parseUserRole(String? role) {
        switch (role?.toLowerCase()) {
          case 'admin':
            return UserRole.admin;
          case 'prestataire':
            return UserRole.prestataire;
          case 'member':
            return UserRole.member;
          default:
            return UserRole.guest;
        }
      }

      ProjectStatus _parseProjectStatus(String? status) {
        switch (status?.toLowerCase()) {
          case 'completed':
            return ProjectStatus.completed;
          case 'archived':
            return ProjectStatus.archived;
          case 'on_hold':
            return ProjectStatus.onHold;
          default:
            return ProjectStatus.active;
        }
      }

      Exception _handleAuthException(FirebaseAuthException e) {
        switch (e.code) {
          case 'email-already-in-use':
            return Exception('This email is already registered');
          case 'invalid-email':
            return Exception('Please enter a valid email address');
          case 'weak-password':
            return Exception('Password must be at least 6 characters');
          default:
            return Exception('Authentication failed: ${e.message}');
        }
      }

      Future<UserModel?> getUserModel(String userId) async {
  try {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return UserModel(
      id: data['id'] ?? doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '${data['firstName']} ${data['lastName']}',
      photoURL: data['photoURL'],
      role: _parseUserRole(data['role']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  } catch (e) {
    debugPrint('Erreur getUserModel: $e');
    return null;
  }
}

      

    }
    
