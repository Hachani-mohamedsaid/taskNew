import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:collaborative_task_manager/core/models/project_model.dart';
import 'package:collaborative_task_manager/core/models/task_model.dart';
import 'package:collaborative_task_manager/core/models/user_model.dart';
import 'package:collaborative_task_manager/features/auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final String _imgbbApiKey =
      '05b2177b559da91f49c845e58ba5d7e9'; // Remplacez par votre clé API

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final projectCount = ProjectModel.demoProjects
        .where((p) => p.assignedUsers.contains(_currentUser.email))
        .length;
    final taskCount = TaskModel.demoTasks
        .where((t) => t.assignedTo.contains(_currentUser.id))
        .length;
    final isAdmin = _currentUser.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Section Profil
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _changeProfileImage,
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundColor: isAdmin
                                      ? Colors.blue[100]!
                                      : Colors.green[100]!,
                                  child: _currentUser.photoURL != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _currentUser.photoURL!,
                                            width: 88,
                                            height: 88,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (BuildContext context,
                                                    Widget child,
                                                    ImageChunkEvent?
                                                        loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return _buildFallbackAvatar(
                                                  _currentUser, isAdmin);
                                            },
                                          ),
                                        )
                                      : _buildFallbackAvatar(
                                          _currentUser, isAdmin),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _currentUser.displayName,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isAdmin
                                                ? Colors.blue[50]
                                                : Colors.green[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isAdmin
                                                    ? Icons.admin_panel_settings
                                                    : Icons.verified_user,
                                                size: 16,
                                                color: isAdmin
                                                    ? Colors.blue
                                                    : Colors.green,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isAdmin ? 'ADMIN' : 'MEMBRE',
                                                style: TextStyle(
                                                  color: isAdmin
                                                      ? Colors.blue
                                                      : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentUser.email,
                                      style: TextStyle(color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Section dates
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 8, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Inscrit le ${_formatDate(_currentUser.createdAt)}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 8, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dernière connexion : ${_formatDate(_currentUser.lastSeen)}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Statistiques
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatInfo(
                          label: 'Projets', value: projectCount.toString()),
                      _StatInfo(label: 'Tâches', value: taskCount.toString()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Options
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.edit, color: Colors.deepPurple),
                          title: const Text('Modifier le profil'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showEditProfileDialog(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.lock_reset,
                              color: Colors.orange),
                          title: const Text('Changer le mot de passe'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Déconnexion',
                              style: TextStyle(color: Colors.red)),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFallbackAvatar(UserModel user, bool isAdmin) {
    return Text(
      user.displayName.substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: isAdmin ? Colors.blue : Colors.green,
        fontSize: 38,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await _firestore.collection('users').doc(_currentUser.id).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentUser = UserModel(
            id: doc.id,
            email: doc['email'],
            displayName: doc['displayName'],
            photoURL: doc['photoURL'],
            role: UserRole.values.firstWhere(
              (e) => e.toString().split('.').last == doc['role'],
              orElse: () => UserRole.member,
            ),
            createdAt: (doc['createdAt'] as Timestamp).toDate(),
            lastSeen: (doc['lastSeen'] as Timestamp).toDate(),
            isActive: doc['isActive'],
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de rafraîchissement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() => _isLoading = true);

        // Upload vers ImgBB
        final imageUrl = await _uploadToImgBB(image);

        // Mettre à jour dans Firestore
        await _firestore.collection('users').doc(_currentUser.id).update({
          'photoURL': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour l'état local
        if (mounted) {
          setState(() {
            _currentUser = UserModel(
              id: _currentUser.id,
              email: _currentUser.email,
              displayName: _currentUser.displayName,
              photoURL: imageUrl,
              role: _currentUser.role,
              createdAt: _currentUser.createdAt,
              lastSeen: DateTime.now(),
              isActive: _currentUser.isActive,
            );
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadToImgBB(XFile image) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      uri,
      body: {
        'key': _imgbbApiKey,
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['data']['url']; // URL de l'image sur ImgBB
    } else {
      throw Exception('Échec de l\'upload vers ImgBB: ${response.statusCode}');
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController =
        TextEditingController(text: _currentUser.displayName);
    final emailController = TextEditingController(text: _currentUser.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez remplir tous les champs')),
                );
                return;
              }

              try {
                if (mounted) setState(() => _isLoading = true);
                Navigator.pop(context);

                if (emailController.text != _currentUser.email) {
                  await _auth.currentUser
                      ?.verifyBeforeUpdateEmail(emailController.text);
                }

                await _firestore
                    .collection('users')
                    .doc(_currentUser.id)
                    .update({
                  'displayName': nameController.text,
                  'email': emailController.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  setState(() {
                    _currentUser = UserModel(
                      id: _currentUser.id,
                      email: emailController.text,
                      displayName: nameController.text,
                      photoURL: _currentUser.photoURL,
                      role: _currentUser.role,
                      createdAt: _currentUser.createdAt,
                      lastSeen: DateTime.now(),
                      isActive: _currentUser.isActive,
                    );
                  });
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profil mis à jour avec succès')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Changer le mot de passe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Ancien mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe (min. 6 caractères)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onSubmitted: (_) async {
                // Permet de valider avec la touche entrée
                await _processPasswordChange(
                  context,
                  oldPasswordController.text,
                  newPasswordController.text,
                  confirmPasswordController.text,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _processPasswordChange(
              context,
              oldPasswordController.text,
              newPasswordController.text,
              confirmPasswordController.text,
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}
Future<void> _processPasswordChange(
  BuildContext context,
  String oldPassword,
  String newPassword,
  String confirmPassword,
) async {
  // Validation des champs
  if (newPassword != confirmPassword) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return;
  }

  if (newPassword.length < 6) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return;
  }

  try {
    if (mounted) setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    // 1. Recréer l'email et le mot de passe
    final email = user.email;
    if (email == null) {
      throw Exception('Email utilisateur non disponible');
    }

    // 2. Créer les credentials avec l'email actuel
    final credential = EmailAuthProvider.credential(
      email: email,
      password: oldPassword,
    );

    // 3. Réauthentification avec vérification d'erreur
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Le mot de passe actuel est incorrect',
        );
      }
      rethrow;
    }

    // 4. Mise à jour du mot de passe
    await user.updatePassword(newPassword);

    // 5. Mise à jour dans Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // 6. Rafraîchir les données locales
    if (mounted) {
      await _refreshProfile();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe changé avec succès'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    if (mounted) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Mot de passe actuel incorrect';
          break;
        case 'weak-password':
          errorMessage = 'Le nouveau mot de passe est trop faible';
          break;
        case 'requires-recent-login':
          errorMessage = 'Session expirée. Veuillez vous reconnecter avant de changer votre mot de passe.';
          break;
        default:
          errorMessage = 'Erreur d\'authentification: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du changement: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _signOut() async {
    try {
      setState(() => _isLoading = true);
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de déconnexion: $e')),
        );
      }
    }
  }
}

class _StatInfo extends StatelessWidget {
  final String label;
  final String value;

  const _StatInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
