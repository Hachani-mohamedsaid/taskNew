import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/project_service.dart';
import 'task_card.dart';

class Task extends StatefulWidget {
  final UserModel currentUser;
  final List<UserModel> usersList; // Liste globale des utilisateurs
  final ProjectService projectService;
  final FirebaseService firebaseService;

  const Task({
    super.key,
    required this.currentUser,
    required this.projectService,
    required this.usersList,
    required this.firebaseService,
  });

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  List<UserModel> usersList = [];
  List<TaskModel> tasks = [];
  bool isLoading = true;

  String? selectedStatus;
  String? selectedPriority;
  String? selectedMember;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadProjects(); // ✅ Charger les projets en cache
    _loadTasks();
  }

  Future<void> _loadUsers() async {
    final fetchedUsers = await widget.firebaseService.getAllUsers();
    setState(() {
      usersList = fetchedUsers;
    });

    debugPrint("✅ Utilisateurs chargés : ${usersList.map((u) => u.displayName).toList()}");
  }

  Future<void> _loadProjects() async {
    try {
      await widget.projectService.loadProjects(); // ⚡️ méthode qui charge tous les projets en mémoire
      debugPrint("✅ Projets chargés en cache");
    } catch (e) {
      debugPrint("❌ Erreur chargement projets: $e");
    }
  }

  Future<void> _loadTasks() async {
    try {
      final userTasks =
          await widget.firebaseService.getTasksCreatedByUser(widget.currentUser.id);
      setState(() {
        tasks = userTasks;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement tâches: $e');
      setState(() => isLoading = false);
    }
  }

  Future<List<UserModel>> _loadProjectMembers(String projectId) async {
    final project = widget.projectService.getCachedProjectById(projectId);
    if (project == null) return [];
    final List<UserModel> members = [];
    for (final userId in project.assignedUsers) {
      final user = await widget.firebaseService.getUserModel(userId);
      if (user != null) members.add(user);
    }
    return members;
  }

  // 🔹 FILTRE
  void _showFilterSheet() {
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
              Text('Filtres',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text('Statut', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: ['À faire', 'En cours', 'Terminé', 'Archivé']
                    .map((status) => ChoiceChip(
                          label: Text(status),
                          selected: selectedStatus == status,
                          onSelected: (val) {
                            setState(() => selectedStatus = val ? status : null);
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text('Priorité', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: ['Faible', 'Moyenne', 'Élevée']
                    .map((prio) => ChoiceChip(
                          label: Text(prio),
                          selected: selectedPriority == prio,
                          onSelected: (val) {
                            setState(() => selectedPriority = val ? prio : null);
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text('Membre assigné',
                  style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: widget.usersList
                    .map((user) => ChoiceChip(
                          label: Text(user.displayName),
                          selected: selectedMember == user.id,
                          onSelected: (val) {
                            setState(
                                () => selectedMember = val ? user.id : null);
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      selectedStatus = null;
                      selectedPriority = null;
                      selectedMember = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 CRÉER TÂCHE
  void _showCreateTaskDialog() {
    String taskTitle = '';
    String taskDesc = '';
    String? selectedProjectId;
    String? assignedMember;
    TaskStatus selectedStatus = TaskStatus.todo;
    TaskPriority selectedPriority = TaskPriority.medium;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          List<UserModel> filteredUsers = [];
          if (selectedProjectId != null) {
            final project =
                widget.projectService.getCachedProjectById(selectedProjectId!);
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
                  TextField(
                    decoration: const InputDecoration(labelText: 'Titre'),
                    onChanged: (v) => taskTitle = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    onChanged: (v) => taskDesc = v,
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<ProjectModel>>(
                    future: widget.projectService
                        .getProjectsCreatedBy(widget.currentUser.email),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final projects = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Projet'),
                        value: selectedProjectId,
                        items: projects
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedProjectId = val;
                            assignedMember = null;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Assigner à',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (selectedProjectId != null)
                    ...filteredUsers.map(
                      (u) => RadioListTile<String>(
                        value: u.id,
                        groupValue: assignedMember,
                        title: Text(u.displayName),
                        onChanged: (val) {
                          setStateDialog(() => assignedMember = val);
                        },
                      ),
                    )
                  else
                    const Text(
                        'Sélectionnez un projet pour voir les membres'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    decoration:
                        const InputDecoration(labelText: 'Priorité'),
                    value: selectedPriority,
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() => selectedPriority = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
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
                          if (picked != null) {
                            setStateDialog(() => dueDate = picked);
                          }
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
                  child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  if (taskTitle.isEmpty ||
                      selectedProjectId == null ||
                      assignedMember == null) return;

                  final newTask = TaskModel(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    title: taskTitle,
                    description: taskDesc,
                    projectId: selectedProjectId!,
                    assignedTo: [assignedMember!],
                    status: selectedStatus,
                    priority: selectedPriority,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    createdBy: widget.currentUser.id,
                    subTasks: [],
                  );

                  await widget.firebaseService.createTaskModel(newTask);
                  setState(() => tasks.add(newTask));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Tâche "${newTask.title}" créée !')),
                  );
                },
                child: const Text('Créer'),
              ),
            ],
          );
        });
      },
    );
  }

  // 🔹 MODIFIER TÂCHE
void _showUpdateTaskDialog(TaskModel task, ProjectModel project) {
  final titleController = TextEditingController(text: task.title);
  final descriptionController = TextEditingController(text: task.description);

  TaskPriority selectedPriority = task.priority;
  TaskStatus selectedStatus = task.status;
  DateTime? selectedDueDate = task.dueDate;

  // ✅ Liste des membres du projet
  List<String> projectMembers = project.members; 

  // ✅ Membres déjà assignés à la tâche
  List<String> selectedMembers = List.from(task.assignedTo);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Modifier la tâche"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Champ titre
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "Titre"),
                  ),

                  // Champ description
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: "Description"),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Liste des membres du projet avec ceux de la tâche déjà cochés
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Assigner aux membres :", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...projectMembers.map((member) {
                    return CheckboxListTile(
                      title: Text(member),
                      value: selectedMembers.contains(member), // déjà sélectionné ?
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            selectedMembers.add(member);
                          } else {
                            selectedMembers.remove(member);
                          }
                        });
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Statut
                  DropdownButton<TaskStatus>(
                    value: selectedStatus,
                    onChanged: (value) {
                      setState(() => selectedStatus = value!);
                    },
                    items: TaskStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      );
                    }).toList(),
                  ),

                  // Priorité
                  DropdownButton<TaskPriority>(
                    value: selectedPriority,
                    onChanged: (value) {
                      setState(() => selectedPriority = value!);
                    },
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.toString().split('.').last),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Mettre à jour"),
            onPressed: () {
              // ✅ Sauvegarde avec les membres mis à jour
              final updatedTask = task.copyWith(
                title: titleController.text,
                description: descriptionController.text,
                priority: selectedPriority,
                status: selectedStatus,
                dueDate: selectedDueDate,
                assignedTo: selectedMembers,
              );
              Navigator.pop(context, updatedTask);
            },
          ),
        ],
      );
    },
  );
}


  // 🔹 SUPPRIMER TÂCHE
  void _showDeleteTaskDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la tâche'),
          content: Text('Voulez-vous vraiment supprimer la tâche "${task.title}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await widget.firebaseService.deleteTask(task.id);
                  setState(() {
                    tasks.removeWhere((t) => t.id == task.id);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Tâche supprimée !')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Erreur delete: $e')),
                  );
                }
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

