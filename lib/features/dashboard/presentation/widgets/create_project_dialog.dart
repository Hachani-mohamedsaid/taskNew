import 'package:flutter/material.dart';
import 'package:collaborative_task_manager/core/models/project_model.dart';
import 'package:collaborative_task_manager/core/models/ProjectStatus.dart';
import 'package:collaborative_task_manager/core/models/user_model.dart';

class CreateProjectDialog extends StatefulWidget {
  final UserModel currentUser;

  const CreateProjectDialog({super.key, required this.currentUser});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _priority = "medium";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Créer un projet"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nom du projet"),
              validator: (value) =>
                  value == null || value.isEmpty ? "Champ obligatoire" : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              validator: (value) =>
                  value == null || value.isEmpty ? "Champ obligatoire" : null,
            ),
            DropdownButtonFormField<String>(
              value: _priority,
              items: const [
                DropdownMenuItem(value: "low", child: Text("Basse")),
                DropdownMenuItem(value: "medium", child: Text("Moyenne")),
                DropdownMenuItem(value: "high", child: Text("Haute")),
              ],
              onChanged: (val) => setState(() => _priority = val ?? "medium"),
              decoration: const InputDecoration(labelText: "Priorité"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Annuler"),
          onPressed: () => Navigator.pop(context, null),
        ),
        ElevatedButton(
          child: const Text("Créer"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final now = DateTime.now();
              final project = ProjectModel(
                id: "",
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                status: ProjectStatus.active,
                startDate: now,
                endDate: null,
                createdBy: widget.currentUser.id,
                assignedUsers: [],
                progress: 0,
                priority: _priority,
                createdAt: now,
                updatedAt: now,
                members: [widget.currentUser.id],
                ownerId: widget.currentUser.id,
              );
              Navigator.pop(context, project);
            }
          },
        ),
      ],
    );
  }
}
