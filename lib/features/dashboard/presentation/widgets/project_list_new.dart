import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/user_model.dart';

class ProjectListNew extends StatelessWidget {
  final UserModel currentUser;
  final List<ProjectModel>? projects;

  const ProjectListNew({
    super.key,
    required this.currentUser,
    this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final projectList = projects ?? ProjectModel.demoProjects;
    final isAdmin = currentUser.role == UserRole.admin;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Projets Récents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajouter un projet')),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (projectList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun projet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Commencez par créer votre premier projet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectList.length,
                itemBuilder: (context, index) {
                  final project = projectList[index];
                  try {
                    return _buildProjectCard(context, project, isAdmin);
                  } catch (e) {
                    // Affiche une carte d'erreur si un projet pose problème
                    return Card(
                      color: Colors.red[50],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.error, color: Colors.red),
                        title: const Text('Erreur de projet'),
                        subtitle: Text(
                          'Impossible d\'afficher ce projet.\n${e.toString()}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: ${e.toString()}')),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(
      BuildContext context, ProjectModel project, bool isAdmin) {
    // Gestion du type du statut (enum ou string)
    String statusStr;
    if (project.status is String) {
      statusStr = project.status as String;
    } else {
      statusStr = project.status.toString().split('.').last;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(statusStr).withOpacity(0.1),
          child: Icon(
            Icons.folder,
            color: _getStatusColor(statusStr),
          ),
        ),
        title: Text(
          project.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              project.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(statusStr),
                const SizedBox(width: 8),
                _buildPriorityChip(project.priority),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${project.assignedUsers.length} membres',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(project.updatedAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (project.progress / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(statusStr)),
            ),
            const SizedBox(height: 4),
            Text(
              '${project.progress}% terminé',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Modifier: ${project.name}')),
                    );
                  } else if (value == 'delete') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Supprimer: ${project.name}')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ouvrir: ${project.name}')),
          );
        },
      ),
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
      case 'onHold':
        color = Colors.orange;
        label = 'En pause';
        break;
      case 'archived':
        color = Colors.grey;
        label = 'Archivé';
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
      case 'onHold':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}