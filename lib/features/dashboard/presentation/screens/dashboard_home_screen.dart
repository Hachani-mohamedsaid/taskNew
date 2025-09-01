import 'package:flutter/material.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/services/project_service.dart';
import '../../../../core/services/firebase_service.dart' as core;
import '../widgets/dashboard_stats.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_tasks.dart';

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
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<ProjectModel>> _projectsFuture;
  late Future<List<TaskModel>> _recentTasksFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

void _loadData() {
  setState(() {
    _statsFuture = widget.projectService.getProjectStats();
    _projectsFuture =
        widget.projectService.getProjectsByUser(widget.currentUser.id);

   
    _recentTasksFuture =
        widget.firebaseService.getTasksCreatedByUser(widget.currentUser.id);

    _recentTasksFuture.then((tasks) {
      debugPrint('Tâches créées par ${widget.currentUser.id}: ${tasks.map((t) => t.title).toList()}');
    });
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications à implémenter')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          _statsFuture,
          _projectsFuture,
          _recentTasksFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final stats = snapshot.data![0] as Map<String, dynamic>;
          final projects = snapshot.data![1] as List<ProjectModel>;
          final recentTasks = snapshot.data![2] as List<TaskModel>;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardStats(
                    currentUser: widget.currentUser,
                    projectStats: stats,
                  ),
                  const SizedBox(height: 24),
                  QuickActions(
                    currentUser: widget.currentUser,
                    projectService: widget.projectService,
                    firebaseService: widget.firebaseService,
                    onProjectCreated: _loadData,
                  ),
                  const SizedBox(height: 24),
                  RecentTasks(
                  currentUser: widget.currentUser,
                  tasks: recentTasks,
                  onEdit: (task) => _showTaskDetails(context, task), // utilisé pour voir les détails
                  onDelete: (task) {
                    // Exemple simple : supprimer (à adapter avec ton service Firebase)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Suppression de ${task.title}')),
                    );
                  },
                  onAssign: (task) {
                    // Si tu veux gérer l’assignation
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
    );
  }

  void _showTaskDetails(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 16),
            Text('Statut: ${_statusText(task.status)}'),
            if (task.dueDate != null)
              Text('Échéance: ${task.dueDate!.day}/${task.dueDate!.month}'),
            const SizedBox(height: 16),
            Text('Priorité: ${_priorityText(task.priority)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _statusText(TaskStatus status) {
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
}
