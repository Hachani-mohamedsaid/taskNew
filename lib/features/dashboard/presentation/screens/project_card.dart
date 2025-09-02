import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/ProjectStatus.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/project_service.dart';

class ProjectCard extends StatefulWidget {
  final ProjectModel project;
  final UserModel currentUser;
  final ProjectService projectService;
  final VoidCallback? onProjectUpdated;
  final FirebaseService firebaseService;

  const ProjectCard({
    super.key,
    required this.project,
    required this.currentUser,
    required this.projectService,
    required this.firebaseService,
    this.onProjectUpdated,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _progressController;
  ProjectStatus? _selectedStatus;
  String? _selectedPriority;

  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];

  List<UserModel> allUsers = [];
  List<String> selectedMemberIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController =
        TextEditingController(text: widget.project.description);
    _progressController =
        TextEditingController(text: widget.project.progress.toString());
    _selectedStatus = widget.project.status;
    _selectedPriority = widget.project.priority;
    selectedMemberIds = List.from(widget.project.members);

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.firebaseService.getAllUsers();
      if (!mounted) return; // ✅ Vérification avant setState
      setState(() {
        allUsers = users;
      });
    } catch (e) {
      // Gérer l'erreur si nécessaire
      if (!mounted) return;
      setState(() {
        allUsers = [];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _openEditDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le projet'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ProjectStatus>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: ProjectStatus.values
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.toString().split('.').last),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (!mounted) return;
                      setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priorité'),
                    items: _priorities
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                        .toList(),
                    onChanged: (val) {
                      if (!mounted) return;
                      setState(() => _selectedPriority = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Sélectionner les membres :",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: allUsers.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: allUsers.map((user) {
                              final userId = user.id.toString();
                              final isSelected = selectedMemberIds.contains(userId);

                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(user.displayName),
                                onChanged: (checked) {
                                  if (!mounted) return;
                                  setState(() {
                                    if (checked == true) {
                                      if (!selectedMemberIds.contains(userId)) {
                                        selectedMemberIds.add(userId);
                                      }
                                    } else {
                                      selectedMemberIds.remove(userId);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedMemberIds.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Membres choisis : " +
                            allUsers
                                .where((u) =>
                                    selectedMemberIds.contains(u.id.toString()))
                                .map((u) => u.displayName)
                                .join(", "),
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(onPressed: _saveProject, child: const Text('Enregistrer')),
        ],
      ),
    );
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedProject = widget.project.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      priority: _selectedPriority,
      progress: int.tryParse(_progressController.text) ?? 0,
      updatedAt: DateTime.now(),
      members: selectedMemberIds,
    );

    try {
      await widget.projectService.updateProject(updatedProject);
      if (!mounted) return; // ✅ Vérification avant setState
      widget.onProjectUpdated?.call();
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Projet mis à jour')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.folder, color: Colors.white),
        ),
        title: Text(widget.project.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(widget.project.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${widget.project.members.length} membres',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const Spacer(),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                    '${widget.project.updatedAt.day}/${widget.project.updatedAt.month}/${widget.project.updatedAt.year}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _openEditDialog();
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Action: $value')));
            }
          },
        ),
      ),
    );
  }
}

