import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/services/firebase_service.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_tasks.dart';
import '../widgets/project_list_fixed.dart';

class DashboardHomeScreen extends StatefulWidget {
  final UserModel currentUser;

  const DashboardHomeScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<ProjectModel>> _projectsFuture;
  late Future<List<Map<String, dynamic>>> _recentTasksFuture;
  final FirebaseService _firebaseService = FirebaseService();

  // Simule une liste d'utilisateurs (remplace par ta vraie source)
  final List<Map<String, String>> allUsers = [
     {'id': 'ICqykiPlV5f6hUFMuYXy21u3N2G3', 'displayName': 'hachanimohamedsaid'},
    {'id': 'WpZ7mwVzd9QjJEAbKjWa74leSeE3', 'displayName': 'ddd ddd'},
    
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _statsFuture = _firebaseService.getProjectStats(widget.currentUser.id);
      _projectsFuture = _firebaseService.getUserProjects(widget.currentUser.id);
      _recentTasksFuture =
          _firebaseService.getRecentTasks(widget.currentUser.id);
    });
  }

  Future<void> _handleRefresh() async {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: FutureBuilder(
        future:
            Future.wait([_statsFuture, _projectsFuture, _recentTasksFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Erreur de chargement des données'),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data![0] as Map<String, dynamic>;
          final projects = snapshot.data![1] as List<ProjectModel>;
          final recentTasks = snapshot.data![2] as List<Map<String, dynamic>>;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
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
                    onCreateProject: () => _createProject(context),
                    onCreateTask: () => _createTask(context, projects),
                  ),
                  const SizedBox(height: 24),
                  RecentTasks(
                    currentUser: widget.currentUser,
                    tasks: recentTasks,
                    onTaskTap: (task) => _showTaskDetails(context, task),
                  ),
                  const SizedBox(height: 24),
                  ProjectListFixed(
                    currentUser: widget.currentUser,
                    projects: projects,
                    onProjectTap: (project) =>
                        _showProjectDetails(context, project),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Fonctionnalité notifications à implémenter')),
    );
  }

  Future<void> _createProject(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => _CreateProjectDialog(
        allUsers: allUsers,
        currentUserId: widget.currentUser.id,
      ),
    );

    debugPrint('Résultat du formulaire projet: $result');

    if (result != null && result is Map<String, dynamic>) {
      try {
        if (result['members'] == null ||
            !(result['members'] is List) ||
            (result['members'] as List).isEmpty) {
          debugPrint('Erreur: Aucun membre sélectionné');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Veuillez sélectionner au moins un membre')),
          );
          return;
        }
        debugPrint('Tentative de création de projet avec: $result');
        await _firebaseService.createProject(
          name: result['name'],
          description: result['description'],
          ownerId: widget.currentUser.id,
          members: List<String>.from(result['members']),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projet créé avec succès')),
        );
        _loadData();
      } catch (e, stack) {
        debugPrint('Erreur lors de la création du projet: $e\n$stack');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Firestore: ${e.toString()}')),
        );
      }
    } else {
      debugPrint('Formulaire annulé ou résultat invalide: $result');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulaire annulé ou résultat invalide')),
      );
    }
  }

  Future<void> _createTask(
      BuildContext context, List<ProjectModel> projects) async {
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun projet disponible. Créez d\'abord un projet.'),
        ),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (context) => _CreateTaskDialog(projects: projects),
    );

    if (result != null && result is Map<String, dynamic>) {
      try {
        if (result['projectId'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner un projet')),
          );
          return;
        }
        await _firebaseService.createTask(
          projectId: result['projectId'],
          title: result['title'],
          description: result['description'],
          assignedTo: widget.currentUser.id,
          dueDate: result['dueDate'],
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tâche créée avec succès')),
        );
        _loadData();
      } catch (e) {
        debugPrint('Erreur lors de la création de la tâche: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['description']),
            const SizedBox(height: 16),
            Text('Statut: ${task['isCompleted'] ? 'Terminée' : 'En cours'}'),
            if (task['dueDate'] != null)
              Text('Échéance: ${task['dueDate'].toString()}'),
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

  void _showProjectDetails(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(project.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.description),
            const SizedBox(height: 16),
            Text('Statut: ${project.status.toString().split('.').last}'),
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
}

// --- DIALOG POUR CREER UN PROJET AVEC SELECTION DES MEMBRES ---
class _CreateProjectDialog extends StatefulWidget {
  final List<Map<String, String>> allUsers;
  final String currentUserId;

  const _CreateProjectDialog({
    Key? key,
    required this.allUsers,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late Set<String> selectedUserIds;

  @override
  void initState() {
    super.initState();
    // Par défaut, le créateur est membre
    selectedUserIds = {widget.currentUserId};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un nouveau projet'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du projet'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Membres',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...widget.allUsers.map((user) => CheckboxListTile(
                    title: Text(user['name']!),
                    value: selectedUserIds.contains(user['id']),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedUserIds.add(user['id']!);
                        } else {
                          // On ne peut pas retirer le créateur du projet
                          if (user['id'] != widget.currentUserId) {
                            selectedUserIds.remove(user['id']!);
                          }
                        }
                      });
                    },
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              debugPrint(
                  'Formulaire valide, membres sélectionnés: $selectedUserIds');
              if (selectedUserIds.isEmpty) {
                debugPrint('Erreur: Aucun membre sélectionné');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Veuillez sélectionner au moins un membre')),
                );
                return;
              }
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text,
                'members': selectedUserIds.toList(),
              });
            } else {
              debugPrint('Formulaire invalide');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Veuillez remplir tous les champs obligatoires')),
              );
            }
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

// --- DIALOG POUR CREER UNE TACHE ---
class _CreateTaskDialog extends StatefulWidget {
  final List<ProjectModel> projects;

  const _CreateTaskDialog({Key? key, required this.projects}) : super(key: key);

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ProjectModel? _selectedProject;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle tâche'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProjectModel>(
              value: _selectedProject,
              items: widget.projects
                  .map((project) => DropdownMenuItem(
                        value: project,
                        child: Text(project.name),
                      ))
                  .toList(),
              onChanged: (project) =>
                  setState(() => _selectedProject = project),
              decoration: const InputDecoration(labelText: 'Projet'),
              validator: (value) =>
                  value == null ? 'Sélectionnez un projet' : null,
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ obligatoire' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Date d\'échéance:'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _dueDate = date);
                    }
                  },
                  child: Text(
                    _dueDate == null
                        ? 'Sélectionner'
                        : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (_selectedProject == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez sélectionner un projet')),
                );
                return;
              }
              Navigator.pop(context, {
                'projectId': _selectedProject!.id,
                'title': _titleController.text,
                'description': _descriptionController.text,
                'dueDate': _dueDate,
              });
            }
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
