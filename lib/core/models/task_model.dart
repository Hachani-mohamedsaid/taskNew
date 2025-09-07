import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  todo,       // À faire
  inProgress, // En cours
  completed,  // Terminée
  overdue,    // En retard
}
enum TaskPriority { low, medium, high }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String projectId;
  final List<String> assignedTo;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final List<String> attachments;
  final List<SubTask> subTasks;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.projectId,
    required this.assignedTo,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.attachments = const [],
    this.subTasks = const [],
  });

  /// 🔹 Nouveau constructeur depuis Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      projectId: data['projectId'] ?? '',
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      status: TaskStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (data['status'] ?? 'todo').toLowerCase(),
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name.toLowerCase() == (data['priority'] ?? 'medium').toLowerCase(),
        orElse: () => TaskPriority.medium,
      ),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      subTasks: (data['subTasks'] as List<dynamic>?)
              ?.map((st) => SubTask.fromMap(st))
              .toList() ??
          [],
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? projectId,
    List<String>? assignedTo,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? attachments,
    List<SubTask>? subTasks,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      attachments: attachments ?? this.attachments,
      subTasks: subTasks ?? this.subTasks,
    );
  }
}

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 🔹 Factory pour reconstruire une SubTask depuis Firestore
  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
