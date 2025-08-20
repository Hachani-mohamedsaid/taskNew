import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel currentUser;
  const NotificationsScreen({super.key, required this.currentUser});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, String>> notifications = [
    {
      'title': 'Nouvelle fonctionnalité',
      'message': 'Essayez la nouvelle vue Kanban dans vos projets !',
      'date': '2024-06-01',
    },
    {
      'title': 'Maintenance prévue',
      'message': 'L’application sera indisponible dimanche de 2h à 4h.',
      'date': '2024-05-28',
    },
    {
      'title': 'Bienvenue',
      'message': 'Bienvenue sur Task Manager Pro !',
      'date': '2024-05-20',
    },
  ];

  void _showSendNotificationDialog() {
    String notifTitle = '';
    String notifMsg = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Envoyer une annonce'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Titre'),
                onChanged: (v) => notifTitle = v,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
                onChanged: (v) => notifMsg = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  notifications.insert(0, {
                    'title': notifTitle,
                    'message': notifMsg,
                    'date': DateTime.now().toString().substring(0, 10),
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Annonce envoyée !')),
                );
              },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Annonces'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_alert),
              tooltip: 'Envoyer une annonce',
              onPressed: _showSendNotificationDialog,
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final notif = notifications[i];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 5,
            color: i == 0 ? Colors.blue[50] : Colors.grey[50],
            child: ListTile(
              leading: Icon(Icons.notifications,
                  color: i == 0 ? Colors.blue : Colors.grey, size: 32),
              title: Text(
                notif['title'] ?? '',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notif['message'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          notif['date'] ?? '',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
