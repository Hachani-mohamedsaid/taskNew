import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/services/project_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_tasks.dart';

class DashboardHomeScreen extends StatefulWidget {
  final UserModel currentUser;
  final ProjectService projectService;
  final FirebaseService firebaseService; // 🔹 Ajouter ici

  const DashboardHomeScreen({
    super.key,
    required this.currentUser,
    required this.projectService,
    required this.firebaseService, // 🔹 Obligatoire
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<ProjectModel>> _projectsFuture;
  late Future<List<Map<String, dynamic>>> _recentTasksFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _statsFuture = widget.projectService.getProjectStats();
      _projectsFuture = widget.projectService.getProjectsByUser(widget.currentUser.id);
      _recentTasksFuture = Future.value([]); // Remplacer par la vraie méthode
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
                const SnackBar(content: Text('Notifications à implémenter'))),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_statsFuture, _projectsFuture, _recentTasksFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final stats = snapshot.data![0] as Map<String, dynamic>;
          final projects = snapshot.data![1] as List<ProjectModel>;
          final recentTasks = snapshot.data![2] as List<Map<String, dynamic>>;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardStats(currentUser: widget.currentUser, projectStats: stats),
                  const SizedBox(height: 24),
                  QuickActions(
                    currentUser: widget.currentUser,
                    projectService: widget.projectService,
                    firebaseService: widget.firebaseService, // 🔹 Ajouter ici
                    onProjectCreated: _loadData,
                  ),
                  const SizedBox(height: 24),
                  RecentTasks(
                    currentUser: widget.currentUser,
                    tasks: recentTasks,
                    onTaskTap: (task) => _showTaskDetails(context, task),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['description']),
            const SizedBox(height: 16),
            Text('Statut: ${task['isCompleted'] ? 'Terminée' : 'En cours'}'),
            if (task['dueDate'] != null) Text('Échéance: ${task['dueDate']}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
