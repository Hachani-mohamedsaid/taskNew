import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final UserModel currentUser;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.currentUser,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(task.status),
          child: Icon(
            _getStatusIcon(task.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.priority_high,
                  size: 16,
                  color: _getPriorityColor(task.priority),
                ),
                const SizedBox(width: 4),
                Text(
                  _getPriorityText(task.priority),
                  style: TextStyle(
                    color: _getPriorityColor(task.priority),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (task.dueDate != null) ...[
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: isAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Modifier',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                  ),
                ],
              )
            : null,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ouvrir: ${task.title}')),
          );
        },
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
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
    return '${date.day}/${date.month}/${date.year}';
  }
}