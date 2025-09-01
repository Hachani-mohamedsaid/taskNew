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
    print('=== DEBUG PROFIL PRESTATAIRE ===');
    print('PhotoURL: ${currentUser.photoURL}');
    print('DisplayName: ${currentUser.displayName}');
    print('Email: ${currentUser.email}');
    print('Role: ${currentUser.role}');
    
    final ProfileImageService profileImageService = ProfileImageService();
    print('URL valide: ${profileImageService.isValidImageUrl(currentUser.photoURL)}');
    
    return PrestataireNavigation(currentUser: currentUser);
  }
}