import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firebase_service.dart';

class PrestataireNotificationScreen extends StatefulWidget {
  final UserModel currentUser;
  final FirebaseService firebaseService;

  const PrestataireNotificationScreen({
    super.key,
    required this.currentUser,
    required this.firebaseService,
  });

  @override
  State<PrestataireNotificationScreen> createState() => _PrestataireNotificationScreenState();
}

class _PrestataireNotificationScreenState extends State<PrestataireNotificationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isLoading = false;

  // Méthodes utilitaires pour le prestataire
  Future<void> reportProblem(String problemDescription) async {
    setState(() { _isLoading = true; });
    
    try {
      await widget.firebaseService.sendNotificationToAdmin(
        prestataireId: widget.currentUser.id,
        title: '🚨 Problème signalé',
        message: problemDescription,
        data: {
          'type': 'problem_report',
          'prestataire': widget.currentUser.displayName,
          'urgence': 'high',
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problème signalé aux administrateurs')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> requestAssistance() async {
    setState(() { _isLoading = true; });
    
    try {
      await widget.firebaseService.sendNotificationToAdmin(
        prestataireId: widget.currentUser.id,
        title: '🆘 Demande d\'assistance',
        message: 'J\'ai besoin d\'aide sur une tâche',
        data: {
          'type': 'assistance_request',
          'prestataire': widget.currentUser.displayName,
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande d\'assistance envoyée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> sendProgressUpdate(String taskName, String progress) async {
    setState(() { _isLoading = true; });
    
    try {
      await widget.firebaseService.sendNotificationToAdmin(
        prestataireId: widget.currentUser.id,
        title: '📊 Mise à jour d\'avancement',
        message: 'Tâche "$taskName": $progress',
        data: {
          'type': 'progress_update',
          'task': taskName,
          'prestataire': widget.currentUser.displayName,
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mise à jour envoyée aux administrateurs')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Méthode principale pour envoyer des messages personnalisés
  Future<void> _sendNotificationToAdmin() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await widget.firebaseService.sendNotificationToAdmin(
        prestataireId: widget.currentUser.id,
        title: _titleController.text,
        message: _messageController.text,
        data: {
          'type': 'prestataire_message',
          'prestataireName': widget.currentUser.displayName,
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Message envoyé aux administrateurs')),
      );

      _titleController.clear();
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacter les administrateurs'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // BOUTONS RAPIDES POUR LES NOTIFICATIONS PRÉDÉFINIES
                  const Text(
                    'Messages rapides:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => reportProblem('Je rencontre un problème technique avec une tâche'),
                        icon: const Icon(Icons.warning, size: 16),
                        label: const Text('Signaler problème'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: requestAssistance,
                        icon: const Icon(Icons.help, size: 16),
                        label: const Text('Demander aide'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => _ProgressUpdateDialog(
                            onUpdate: sendProgressUpdate,
                          ),
                        ),
                        icon: const Icon(Icons.trending_up, size: 16),
                        label: const Text('Mise à jour'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // FORMULAIRE POUR MESSAGE PERSONNALISÉ
                  const Text(
                    'Message personnalisé:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Sujet',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Problème technique, Demande d\'aide...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      hintText: 'Décrivez votre demande en détail...',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendNotificationToAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Envoyer aux administrateurs'),
                  ),
                ],
              ),
            ),
    );
  }
}

// Dialog pour la mise à jour d'avancement
class _ProgressUpdateDialog extends StatefulWidget {
  final Function(String, String) onUpdate;

  const _ProgressUpdateDialog({required this.onUpdate});

  @override
  State<_ProgressUpdateDialog> createState() => _ProgressUpdateDialogState();
}

class _ProgressUpdateDialogState extends State<_ProgressUpdateDialog> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _progressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mise à jour d\'avancement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _taskController,
            decoration: const InputDecoration(
              labelText: 'Nom de la tâche',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _progressController,
            decoration: const InputDecoration(
              labelText: 'Avancement',
              border: OutlineInputBorder(),
              hintText: 'Ex: 75%, presque terminé, bloqué...',
            ),
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
            if (_taskController.text.isNotEmpty && _progressController.text.isNotEmpty) {
              widget.onUpdate(_taskController.text, _progressController.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}