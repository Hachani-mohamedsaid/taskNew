import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/image_storage_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();
  final ImageStorageService _imageService = ImageStorageService();

  XFile? _profileImage;
  String? _selectedRole;
  bool _isLoading = false;
  bool _captchaVerified = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      _showSnackBar('Veuillez sélectionner un rôle');
      return;
    }
    if (!_captchaVerified) {
      _showSnackBar('Veuillez compléter le CAPTCHA');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      final userCredential =
          await _firebaseService.createUserWithEmailAndPassword(
        email,
        password,
      );

      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await _imageService.uploadImage(
          _profileImage!,
          userId: userCredential.user!.uid,
        );
      }

      await _firebaseService.saveUserData(
        userId: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: _selectedRole!,
        profileImageUrl: imageUrl,
      );

      if (mounted) {
        _showSnackBar('Inscription réussie !');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() => _profileImage = picked);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur de sélection d\'image: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section Photo - Version COMPLÈTEMENT ISOLÉE
                  Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImage != null
                              ? (kIsWeb
                                      ? NetworkImage(_profileImage!.path)
                                      : FileImage(File(_profileImage!.path)))
                                  as ImageProvider
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text('Changer la photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sélection de rôle
                  _buildRoleSelection(),
                  const SizedBox(height: 32),

                  // Formulaire
                  _buildFormFields(),
                  const SizedBox(height: 32),

                  // Bouton d'inscription - Version ABSOLUMENT SÉPARÉE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _registerUser();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'S\'INSCRIRE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rôle*',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildRoleChoice('Admin', Icons.admin_panel_settings)),
            const SizedBox(width: 12),
            Expanded(child: _buildRoleChoice('Provider', Icons.handyman)),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleChoice(String role, IconData icon) {
    final isSelected = _selectedRole == role.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _selectedRole = role.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    isSelected ? Colors.blue.shade700 : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              role,
              style: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'Prénom*'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Nom*'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email*'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Mot de passe*'),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            if (value.length < 6) return 'Minimum 6 caractères';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          decoration:
              const InputDecoration(labelText: 'Confirmer le mot de passe*'),
          obscureText: true,
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildCaptchaVerification(),
      ],
    );
  }



  Widget _buildCaptchaVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _captchaVerified
              ? null
              : () => setState(() => _captchaVerified = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _captchaVerified ? Colors.green.shade50 : null,
            foregroundColor: _captchaVerified ? Colors.green.shade800 : null,
            side: BorderSide(
              color: _captchaVerified
                  ? Colors.green.shade400
                  : Colors.grey.shade300,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_captchaVerified)
                Icon(Icons.check_circle, color: Colors.green.shade800),
              if (_captchaVerified) const SizedBox(width: 8),
              Text(
                _captchaVerified ? 'CAPTCHA vérifié' : 'Vérifier le CAPTCHA',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