@override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.role == UserRole.admin;

    List<TaskModel> filteredTasks = tasks.where((t) {
      bool statusOk = selectedStatus == null ||
          (selectedStatus == 'À faire' && t.status == TaskStatus.todo) ||
          (selectedStatus == 'En cours' && t.status == TaskStatus.inProgress) ||
          (selectedStatus == 'Terminé' && t.status == TaskStatus.completed) ||
          (selectedStatus == 'Archivé' && t.status == TaskStatus.archived);
      bool prioOk = selectedPriority == null ||
          (selectedPriority == 'Faible' && t.priority == TaskPriority.low) ||
          (selectedPriority == 'Moyenne' && t.priority == TaskPriority.medium) ||
          (selectedPriority == 'Élevée' && t.priority == TaskPriority.high);
      bool memberOk =
          selectedMember == null || t.assignedTo.contains(selectedMember);
      return statusOk && prioOk && memberOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tâches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtres',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredTasks.isEmpty
              ? const Center(child: Text('Aucune tâche trouvée.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];

                    // ✅ Membres assignés à la tâche
                    final taskMembers = usersList
                        .where((u) => task.assignedTo.contains(u.id))
                        .map((u) => u.displayName)
                        .toList();
                    debugPrint("👥 Membres de la tâche '${task.title}' : $taskMembers");

                    // ✅ Récupérer le projet lié à la tâche
                    final project = widget.projectService.getCachedProjectById(task.projectId);
                    if (project != null) {
                      final projectMembers = usersList
                          .where((u) => project.assignedUsers.contains(u.id))
                          .map((u) => u.displayName)
                          .toList();

                      debugPrint("📌 Projet: ${project.name}");
                      debugPrint("👥 Membres du projet: $projectMembers");
                    } else {
                      debugPrint("⚠️ Projet introuvable pour la tâche '${task.title}'");
                    }

                    return TaskCard(
                      task: task,
                      currentUser: widget.currentUser,
                      isAdmin: isAdmin,
                      onEdit: () {
                    if (project != null) {
                      _showUpdateTaskDialog(task, project);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Projet introuvable pour cette tâche !")),
                      );
                    }
                  },

                      onDelete: () => _showDeleteTaskDialog(task),
                    );
                  },
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showCreateTaskDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

