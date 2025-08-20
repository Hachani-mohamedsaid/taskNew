import 'package:collaborative_task_manager/features/dashboard/presentation/screens/project_card.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';


class ProjectsScreen extends StatelessWidget {
  final UserModel currentUser;
  const ProjectsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final projects = ProjectModel.demoProjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return ProjectCard(project: project, currentUser: currentUser);
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