import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/ProjectStatus.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ======== AUTHENTICATION ========
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

  /// ======== USERS ========
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

      return users;
    } catch (e) {
      debugPrint('Erreur récupération users : $e');
      return [];
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

  /// ======== PROJECTS ========
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

      await docRef.set({
        'id': docRef.id,
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'createdBy': ownerId,
        'members': members,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': status.toString().split('.').last,
        'priority': priority,
        'startDate': startDate != null ? Timestamp.fromDate(startDate) : FieldValue.serverTimestamp(),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'assignedUsers': members,
        'progress': 0,
      });
    } catch (e, stack) {
      debugPrint('Erreur Firestore lors de l\'ajout du projet: $e\n$stack');
      rethrow;
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
          startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate(),
          createdBy: data['createdBy'] ?? '',
          assignedUsers: List<String>.from(data['assignedUsers'] ?? []),
          progress: data['progress'] ?? 0,
          priority: data['priority'] ?? 'medium',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          members: List<String>.from(data['members'] ?? []),
          ownerId: data['ownerId'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user projects: ${e.toString()}');
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
              (data['dueDate'] as Timestamp).toDate().isBefore(DateTime.now())) {
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
            ? (completedTasks / (completedTasks + activeTasks + overdueTasks)) * 100
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

  /// ======== TASKS ========
  Future<void> createTaskModel(TaskModel task) async {
    await _firestore.collection('tasks').add({
      'title': task.title,
      'description': task.description,
      'projectId': task.projectId,
      'assignedTo': task.assignedTo,
      'status': task.status.name,
      'priority': task.priority.name,
      'dueDate': task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
      'createdAt': task.createdAt,
      'updatedAt': task.updatedAt,
      'createdBy': task.createdBy,
      'subTasks': task.subTasks.map((st) => {
            'id': st.id,
            'title': st.title,
            'isCompleted': st.isCompleted,
            'createdAt': st.createdAt,
          }).toList(),
      'attachments': task.attachments,
      'comments': task.comments.map((c) => {
            'id': c.id,
            'userId': c.userId,
            'userName': c.userName,
            'content': c.content,
            'createdAt': c.createdAt,
          }).toList(),
      'commentsCount': task.commentsCount,
    });
  }

  Future<List<TaskModel>> getTasksByUser(String userId, {int limit = 5}) async {
    final recent = await getRecentTasks(userId, limit: limit);
    return recent.map((t) => TaskModel(
          id: t['id'],
          title: t['title'],
          description: t['description'],
          projectId: t['projectId'],
          assignedTo: [userId],
          status: TaskStatus.values.firstWhere(
            (s) => s.name.toLowerCase() == (t['status'] ?? 'todo').toLowerCase(),
            orElse: () => TaskStatus.todo,
          ),
          priority: TaskPriority.values.firstWhere(
            (p) => p.name.toLowerCase() == (t['priority'] ?? 'medium').toLowerCase(),
            orElse: () => TaskPriority.medium,
          ),
          dueDate: t['dueDate'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: userId,
          subTasks: [],
          attachments: [],
          comments: [],
          commentsCount: 0,
        )).toList();
  }

Future<List<TaskModel>> getTasksCreatedByUser(String userId) async {
  try {
    final query = await _firestore
        .collection('tasks')
        .where('createdBy', isEqualTo: userId) // 🔹 filtre sur l'auteur
        .get();
        debugPrint('Nombre de tâches trouvées: ${query.docs.length}');
for (var doc in query.docs) {
  debugPrint('Doc: ${doc.data()}');
}

    return query.docs.map((doc) {
      final data = doc.data();
      return TaskModel(
        id: doc.id,
        title: data['title'] ?? 'Sans titre',
        description: data['description'] ?? '',
        projectId: data['projectId'] ?? '',
        assignedTo: List<String>.from(data['assignedTo'] ?? []),
        status: TaskStatus.values.firstWhere(
          (s) => s.name.toLowerCase() == (data['status'] ?? 'todo').toLowerCase(),
          orElse: () => TaskStatus.todo,
        ),
        priority: TaskPriority.values.firstWhere(
          (p) => p.name.toLowerCase() == (data['priority'] ?? 'medium').toLowerCase(),
          orElse: () => TaskPriority.medium,
        ),
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: data['createdBy'] ?? '',
        subTasks: (data['subTasks'] as List<dynamic>?)
                ?.map((st) => SubTask(
                      id: st['id'],
                      title: st['title'],
                      isCompleted: st['isCompleted'] ?? false,
                      createdAt: (st['createdAt'] as Timestamp?)?.toDate(),
                    ))
                .toList() ??
            [],
        attachments: List<String>.from(data['attachments'] ?? []),
        comments: (data['comments'] as List<dynamic>?)
                ?.map((c) => Comment(
                      id: c['id'],
                      userId: c['userId'],
                      userName: c['userName'],
                      content: c['content'],
                      createdAt: (c['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    ))
                .toList() ??
            [],
        commentsCount: data['commentsCount'] ?? 0,
      );
    }).toList();
  } catch (e) {
    debugPrint('Erreur getTasksCreatedByUser: $e');
    return [];
  }
}


  Future<List<Map<String, dynamic>>> getRecentTasks(String userId, {int limit = 5}) async {
    try {
      final query = await _firestore
          .collectionGroup('tasks')
          .where('assignedTo', arrayContains: userId)
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
          'status': data['status'] ?? 'todo',
          'priority': data['priority'] ?? 'medium',
          'isCompleted': data['isCompleted'] ?? false,
          'dueDate': (data['dueDate'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching recent tasks: ${e.toString()}');
      return [];
    }
  }

  /// ======== UTILITAIRES ========
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

  /// Convertit TaskStatus en texte lisible
  String getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'À faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.completed:
        return 'Terminé';
      case TaskStatus.archived:
        return 'Archivé';
    }
  }


/// ======== TASKS (CRUD) ========
Future<void> updateTask(TaskModel task) async {
  try {
    await _firestore.collection('tasks').doc(task.id).update({
      'title': task.title,
      'description': task.description,
      'status': task.status.name,
      'priority': task.priority.name,
      'dueDate': task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
      'assignedTo': task.assignedTo,
    });
    debugPrint("✅ Tâche ${task.id} mise à jour");
  } catch (e) {
    debugPrint("❌ Erreur updateTask: $e");
    rethrow;
  }
}

Future<void> deleteTask(String taskId) async {
  try {
    await _firestore.collection('tasks').doc(taskId).delete();
    debugPrint("✅ Tâche $taskId supprimée");
  } catch (e) {
    debugPrint("❌ Erreur deleteTask: $e");
    rethrow;
  }
}

Future<void> assignTask(String taskId, List<String> userIds) async {
  try {
    await _firestore.collection('tasks').doc(taskId).update({
      'assignedTo': userIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint("✅ Tâche $taskId assignée à $userIds");
  } catch (e) {
    debugPrint("❌ Erreur assignTask: $e");
    rethrow;
  }
}

// 🔹 Récupérer les membres assignés à une tâche
Future<List<String>> getTaskMembers(String taskId) async {
  try {
    final doc = await _firestore.collection('tasks').doc(taskId).get();

    if (doc.exists) {
      final data = doc.data()!;
      final members = List<String>.from(data['assignedTo'] ?? []);
      return members;
    } else {
      return [];
    }
  } catch (e) {
    print('Erreur lors de la récupération des membres de la tâche: $e');
    return [];
  }
}

// 🔹 Mettre à jour les membres assignés à une tâche
Future<void> updateTaskMembers(String taskId, List<String> members) async {
  try {
    await _firestore.collection('tasks').doc(taskId).update({'assignedTo': members});
    print("Membres de la tâche mis à jour avec succès");
  } catch (e) {
    print("Erreur lors de la mise à jour des membres: $e");
    throw Exception("Erreur lors de la mise à jour des membres: $e");
  }
}

/// Statistiques des tâches créées par l'utilisateur
Future<Map<String, dynamic>> getCreatedTaskStats(String userId) async {
  try {
    // 🔹 Récupérer toutes les tâches créées par l'utilisateur
    final query = await _firestore
        .collection('tasks')
        .where('createdBy', isEqualTo: userId)
        .get();

    int totalTasks = query.docs.length;
    int activeTasks = 0;
    int completedTasks = 0;
    int overdueTasks = 0;

    for (var doc in query.docs) {
  final data = doc.data();

  bool isCompleted = data['status']?.toString().toLowerCase() == 'completed';
  Timestamp? dueDateTS = data['dueDate'] as Timestamp?;
  DateTime? dueDate = dueDateTS?.toDate();

  if (isCompleted) {
    completedTasks++;
  } else if (dueDate != null && dueDate.isBefore(DateTime.now())) {
    overdueTasks++;
  } else {
    activeTasks++;
  }
}


    double completionPercentage = totalTasks > 0
        ? (completedTasks / totalTasks) * 100
        : 0;

    return {
      'totalTasks': totalTasks,
      'activeTasks': activeTasks,
      'completedTasks': completedTasks,
      'overdueTasks': overdueTasks,
      'completionPercentage': completionPercentage,
    };
  } catch (e) {
    debugPrint('Erreur getCreatedTaskStats: $e');
    return {
      'totalTasks': 0,
      'activeTasks': 0,
      'completedTasks': 0,
      'overdueTasks': 0,
      'completionPercentage': 0,
    };
  }
}





}
