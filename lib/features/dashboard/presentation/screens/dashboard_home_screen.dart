import 'dart:async';

import 'package:collaborative_task_manager/features/dashboard/presentation/screens/AdminNotificationScreen%20.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/services/project_service.dart';
import '../../../../core/services/firebase_service.dart' as core;
import '../widgets/dashboard_stats.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_tasks.dart';
import 'notifications_screen.dart';


class DashboardHomeScreen extends StatefulWidget {
  final UserModel currentUser;
  final ProjectService projectService;
  final core.FirebaseService firebaseService;

  const DashboardHomeScreen({
    super.key,
    required this.currentUser,
    required this.projectService,
    required this.firebaseService,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  late Future<Map<String, dynamic>> _projectStatsFuture;
  late Future<Map<String, dynamic>> _taskStatsFuture;
  late Future<List<ProjectModel>> _projectsFuture;
  late Future<List<TaskModel>> _recentTasksFuture;
  int _unreadNotifications = 0;
  late StreamSubscription<int> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  void _setupNotifications() {
    _notificationSubscription = widget.firebaseService
        .getUnreadCountStream(widget.currentUser.id)
        .listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    });
  }

 void _loadData() async {
  // 1️⃣ Mettre à jour les tâches en retard
  await widget.firebaseService.updateOverdueTasks(widget.currentUser.id);

  // 2️⃣ Charger les futures après la mise à jour
  setState(() {
    _projectStatsFuture = widget.projectService.getProjectStats();
    _projectsFuture = widget.projectService.getProjectsByUser(widget.currentUser.id);
    _recentTasksFuture = widget.firebaseService.getTasksCreatedByUser(widget.currentUser.id);
    _taskStatsFuture = widget.firebaseService.getCreatedTaskStats(widget.currentUser.id);

    _recentTasksFuture.then((tasks) {
      debugPrint('Tâches créées par ${widget.currentUser.id}: ${tasks.map((t) => t.title).toList()}');
    });
  });
}

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          currentUser: widget.currentUser,
          firebaseService: widget.firebaseService,
        ),
      ),
    );
  }

  void _navigateToSendNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminNotificationScreen(
          currentUser: widget.currentUser,
          firebaseService: widget.firebaseService,
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text('Statut: ${_statusText(task.status)}'),
              if (task.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Échéance: ${_formatDate(task.dueDate!)}'),
                ),
              const SizedBox(height: 16),
              Text('Priorité: ${_priorityText(task.priority)}'),
              if (task.projectId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: FutureBuilder<String>(
                    future: _getProjectName(task.projectId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Projet: Chargement...');
                      }
                      return Text('Projet: ${snapshot.data ?? 'Inconnu'}');
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (task.status != TaskStatus.completed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markTaskAsCompleted(task);
              },
              child: const Text('Marquer comme terminé'),
            ),
        ],
      ),
    );
  }

  Future<String> _getProjectName(String projectId) async {
    try {
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();
      return projectDoc.data()?['name'] ?? 'Projet inconnu';
    } catch (e) {
      return 'Erreur de chargement';
    }
  }

  void _markTaskAsCompleted(TaskModel task) async {
    try {
      final updatedTask = task.copyWith(status: TaskStatus.completed);
      await widget.firebaseService.updateTask(updatedTask);
      
      // Envoyer une notification au créateur de la tâche
      if (task.createdBy != widget.currentUser.id) {
        await widget.firebaseService.notifyTaskCompleted(
          taskId: task.id,
          taskTitle: task.title,
          completerId: widget.currentUser.id,
          projectOwnerId: task.createdBy,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tâche "${task.title}" marquée comme terminée'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData(); // Recharger les données
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _statusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'À faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.completed:
        return 'Terminé';
      case TaskStatus.overdue:
        return 'En retard';
    }
  }

  String _priorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Faible';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Élevée';
    }
  }

  void _handleRefresh() async {
    await HapticFeedback.mediumImpact();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // NOUVEAU BOUTON : Envoyer des notifications
          IconButton(
            icon: const Icon(Icons.notification_add),
            onPressed: _navigateToSendNotification,
            tooltip: 'Envoyer une notification',
          ),
          
          // Badge de notifications (existant)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _navigateToNotifications,
                tooltip: 'Notifications',
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          // Bouton actualiser (existant)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Actualiser',
          ),
          
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres à implémenter')),
                );
              } else if (value == 'help') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aide à implémenter')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help, size: 20),
                    SizedBox(width: 8),
                    Text('Aide'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          _projectStatsFuture,
          _taskStatsFuture,
          _projectsFuture,
          _recentTasksFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des données...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final projectStats = snapshot.data![0] as Map<String, dynamic>;
          final taskStats = snapshot.data![1] as Map<String, dynamic>;
          final projects = snapshot.data![2] as List<ProjectModel>;
          final recentTasks = snapshot.data![3] as List<TaskModel>;

          return RefreshIndicator(
            onRefresh: () async {
              _handleRefresh();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de bienvenue
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Bonjour, ${widget.currentUser.displayName} 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                    ),
                  ),

                  // Statistiques
                  DashboardStats(
                    currentUser: widget.currentUser,
                    projectStats: projectStats,
                    taskStats: taskStats,
                  ),
                  const SizedBox(height: 24),

                  // Actions rapides
                  QuickActions(
                    currentUser: widget.currentUser,
                    projectService: widget.projectService,
                    firebaseService: widget.firebaseService,
                    onProjectCreated: _loadData,
                    onTaskCreated: _loadData,
                  ),
                  const SizedBox(height: 24),

                  // Projets récents
                  if (projects.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes Projets',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: projects.take(5).length,
                            itemBuilder: (context, index) {
                              final project = projects[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      project.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    LinearProgressIndicator(
                                      value: project.progress / 100,
                                      backgroundColor: Colors.blue.shade100,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Tâches récentes
                  RecentTasks(
                    currentUser: widget.currentUser,
                    tasks: recentTasks,
                    onEdit: (task) => _showTaskDetails(context, task),
                    onDelete: (task) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer la tâche'),
                          content: Text('Êtes-vous sûr de vouloir supprimer "${task.title}" ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await widget.firebaseService.deleteTask(task.id);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Tâche "${task.title}" supprimée'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadData();
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onAssign: (task) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Assigner ${task.title}')),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Créer une nouvelle tâche')),
          );
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
    Future<void> assignTaskToPrestataire(String taskId, String taskTitle, String prestataireId) async {
    try {
      // 1. Assigner la tâche dans Firestore
      await widget.firebaseService.assignTask(taskId, [prestataireId]);
      
      // 2. Envoyer une notification
      await widget.firebaseService.sendNotificationToPrestataire(
        prestataireId: prestataireId,
        title: '📋 Nouvelle tâche assignée',
        message: 'Vous avez été assigné à la tâche "$taskTitle"',
        adminId: widget.currentUser.id,
        data: {
          'taskId': taskId,
          'taskTitle': taskTitle,
          'type': 'task_assignment'
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tâche assignée et notification envoyée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
    Future<void> addPrestataireToProject(String projectId, String projectName, String prestataireId) async {
    try {
      // Ajouter le prestataire au projet dans Firestore
      await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
        'members': FieldValue.arrayUnion([prestataireId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Envoyer une notification
      await widget.firebaseService.sendNotificationToPrestataire(
        prestataireId: prestataireId,
        title: '🏗️ Nouveau projet',
        message: 'Vous avez été ajouté au projet "$projectName"',
        adminId: widget.currentUser.id,
        data: {
          'projectId': projectId,
          'projectName': projectName,
          'type': 'project_addition'
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prestataire ajouté au projet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
  Future<void> sendUrgentNotification(String prestataireId, String message) async {
    try {
      await widget.firebaseService.sendNotificationToPrestataire(
        prestataireId: prestataireId,
        title: '🚨 Intervention urgente',
        message: message,
        adminId: widget.currentUser.id,
        data: {
          'type': 'urgent',
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification urgente envoyée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> sendInfoNotification(String prestataireId, String title, String message) async {
    try {
      await widget.firebaseService.sendNotificationToPrestataire(
        prestataireId: prestataireId,
        title: '📢 $title',
        message: message,
        adminId: widget.currentUser.id,
        data: {
          'type': 'information',
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification d\'information envoyée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> sendReminderNotification(String prestataireId, String message) async {
    try {
      await widget.firebaseService.sendNotificationToPrestataire(
        prestataireId: prestataireId,
        title: '⏰ Rappel',
        message: message,
        adminId: widget.currentUser.id,
        data: {
          'type': 'reminder',
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rappel envoyé')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  // Méthode générique pour envoyer n'importe quel type de notification
  Future<void> sendCustomNotification(
    String prestataireId, 
    String title, 
    String message, 
    String type,
    Map<String, dynamic>? additionalData,
  ) async {
    try {
      Map<String, dynamic> data = {
        'type': type,
        'timestamp': DateTime.now().toString(),
      };
      
      if (additionalData != null) {
        data.addAll(additionalData);
      }

      await widget.firebaseService.sendNotificationToPrestataire(
        prestataireId: prestataireId,
        title: title,
        message: message,
        adminId: widget.currentUser.id,
        data: data,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification envoyée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

}