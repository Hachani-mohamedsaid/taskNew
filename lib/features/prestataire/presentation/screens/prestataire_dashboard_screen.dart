import 'package:collaborative_task_manager/core/services/firebase_service.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/profile_image_service.dart';
import 'prestataire_navigation.dart';

class PrestataireDashboardScreen extends StatelessWidget {
  final UserModel currentUser;

  const PrestataireDashboardScreen({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Afficher les informations de l'image de profil
    debugPrint('=== DEBUG PROFIL PRESTATAIRE ===');
    debugPrint('PhotoURL: ${currentUser.photoURL}');
    debugPrint('DisplayName: ${currentUser.displayName}');
    debugPrint('Email: ${currentUser.email}');
    debugPrint('Role: ${currentUser.role}');
    
    final ProfileImageService profileImageService = ProfileImageService();
    
    // Vérification plus robuste de l'URL de l'image
    final isValidUrl = currentUser.photoURL != null && 
                      currentUser.photoURL!.isNotEmpty &&
                      (currentUser.photoURL!.startsWith('http://') || 
                       currentUser.photoURL!.startsWith('https://') ||
                       currentUser.photoURL!.startsWith('assets/'));
    
    debugPrint('URL valide: $isValidUrl');
    
    if (currentUser.photoURL != null) {
      debugPrint('Type de photoURL: ${currentUser.photoURL.runtimeType}');
      debugPrint('Longueur de photoURL: ${currentUser.photoURL?.length}');
    }
    
    return PrestataireNavigation(
      currentUser: currentUser, firebaseService: FirebaseService(),
      // Vous devrez peut-être passer le firebaseService ici si nécessaire
      // firebaseService: FirebaseService(),
    );
  }
}