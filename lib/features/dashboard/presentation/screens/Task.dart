import 'package:collaborative_task_manager/features/dashboard/presentation/screens/task_card.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/task_model.dart';


class Task extends StatefulWidget {
  final UserModel currentUser;
  const Task({super.key, required this.currentUser});

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  List<TaskModel> tasks = List.from(TaskModel.demoTasks);
  String? selectedStatus;
  String? selectedPriority;
  String? selectedMember;

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
                            setState(
                                () => selectedStatus = val ? status : null);
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
                            setState(
                                () => selectedPriority = val ? prio : null);
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
                children: ['Admin Principal', 'John Doe', 'Jane Smith']
                    .map((member) => ChoiceChip(
                          label: Text(member),
                          selected: selectedMember == member,
                          onSelected: (val) {
                            setState(
                                () => selectedMember = val ? member : null);
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

  void _showEditTaskDialog(TaskModel task) {
    String title = task.title;
    String desc = task.description;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier la tâche'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Titre'),
                controller: TextEditingController(text: title),
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                controller: TextEditingController(text: desc),
                onChanged: (v) => desc = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final idx = tasks.indexWhere((t) => t.id == task.id);
                  if (idx != -1) {
                    tasks[idx] = TaskModel(
                      id: task.id,
                      title: title,
                      description: desc,
                      projectId: task.projectId,
                      assignedTo: task.assignedTo,
                      status: task.status,
                      priority: task.priority,
                      dueDate: task.dueDate,
                      createdAt: task.createdAt,
                      updatedAt: DateTime.now(),
                      createdBy: task.createdBy,
                    );
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tâche modifiée !')),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteTaskDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la tâche'),
          content:
              Text('Voulez-vous vraiment supprimer la tâche "${task.title}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tasks.removeWhere((t) => t.id == task.id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tâche supprimée !')),
                );
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateTaskDialog() {
    String title = '';
    String desc = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Créer une nouvelle tâche'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Titre'),
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (v) => desc = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tasks.add(TaskModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    description: desc,
                    projectId: '1',
                    assignedTo: [],
                    status: TaskStatus.todo,
                    priority: TaskPriority.low,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    createdBy: widget.currentUser.id,
                  ));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tâche créée !')),
                );
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.role == UserRole.admin;
    // Filtrage local mock
    List<TaskModel> filteredTasks = tasks.where((t) {
      bool statusOk = selectedStatus == null ||
          (selectedStatus == 'À faire' && t.status == TaskStatus.todo) ||
          (selectedStatus == 'En cours' && t.status == TaskStatus.inProgress) ||
          (selectedStatus == 'Terminé' && t.status == TaskStatus.completed) ||
          (selectedStatus == 'Archivé' && t.status == TaskStatus.archived);
      bool prioOk = selectedPriority == null ||
          (selectedPriority == 'Faible' && t.priority == TaskPriority.low) ||
          (selectedPriority == 'Moyenne' &&
              t.priority == TaskPriority.medium) ||
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return TaskCard(
            task: task,
            currentUser: widget.currentUser,
            isAdmin: isAdmin,
            onEdit: () => _showEditTaskDialog(task),
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