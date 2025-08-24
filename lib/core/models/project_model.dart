import 'package:cloud_firestore/cloud_firestore.dart';
      import 'package:collaborative_task_manager/core/models/ProjectStatus.dart';

      class ProjectModel {
        final String id;
        final String name;
        final String description;
        final ProjectStatus status;
        final DateTime startDate;
        final DateTime? endDate;
        final String createdBy;
        final List<String> assignedUsers;
        final int progress;
        final String priority;
        final DateTime createdAt;
        final DateTime updatedAt;
        final List<String> members;
        final String? ownerId;

        ProjectModel({
          required this.id,
          required this.name,
          required this.description,
          required this.status,
          required this.startDate,
          this.endDate,
          required this.createdBy,
          required this.assignedUsers,
          required this.progress,
          required this.priority,
          required this.createdAt,
          required this.updatedAt,
          required this.members,
          this.ownerId,
        });

        factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ProjectModel(
            id: doc.id,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            status: _parseProjectStatus(data['status']),
            startDate: (data['startDate'] as Timestamp).toDate(),
            endDate: data['endDate'] != null
                ? (data['endDate'] as Timestamp).toDate()
                : null,
            createdBy: data['createdBy'] ?? '',
            assignedUsers: List<String>.from(data['assignedUsers'] ?? []),
            progress: data['progress'] ?? 0,
            priority: data['priority'] ?? 'medium',
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            updatedAt: (data['updatedAt'] as Timestamp).toDate(),
            members: List<String>.from(data['members'] ?? []),
            ownerId: data['ownerId'],
          );
        }

        Map<String, dynamic> toFirestore() {
          return {
            'name': name,
            'description': description,
            'status': status.toString().split('.').last,
            'startDate': Timestamp.fromDate(startDate),
            'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
            'createdBy': createdBy,
            'assignedUsers': assignedUsers,
            'progress': progress,
            'priority': priority,
            'createdAt': Timestamp.fromDate(createdAt),
            'updatedAt': Timestamp.fromDate(updatedAt),
            'members': members,
            if (ownerId != null) 'ownerId': ownerId,
          };
        }

        ProjectModel copyWith({
          String? id,
          String? name,
          String? description,
          ProjectStatus? status,
          DateTime? startDate,
          DateTime? endDate,
          String? createdBy,
          List<String>? assignedUsers,
          int? progress,
          String? priority,
          DateTime? createdAt,
          DateTime? updatedAt,
          List<String>? members,
          String? ownerId,
        }) {
          return ProjectModel(
            id: id ?? this.id,
            name: name ?? this.name,
            description: description ?? this.description,
            status: status ?? this.status,
            startDate: startDate ?? this.startDate,
            endDate: endDate ?? this.endDate,
            createdBy: createdBy ?? this.createdBy,
            assignedUsers: assignedUsers ?? this.assignedUsers,
            progress: progress ?? this.progress,
            priority: priority ?? this.priority,
            createdAt: createdAt ?? this.createdAt,
            updatedAt: updatedAt ?? this.updatedAt,
            members: members ?? this.members,
            ownerId: ownerId ?? this.ownerId,
          );
        }

        static List<ProjectModel> get demoProjects => [
              ProjectModel(
                id: '1',
                name: 'Développement Application Mobile',
                description: 'Création d\'une application mobile pour la gestion des tâches',
                status: ProjectStatus.active,
                startDate: DateTime.now().subtract(const Duration(days: 30)),
                endDate: DateTime.now().add(const Duration(days: 60)),
                createdBy: 'admin@demo.com',
                assignedUsers: ['john@demo.com', 'jane@demo.com'],
                progress: 65,
                priority: 'high',
                createdAt: DateTime.now().subtract(const Duration(days: 30)),
                updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
                members: ['john@demo.com', 'jane@demo.com'],
                ownerId: 'admin@demo.com',
              ),
              // Ajoutez d'autres projets de démo si nécessaire
            ];

        static ProjectStatus _parseProjectStatus(String? status) {
          switch (status?.toLowerCase()) {
            case 'completed':
              return ProjectStatus.completed;
            case 'archived':
              return ProjectStatus.archived;
            case 'onhold':
            case 'on_hold':
              return ProjectStatus.onHold;
            default:
              return ProjectStatus.active;
          }
        }
      }
