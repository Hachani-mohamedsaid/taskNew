import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collaborative_task_manager/core/models/ProjectStatus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

import '../models/notification_model.dart';

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

      // Notifier les membres du nouveau projet
      await notifyProjectCreated(
        projectId: docRef.id,
        projectName: name,
        creatorId: ownerId,
        memberIds: members,
      );
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
    final docRef = await _firestore.collection('tasks').add({
      'title': task.title,
      'description': task.description,
      'projectId': task.projectId,
      'assignedTo': task.assignedTo,
      'status': task.status.name,
      'priority': task.priority.name,
      'dueDate': task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'updatedAt': Timestamp.fromDate(task.updatedAt),
      'createdBy': task.createdBy,
      'subTasks': task.subTasks.map((st) => {
            'id': st.id,
            'title': st.title,
            'isCompleted': st.isCompleted,
            'createdAt': st.createdAt != null ? Timestamp.fromDate(st.createdAt!) : null,
          }).toList(),
      'attachments': task.attachments,
    });

    // Notifier les utilisateurs assignés
    await notifyTaskAssigned(
      taskId: docRef.id,
      taskTitle: task.title,
      assignerId: task.createdBy,
      assigneeIds: task.assignedTo,
    );
  }

  Future<List<TaskModel>> getTasksByUser(String userId, {int limit = 5}) async {
    try {
      final query = await _firestore
          .collection('tasks')
          .where('assignedTo', arrayContains: userId)
          .orderBy('dueDate', descending: false)
          .limit(limit)
          .get();

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
                        id: st['id'] ?? '',
                        title: st['title'] ?? '',
                        isCompleted: st['isCompleted'] ?? false,
                        createdAt: (st['createdAt'] as Timestamp?)?.toDate(),
                      ))
                  .toList() ??
              [],
          attachments: List<String>.from(data['attachments'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur getTasksByUser: $e');
      return [];
    }
  }

  Future<List<TaskModel>> getTasksCreatedByUser(String userId) async {
    try {
      final query = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();
      
      debugPrint('Nombre de tâches trouvées: ${query.docs.length}');

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
                        id: st['id'] ?? '',
                        title: st['title'] ?? '',
                        isCompleted: st['isCompleted'] ?? false,
                        createdAt: (st['createdAt'] as Timestamp?)?.toDate(),
                      ))
                  .toList() ??
              [],
          attachments: List<String>.from(data['attachments'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur getTasksCreatedByUser: $e');
      return [];
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
      debugPrint('Erreur lors de la récupération des membres de la tâche: $e');
      return [];
    }
  }

  // 🔹 Mettre à jour les membres assignés à une tâche
  Future<void> updateTaskMembers(String taskId, List<String> members) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({'assignedTo': members});
      debugPrint("Membres de la tâche mis à jour avec succès");
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour des membres: $e");
      throw Exception("Erreur lors de la mise à jour des membres: $e");
    }
  }

  /// Statistiques des tâches créées par l'utilisateur
  Future<Map<String, dynamic>> getCreatedTaskStats(String userId) async {
    try {
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

  /// ======== NOTIFICATIONS ========
  Future<void> sendNotification({
    required String title,
    required String message,
    required NotificationType type,
    required String senderId,
    required String receiverId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      
      final notificationData = {
        'id': docRef.id,
        'title': title,
        'message': message,
        'type': type.toString().split('.').last,
        'senderId': senderId,
        'receiverId': receiverId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (data != null) 'data': data,
      };

      await docRef.set(notificationData);
      
      debugPrint('📨 Notification envoyée à $receiverId: $title');
      
      // Envoyer une notification push si l'utilisateur n'est pas en ligne
      await _sendPushNotification(notificationData);
    } catch (e) {
      debugPrint('❌ Erreur envoi notification: $e');
      rethrow;
    }
  }

  Future<void> _sendPushNotification(Map<String, dynamic> notification) async {
    // Implémentez ici l'envoi de notifications push FCM
    debugPrint('📲 Push notification à ${notification['receiverId']}');
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return NotificationModel.fromJson({
                ...data,
                'id': doc.id,
              });
            })
            .toList());
  }

  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      debugPrint('✅ Notification $notificationId marquée comme lue');
    } catch (e) {
      debugPrint('❌ Erreur markAsRead: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      debugPrint('✅ Toutes les notifications marquées comme lues pour $userId');
    } catch (e) {
      debugPrint('❌ Erreur markAllAsRead: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return query.docs.length;
    } catch (e) {
      debugPrint('❌ Erreur getUnreadCount: $e');
      return 0;
    }
  }

  /// ======== NOTIFICATIONS SPÉCIFIQUES ========
  Future<void> notifyTaskAssigned({
    required String taskId,
    required String taskTitle,
    required String assignerId,
    required List<String> assigneeIds,
  }) async {
    final assigner = await getUserModel(assignerId);
    
    for (final assigneeId in assigneeIds) {
      await sendNotification(
        title: '📋 Nouvelle tâche assignée',
        message: '${assigner?.displayName} vous a assigné la tâche "$taskTitle"',
        type: NotificationType.taskAssigned,
        senderId: assignerId,
        receiverId: assigneeId,
        data: {
          'taskId': taskId,
          'taskTitle': taskTitle,
          'type': 'task_assigned'
        },
      );
    }
  }

  Future<void> notifyTaskCompleted({
    required String taskId,
    required String taskTitle,
    required String completerId,
    required String projectOwnerId,
  }) async {
    final completer = await getUserModel(completerId);
    
    await sendNotification(
      title: '✅ Tâche complétée',
      message: '${completer?.displayName} a complété la tâche "$taskTitle"',
      type: NotificationType.taskCompleted,
      senderId: completerId,
      receiverId: projectOwnerId,
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'type': 'task_completed'
      },
    );
  }

  Future<void> notifyProjectCreated({
    required String projectId,
    required String projectName,
    required String creatorId,
    required List<String> memberIds,
  }) async {
    final creator = await getUserModel(creatorId);
    
    for (final memberId in memberIds) {
      if (memberId != creatorId) { // Ne pas notifier le créateur
        await sendNotification(
          title: '🏗️ Nouveau projet',
          message: '${creator?.displayName} vous a ajouté au projet "$projectName"',
          type: NotificationType.projectCreated,
          senderId: creatorId,
          receiverId: memberId,
          data: {
            'projectId': projectId,
            'projectName': projectName,
            'type': 'project_created'
          },
        );
      }
    }
  }

  Future<void> notifyPrestataireTaskAssigned({
    required String taskId,
    required String taskTitle,
    required String adminId,
    required String prestataireId,
  }) async {
    final admin = await getUserModel(adminId);
    
    await sendNotification(
      title: '📋 Tâche assignée par admin',
      message: 'L\'administrateur ${admin?.displayName} vous a assigné la tâche "$taskTitle"',
      type: NotificationType.taskAssigned,
      senderId: adminId,
      receiverId: prestataireId,
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'type': 'task_assigned_by_admin'
      },
    );
  }

  Future<void> notifyAdminTaskCompletedByPrestataire({
    required String taskId,
    required String taskTitle,
    required String prestataireId,
    required String adminId,
  }) async {
    final prestataire = await getUserModel(prestataireId);
    
    await sendNotification(
      title: '✅ Tâche complétée par prestataire',
      message: 'Le prestataire ${prestataire?.displayName} a complété la tâche "$taskTitle"',
      type: NotificationType.taskCompleted,
      senderId: prestataireId,
      receiverId: adminId,
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'type': 'task_completed_by_prestataire'
      },
    );
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
      case 'client':
        return UserRole.guest;
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

  /// Récupérer tous les prestataires
  Future<List<UserModel>> getPrestataires() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'prestataire')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: data['id'] ?? doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? '',
          photoURL: data['photoURL'],
          role: UserRole.prestataire,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur récupération prestataires: $e');
      return [];
    }
  }

  /// Récupérer tous les administrateurs
  Future<List<UserModel>> getAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: data['id'] ?? doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? '',
          photoURL: data['photoURL'],
          role: UserRole.admin,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur récupération admins: $e');
      return [];
    }
  }

  // Dans FirebaseService
Future<void> sendNotificationToPrestataire({
  required String prestataireId,
  required String title,
  required String message,
  required String adminId,
  Map<String, dynamic>? data,
}) async {
  try {
    await sendNotification(
      title: title,
      message: message,
      type: NotificationType.system,
      senderId: adminId,
      receiverId: prestataireId,
      data: data,
    );
    
    debugPrint('✅ Notification envoyée au prestataire $prestataireId');
  } catch (e) {
    debugPrint('❌ Erreur envoi notification prestataire: $e');
    rethrow;
  }
}

Future<void> sendNotificationToAdmin({
  required String prestataireId,
  required String title,
  required String message,
  Map<String, dynamic>? data,
}) async {
  try {
    // Récupérer tous les admins
    final admins = await getAdmins();
    
    for (final admin in admins) {
      await sendNotification(
        title: title,
        message: message,
        type: NotificationType.message,
        senderId: prestataireId,
        receiverId: admin.id,
        data: data,
      );
    }
    
    debugPrint('✅ Notification envoyée à tous les admins');
  } catch (e) {
    debugPrint('❌ Erreur envoi notification admin: $e');
    rethrow;
  }
}
}