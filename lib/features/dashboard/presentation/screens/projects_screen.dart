import 'package:collaborative_task_manager/features/dashboard/presentation/screens/project_card.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/services/project_service.dart';

class ProjectsScreen extends StatelessWidget {
  final UserModel currentUser;
  final ProjectService projectService;

  const ProjectsScreen({
    super.key,
    required this.currentUser,
    required this.projectService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets'),
      ),
      body: FutureBuilder<List<ProjectModel>>(
        future: projectService.getAllProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return const Center(child: Text('Aucun projet trouvé.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ProjectCard(
                  project: project, currentUser: currentUser);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nouveau projet')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
