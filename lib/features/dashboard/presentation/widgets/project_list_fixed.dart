import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/task_model.dart';

class ProjectListFixed extends StatefulWidget {
  final UserModel currentUser;
  final List<ProjectModel>? projects;

  const ProjectListFixed({
    super.key,
    required this.currentUser,
    this.projects, required void Function(dynamic project) onProjectTap,
  });

  @override
  State<ProjectListFixed> createState() => _ProjectListFixedState();
}

class _ProjectListFixedState extends State<ProjectListFixed> {
  List<String> users = ['Admin Principal', 'John Doe', 'Jane Smith'];
  List<ProjectModel> get projects =>
      widget.projects ?? ProjectModel.demoProjects;

  void _showManageMembersDialog(ProjectModel project) {
    List<String> projectMembers = List.from(project.assignedUsers);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Gérer les membres de ${project.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...users.map((u) => CheckboxListTile(
                        value: projectMembers.contains(u),
                        title: Text(u),
                        onChanged: (val) {
                          setStateDialog(() {
                            if (val == true) {
                              projectMembers.add(u);
                            } else {
                              projectMembers.remove(u);
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
                      SnackBar(
                          content: Text(
                              'Membres mis à jour pour ${project.name} !')),
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

  void _showArchiveProjectDialog(ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Archiver le projet'),
          content: Text(
              'Voulez-vous vraiment archiver le projet "${project.name}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  projects.removeWhere((p) => p.id == project.id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Projet archivé !')),
                );
              },
              child: const Text('Archiver'),
            ),
          ],
        );
      },
    );
  }

  void _showProjectDetailSheet(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
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
                  const SizedBox(height: 18),
                  Text(project.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(project.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildStatusChip(project.status as String),
                      const SizedBox(width: 8),
                      _buildPriorityChip(project.priority),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Membres (${project.assignedUsers.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: project.assignedUsers
                        .take(5)
                        .map((u) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue[100],
                                child: Text(u.substring(0, 1),
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Text('Progression',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(project.status as String)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.progress}% terminé',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (widget.currentUser.role == UserRole.admin) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showManageMembersDialog(project),
                            icon: const Icon(Icons.group),
                            label: const Text('Gérer membres'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue[900]),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showArchiveProjectDialog(project),
                            icon: const Icon(Icons.archive),
                            label: const Text('Archiver'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[50],
                                foregroundColor: Colors.orange[900]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Actif';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Terminé';
        break;
      case 'paused':
        color = Colors.orange;
        label = 'En pause';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'urgent':
        color = Colors.red;
        label = 'Urgent';
        break;
      case 'high':
        color = Colors.orange;
        label = 'Élevée';
        break;
      case 'medium':
        color = Colors.blue;
        label = 'Moyenne';
        break;
      case 'low':
        color = Colors.green;
        label = 'Faible';
        break;
      default:
        color = Colors.grey;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.role == UserRole.admin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Projets récents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voir tous les projets')),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...projects.map((project) => _ProjectItemFixed(
              project: project,
              currentUser: widget.currentUser,
              isAdmin: isAdmin,
              onManageMembers: () => _showManageMembersDialog(project),
              onArchive: () => _showArchiveProjectDialog(project),
              onOpenDetail: () => _showProjectDetailSheet(project),
            )),
      ],
    );
  }
}

class _ProjectItemFixed extends StatelessWidget {
  final ProjectModel project;
  final UserModel currentUser;
  final bool isAdmin;
  final VoidCallback onManageMembers;
  final VoidCallback onArchive;
  final VoidCallback onOpenDetail;

  const _ProjectItemFixed({
    required this.project,
    required this.currentUser,
    required this.isAdmin,
    required this.onManageMembers,
    required this.onArchive,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _getStatusColor(project.status as String),
          child: const Icon(Icons.folder, color: Colors.white, size: 20),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${project.assignedUsers.length} membres',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDate(project.updatedAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: project.progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(project.status as String)),
            ),
            const SizedBox(height: 4),
            Text(
              '${project.progress}% terminé',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onManageMembers,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Gérer'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 32)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive),
                    label: const Text('Archiver'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 32)),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: onOpenDetail,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
