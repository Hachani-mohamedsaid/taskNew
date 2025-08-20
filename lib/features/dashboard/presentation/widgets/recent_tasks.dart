import 'package:flutter/material.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/user_model.dart';

class RecentTasks extends StatelessWidget {
  final UserModel currentUser;
  const RecentTasks({super.key, required this.currentUser, required List<Map<String, dynamic>> tasks, required void Function(dynamic task) onTaskTap});

  @override
  Widget build(BuildContext context) {
    final recentTasks = TaskModel.demoTasks.take(3).toList();
    final isAdmin = currentUser.role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tâches récentes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voir toutes les tâches')),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recentTasks.map(
          (task) => _RecentTaskItem(
            task: task,
            currentUser: currentUser,
            isAdmin: isAdmin,
          ),
        ),
      ],
    );
  }
}

class _RecentTaskItem extends StatelessWidget {
  final TaskModel task;
  final UserModel currentUser;
  final bool isAdmin;

  const _RecentTaskItem(
      {required this.task, required this.currentUser, required this.isAdmin});

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.archived:
        return Colors.orange;
    }
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _statusColor(task.status).withOpacity(0.15),
                child: Icon(
                  _getStatusIcon(task.status),
                  color: _statusColor(task.status),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(task.status).withOpacity(0.13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusText(task.status),
                            style: TextStyle(
                              color: _statusColor(task.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 15, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          task.dueDate != null
                              ? _formatDate(task.dueDate!)
                              : 'Pas de date',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const Spacer(),
                        Icon(Icons.priority_high,
                            size: 15, color: _getPriorityColor(task.priority)),
                        const SizedBox(width: 4),
                        Text(
                          _getPriorityText(task.priority),
                          style: TextStyle(
                              color: _getPriorityColor(task.priority),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      tooltip: 'Assigner',
                      color: Colors.blue,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Assigner la tâche'),
                            content: const Text(
                                'Sélectionnez un membre à assigner (mock).'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Tâche assignée (mock)')),
                                  );
                                },
                                child: const Text('Assigner'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Modifier',
                      color: Colors.deepPurple,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Modifier la tâche'),
                            content: const Text(
                                'Formulaire de modification (mock).'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Tâche modifiée (mock)')),
                                  );
                                },
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Supprimer',
                      color: Colors.red,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer la tâche'),
                            content: const Text(
                                'Voulez-vous vraiment supprimer cette tâche ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Tâche supprimée (mock)')),
                                  );
                                },
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_arrow;
      case TaskStatus.completed:
        return Icons.check;
      case TaskStatus.archived:
        return Icons.archive;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Faible';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Élevée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
