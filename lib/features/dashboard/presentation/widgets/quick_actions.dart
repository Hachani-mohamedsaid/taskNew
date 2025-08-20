import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';

class QuickActions extends StatefulWidget {
  final UserModel currentUser;
  const QuickActions({super.key, required this.currentUser, required Future<void> Function() onCreateProject, required Future<void> Function() onCreateTask});

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  // Mock pour la démo
  List<String> projects = ['Application Mobile', 'Site Web E-commerce'];
  List<String> users = ['Admin Principal', 'John Doe', 'Jane Smith'];
  List<String> notifications = [];

  void _showCreateProjectDialog() {
    String projectName = '';
    String projectDesc = '';
    List<String> selectedMembers = [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Créer un nouveau projet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Nom du projet'),
                  onChanged: (v) => projectName = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (v) => projectDesc = v,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Membres',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...users.map((u) => CheckboxListTile(
                      value: selectedMembers.contains(u),
                      title: Text(u),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedMembers.add(u);
                          } else {
                            selectedMembers.remove(u);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  projects.add(projectName);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Projet "$projectName" créé !')),
                );
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  void _showManageUsersDialog() {
    List<String> projectMembers = List.from(users.take(2));
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Gérer les membres du projet'),
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
                      const SnackBar(content: Text('Membres mis à jour !')),
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

  void _showNotificationDialog() {
    String notif = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Envoyer une notification'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Message'),
            onChanged: (v) => notif = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  notifications.add(notif);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification envoyée : $notif')),
                );
              },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  void _showMaintenanceSheet() {
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
              Text('Maintenance',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: const Text('Désactiver un membre'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membre désactivé (mock)')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.orange),
                  title: const Text('Supprimer une tâche'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tâche supprimée (mock)')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.archive, color: Colors.blue),
                  title: const Text('Archiver un projet'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projet archivé (mock)')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.role == UserRole.admin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Nouvelle tâche',
                icon: Icons.add_task,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nouvelle tâche')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Nouveau projet',
                icon: Icons.create_new_folder,
                onTap: isAdmin
                    ? _showCreateProjectDialog
                    : () {}, // désactive si non admin
              ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Gestion utilisateurs',
                  icon: Icons.group,
                  onTap: _showManageUsersDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Notifications',
                  icon: Icons.notifications_active,
                  onTap: _showNotificationDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Maintenance',
                  icon: Icons.build,
                  onTap: _showMaintenanceSheet,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
