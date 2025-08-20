import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

class ProfileImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Méthode pour uploader une nouvelle image
  Future<String> uploadImage(XFile imageFile, {required String userId}) async {
    try {
      print('=== DÉBUT UPLOAD IMAGE ===');
      
      // Convertir l'image en bytes
      final Uint8List bytes = await imageFile.readAsBytes();
      
      // Créer une référence dans Firebase Storage
      final Reference storageRef = _storage
          .ref()
          .child('profile_images')
          .child('$userId-${DateTime.now().millisecondsSinceEpoch}');
      
      // Uploader l'image
      final UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Attendre la fin de l'upload
      final TaskSnapshot snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Upload réussi. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
      throw Exception('Échec de l\'upload de l\'image: $e');
    }
  }

  // Obtenir l'URL de l'image de profil
  Future<String?> getProfileImageUrl(String? photoURL) async {
    if (photoURL == null || photoURL.isEmpty) return null;

    try {
      print('=== DÉBUT RÉCUPÉRATION IMAGE ===');
      print('PhotoURL: $photoURL');

      // Si c'est déjà une URL HTTP, la retourner directement
      if (photoURL.startsWith('http://') || photoURL.startsWith('https://')) {
        print('URL HTTP détectée, retour direct');
        return photoURL;
      }

      // Si c'est un chemin Firebase Storage, obtenir l'URL de téléchargement
      if (photoURL.startsWith('gs://') || photoURL.contains('firebase')) {
        print('URL Firebase Storage détectée');
        final ref = _storage.refFromURL(photoURL);
        final url = await ref.getDownloadURL();
        print('URL Firebase récupérée: $url');
        return url;
      }

      print('Type d\'URL non reconnu');
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'image de profil: $e');
      return null;
    }
  }

  // Widget d'image de profil avec gestion d'erreurs
  Widget buildProfileImage({
    required String? photoURL,
    required double radius,
    required Color backgroundColor,
    required Widget fallbackWidget,
    BoxFit fit = BoxFit.cover,
  }) {
    return FutureBuilder<String?>(
      future: getProfileImageUrl(photoURL),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                backgroundColor.withOpacity(0.7),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            backgroundImage: NetworkImage(snapshot.data!),
            onBackgroundImageError: (exception, stackTrace) {
              print('Erreur de chargement de l\'image: $exception');
            },
            child: fallbackWidget,
          );
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: fallbackWidget,
        );
      },
    );
  }

  // Vérifier si l'URL de l'image est valide
  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || 
           url.startsWith('https://') ||
           url.startsWith('gs://') ||
           url.contains('firebase');
  }

  // Sélectionner une image depuis la galerie
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }
}