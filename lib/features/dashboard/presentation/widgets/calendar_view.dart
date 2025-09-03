import 'package:flutter/material.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firebase_service.dart';

class CalendarView extends StatefulWidget {
  final UserModel currentUser;

  const CalendarView({super.key, required this.currentUser});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final FirebaseService _firebaseService = FirebaseService();
  List<TaskModel> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    try {
      final fetchedTasks =
          await _firebaseService.getTasksCreatedByUser(widget.currentUser.id);
      setState(() {
        tasks = fetchedTasks;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement tâches: $e');
      setState(() => isLoading = false);
    }
  }

  void _showTasksForDay(BuildContext context, int day) {
    final dayTasks = tasks
        .where((t) =>
            t.dueDate?.day == day &&
            t.dueDate?.month == DateTime.now().month &&
            t.dueDate?.year == DateTime.now().year)
        .toList();

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
              Text(
                'Tâches du $day',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              if (dayTasks.isEmpty)
                const Text('Aucune tâche pour ce jour.',
                    style: TextStyle(color: Colors.grey)),
              ...dayTasks.map((task) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading:
                          Icon(Icons.task_alt, color: Colors.blue[700]),
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();

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
                  '${_monthName(now.month)} ${now.year}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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
          _CalendarGrid(
            tasks: tasks,
            onDayTap: (day) => _showTasksForDay(context, day),
          ),
          const SizedBox(height: 24),
          const _CalendarLegend(),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}

// =======================================
// Grid du calendrier
// =======================================
class _CalendarGrid extends StatelessWidget {
  final List<TaskModel> tasks;
  final void Function(int day) onDayTap;

  const _CalendarGrid({required this.tasks, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    return Column(
      children: [
        Row(
          children: ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim']
              .map((day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(day, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ))
              .toList(),
        ),
        ...List.generate((daysInMonth / 7).ceil(), (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex + 1;
              if(dayNumber > daysInMonth) return const Expanded(child: SizedBox());

              final dayTasks = tasks.where((t) => t.dueDate?.day == dayNumber &&
                  t.dueDate?.month == now.month &&
                  t.dueDate?.year == now.year).toList();

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(dayNumber),
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Text(dayNumber.toString(),
                              style: const TextStyle(fontSize: 12)),
                        ),
                        if(dayTasks.isNotEmpty)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dayTasks.take(2).map((t) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: _getTaskColor(t),
                                  shape: BoxShape.circle,
                                ),
                              )).toList(),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
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

// =======================================
// Légende des couleurs
// =======================================
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendItem(color: Colors.red, label: 'Priorité élevée'),
        SizedBox(width: 16),
        _LegendItem(color: Colors.orange, label: 'Priorité moyenne'),
        SizedBox(width: 16),
        _LegendItem(color: Colors.green, label: 'Priorité faible'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
