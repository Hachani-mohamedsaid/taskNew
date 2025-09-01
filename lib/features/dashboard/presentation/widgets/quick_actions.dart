import 'package:flutter/material.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/ProjectStatus.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/project_service.dart';

class QuickActions extends StatefulWidget {
  final UserModel currentUser;
  final ProjectService projectService;
  final VoidCallback onProjectCreated;
  final FirebaseService firebaseService;

  const QuickActions({
    super.key,
    required this.currentUser,
    required this.projectService,
    required this.onProjectCreated,
    required this.firebaseService,
  });

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  List<UserModel> usersList = [];
  List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    usersList = await widget.firebaseService.getAllUsers();

    // 🔹 Debug print
    debugPrint('=== Liste des utilisateurs ===');
    for (var u in usersList) {
      debugPrint('${u.id} | ${u.displayName} | ${u.email} | Role: ${u.role}');
    }
    setState(() {});
  }

void _showCreateProjectDialog() {
  String projectName = '';
  String projectDesc = '';
  List<String> selectedMembers = [];
  String selectedPriority = 'medium'; // 🔹 Priorité par défaut
  DateTime? endDate; // 🔹 Date de fin

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Créer un nouveau projet'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom
                  TextField(
                    decoration: const InputDecoration(labelText: 'Nom du projet'),
                    onChanged: (v) => projectName = v,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (v) => projectDesc = v,
                  ),
                  const SizedBox(height: 12),

                  // Membres
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Membres', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...usersList
                      .where((u) => u.id != widget.currentUser.id)
                      .map((u) => CheckboxListTile(
                            value: selectedMembers.contains(u.id),
                            title: Text(u.displayName),
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) selectedMembers.add(u.id);
                                else selectedMembers.remove(u.id);
                              });
                            },
                          )),

                  const SizedBox(height: 12),

                  // 🔹 Priorité
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Priorité'),
                    value: selectedPriority,
                    items: ['low', 'medium', 'high', 'urgent'].map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p[0].toUpperCase() + p.substring(1)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedPriority = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Date de fin
                  Row(
                    children: [
                      Text(endDate == null
                          ? 'Date de fin : Non définie'
                          : 'Date de fin : ${endDate!.day}/${endDate!.month}/${endDate!.year}'),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setStateDialog(() => endDate = picked);
                        },
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
                onPressed: () async {
                  if (projectName.isEmpty) return;

                  final newProject = ProjectModel(
                    id: '',
                    name: projectName,
                    description: projectDesc,
                    status: ProjectStatus.active,
                    startDate: DateTime.now(),
                    endDate: endDate,
                    createdBy: widget.currentUser.email,
                    assignedUsers: selectedMembers,
                    progress: 0,
                    priority: selectedPriority,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    members: selectedMembers,
                    ownerId: widget.currentUser.id,
                  );

                  await widget.projectService.createProject(newProject);
                  Navigator.pop(context);
                  widget.onProjectCreated();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Projet "$projectName" créé avec succès !')),
                  );
                },
                child: const Text('Créer'),
              ),
            ],
          );
        },
      );
    },
  );
}

  void _showManageUsersDialog() {
    List<String> projectMembers = usersList.take(2).map((u) => u.id).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Gérer les membres du projet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...usersList
                      .where((u) => u.id != widget.currentUser.id) // Exclure le membre connecté
                      .map((u) => CheckboxListTile(
                            value: projectMembers.contains(u.id),
                            title: Text(u.displayName),
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  projectMembers.add(u.id);
                                } else {
                                  projectMembers.remove(u.id);
                                }
                              });
                            },
                          )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membres mis à jour !')),
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationDialog() {
    String notif = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Envoyer une notification'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Message'),
            onChanged: (v) => notif = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  notifications.add(notif);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification envoyée : $notif')),
                );
              },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  void _showMaintenanceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Maintenance',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: const Text('Désactiver un membre'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membre désactivé (mock)')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.orange),
                  title: const Text('Supprimer une tâche'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tâche supprimée (mock)')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.archive, color: Colors.blue),
                  title: const Text('Archiver un projet'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projet archivé (mock)')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
void _showCreateTaskDialog() {
  String taskTitle = '';
  String taskDesc = '';
  String? selectedProjectId;
  String? assignedMember; // 🔹 Un seul membre
  TaskStatus selectedStatus = TaskStatus.todo;
  TaskPriority selectedPriority = TaskPriority.medium;
  DateTime? dueDate;
  List<String> attachments = [];
  List<SubTask> subTasks = [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          // 🔹 Liste filtrée des membres selon le projet sélectionné
          List<UserModel> filteredUsers = [];
          if (selectedProjectId != null) {
            final project = widget.projectService.getCachedProjectById(selectedProjectId!);
            if (project != null) {
              filteredUsers = usersList
                  .where((u) => project.assignedUsers.contains(u.id))
                  .toList();
            }
          }

          return AlertDialog(
            title: const Text('Créer une nouvelle tâche'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Titre
                  TextField(
                    decoration: const InputDecoration(labelText: 'Titre de la tâche'),
                    onChanged: (v) => taskTitle = v,
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Description
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    onChanged: (v) => taskDesc = v,
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Choix projet
                  FutureBuilder<List<ProjectModel>>(
                    future: widget.projectService.getProjectsCreatedBy(widget.currentUser.email),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final projects = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Projet'),
                        value: selectedProjectId,
                        items: projects.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        )).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedProjectId = val;
                            assignedMember = null; // 🔹 Réinitialiser le membre sélectionné
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Assignation aux membres (un seul)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Assigner à', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (selectedProjectId != null)
                    ...filteredUsers.map((u) => RadioListTile<String>(
                          value: u.id,
                          groupValue: assignedMember,
                          title: Text(u.displayName),
                          onChanged: (val) {
                            setStateDialog(() {
                              assignedMember = val;
                            });
                          },
                        ))
                  else
                    const Text('Sélectionnez un projet pour voir les membres'),

                  const SizedBox(height: 12),

                  // 🔹 Priorité
                  DropdownButtonFormField<TaskPriority>(
                    decoration: const InputDecoration(labelText: 'Priorité'),
                    value: selectedPriority,
                    items: TaskPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedPriority = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Date d’échéance
                  Row(
                    children: [
                      Text(dueDate == null
                          ? 'Échéance : Non définie'
                          : 'Échéance : ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setStateDialog(() => dueDate = picked);
                        },
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
                onPressed: () async {
                  if (taskTitle.isEmpty || selectedProjectId == null || assignedMember == null) return;

                  final newTask = TaskModel(
                    id: '',
                    title: taskTitle,
                    description: taskDesc,
                    projectId: selectedProjectId!,
                    assignedTo: [assignedMember!], // 🔹 Liste avec un seul membre
                    status: TaskStatus.todo,
                    priority: selectedPriority,
                    dueDate: dueDate,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    createdBy: widget.currentUser.id,
                    subTasks: subTasks,
                  );

                  await widget.firebaseService.createTaskModel(newTask);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tâche "$taskTitle" créée avec succès !')),
                  );
                },
                child: const Text('Créer'),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _ActionCard(
                title: 'Nouvelle tâche',
                icon: Icons.add_task,
                onTap: _showCreateTaskDialog,
              ),

            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Nouveau projet',
                icon: Icons.create_new_folder,
                onTap: isAdmin ? _showCreateProjectDialog : () {},
              ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Gestion utilisateurs',
                  icon: Icons.group,
                  onTap: _showManageUsersDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Notifications',
                  icon: Icons.notifications_active,
                  onTap: _showNotificationDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Maintenance',
                  icon: Icons.build,
                  onTap: _showMaintenanceSheet,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}