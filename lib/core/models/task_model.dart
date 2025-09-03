enum TaskStatus { todo, inProgress, completed, archived }

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
  final List<Comment> comments;
  final int commentsCount;

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
    this.comments = const [],
    this.commentsCount = 0,
  });

  // Données statiques pour la démo
  static List<TaskModel> get demoTasks => [
        TaskModel(
          id: '1',
          title: 'Concevoir l\'interface utilisateur',
          description:
              'Créer les maquettes et wireframes pour l\'application mobile',
          projectId: '1',
          assignedTo: ['2', '3'],
          status: TaskStatus.inProgress,
          priority: TaskPriority.high,
          dueDate: DateTime.now().add(const Duration(days: 5)),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
          createdBy: '1',
          subTasks: [
            SubTask(id: '1', title: 'Maquettes desktop', isCompleted: true),
            SubTask(id: '2', title: 'Maquettes mobile', isCompleted: false),
            SubTask(id: '3', title: 'Prototype interactif', isCompleted: false),
          ],
          comments: [
            Comment(
              id: '1',
              userId: '2',
              userName: 'John Doe',
              content: 'J\'ai terminé les maquettes desktop',
              createdAt: DateTime.now().subtract(const Duration(hours: 4)),
            ),
            Comment(
              id: '2',
              userId: '3',
              userName: 'Jane Smith',
              content: 'Je commence les maquettes mobile',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            ),
          ],
        ),
        TaskModel(
          id: '2',
          title: 'Implémenter l\'authentification',
          description: 'Développer le système de connexion et d\'inscription',
          projectId: '1',
          assignedTo: ['1'],
          status: TaskStatus.todo,
          priority: TaskPriority.high,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdBy: '1',
        ),
        TaskModel(
          id: '3',
          title: 'Créer la base de données',
          description:
              'Concevoir et implémenter la structure de la base de données',
          projectId: '2',
          assignedTo: ['2'],
          status: TaskStatus.completed,
          priority: TaskPriority.medium,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdBy: '1',
        ),
        TaskModel(
          id: '4',
          title: 'Tests unitaires',
          description:
              'Écrire les tests unitaires pour les composants principaux',
          projectId: '1',
          assignedTo: ['3'],
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          dueDate: DateTime.now().add(const Duration(days: 10)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdBy: '2',
        ),
      ];

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
    List<Comment>? comments,
    int? commentsCount,
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
      comments: comments ?? this.comments,
      commentsCount: commentsCount ?? this.commentsCount,
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
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });
}


