import 'package:flutter/material.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/user_model.dart';

class CalendarView extends StatelessWidget {
  final UserModel currentUser;
  const CalendarView({super.key, required this.currentUser});

  void _showTasksForDay(BuildContext context, int day, List<TaskModel> tasks) {
    final dayTasks = tasks.where((t) => t.dueDate?.day == day).toList();
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
              Text('Tâches du $day',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              if (dayTasks.isEmpty)
                const Text('Aucune tâche pour ce jour.',
                    style: TextStyle(color: Colors.grey)),
              ...dayTasks.map((task) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Icon(Icons.task_alt, color: Colors.blue[700]),
                      title: Text(task.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(task.description,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(task.status.toString().split('.').last,
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = TaskModel.demoTasks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mois précédent')),
                  );
                },
              ),
              Expanded(
                child: Text(
                  'Décembre 2024',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mois suivant')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grille du calendrier
          _CalendarGrid(
              tasks: tasks,
              onDayTap: (day) => _showTasksForDay(context, day, tasks)),

          const SizedBox(height: 24),

          // Légende
          const _CalendarLegend(),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<TaskModel> tasks;
  final void Function(int day) onDayTap;

  const _CalendarGrid({required this.tasks, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-têtes des jours
        Row(
          children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
              .map((day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),

        // Grille des jours
        ...List.generate(
            5,
            (weekIndex) => _CalendarWeek(
                  weekIndex: weekIndex,
                  tasks: tasks,
                  onDayTap: onDayTap,
                )),
      ],
    );
  }
}

class _CalendarWeek extends StatelessWidget {
  final int weekIndex;
  final List<TaskModel> tasks;
  final void Function(int day) onDayTap;

  const _CalendarWeek({
    required this.weekIndex,
    required this.tasks,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (dayIndex) {
        final dayNumber = weekIndex * 7 + dayIndex + 1;
        final dayTasks =
            tasks.where((task) => task.dueDate?.day == dayNumber).toList();

        return Expanded(
          child: GestureDetector(
            onTap: () => onDayTap(dayNumber),
            child: _CalendarDay(
              dayNumber: dayNumber,
              tasks: dayTasks,
              isToday: dayNumber == DateTime.now().day,
            ),
          ),
        );
      }),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int dayNumber;
  final List<TaskModel> tasks;
  final bool isToday;

  const _CalendarDay({
    required this.dayNumber,
    required this.tasks,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        color: isToday ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      ),
      child: Stack(
        children: [
          // Numéro du jour
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              dayNumber.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),

          // Indicateurs de tâches
          if (tasks.isNotEmpty) ...[
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Column(
                children: tasks
                    .take(2)
                    .map((task) => Container(
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: BoxDecoration(
                            color: _getTaskColor(task),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTaskColor(TaskModel task) {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Légende',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _LegendItem(
              color: Colors.red,
              label: 'Priorité élevée',
            ),
            SizedBox(width: 16),
            _LegendItem(
              color: Colors.orange,
              label: 'Priorité moyenne',
            ),
            SizedBox(width: 16),
            _LegendItem(
              color: Colors.green,
              label: 'Priorité faible',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
