// admin_notification_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firebase_service.dart';

class AdminNotificationScreen extends StatefulWidget {
  final UserModel currentUser;
  final FirebaseService firebaseService;

  const AdminNotificationScreen({
    super.key,
    required this.currentUser,
    required this.firebaseService,
  });

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedPrestataireId;
  List<UserModel> _prestataires = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrestataires();
  }

  Future<void> _loadPrestataires() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prestataires = await widget.firebaseService.getPrestataires();
      setState(() {
        _prestataires = prestataires;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _sendNotification() async {
    if (_selectedPrestataireId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un prestataire')),
      );
      return;
    }

    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.firebaseService.sendNotificationToPrestataire(
        prestataireId: _selectedPrestataireId!,
        title: _titleController.text,
        message: _messageController.text,
        adminId: widget.currentUser.id,
        data: {
          'type': 'admin_notification',
          'timestamp': DateTime.now().toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Notification envoyée avec succès')),
      );

      // Réinitialiser le formulaire
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _selectedPrestataireId = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer une notification'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _prestataires.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sélection du prestataire
                  DropdownButtonFormField<String>(
                    value: _selectedPrestataireId,
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner un prestataire',
                      border: OutlineInputBorder(),
                    ),
                    items: _prestataires.map((prestataire) {
                      return DropdownMenuItem<String>(
                        value: prestataire.id,
                        child: Text(prestataire.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPrestataireId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Titre de la notification
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la notification',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Nouvelle tâche importante',
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  
                  // Message de la notification
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Veuillez prendre en charge cette tâche urgente...',
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),
                  
                  // Bouton d'envoi
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Envoyer la notification'),
                  ),
                ],
              ),
            ),
    );
  }
}