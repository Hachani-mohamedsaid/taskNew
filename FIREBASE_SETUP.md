# Configuration Firebase pour l'enregistrement des utilisateurs

## Modifications apportées

### 1. Service Firebase (`lib/core/services/firebase_service.dart`)

Création d'un service Firebase pour gérer :
- Création d'utilisateurs dans Firebase Auth
- Sauvegarde des données utilisateur dans Firestore
- Récupération et mise à jour des données utilisateur

**Fonctionnalités principales :**
- `createUserWithEmailAndPassword()` : Crée un utilisateur dans Firebase Auth
- `saveUserData()` : Sauvegarde les données complètes dans Firestore
- `getUserData()` : Récupère les données utilisateur
- `updateUserData()` : Met à jour les données utilisateur
- `deleteUser()` : Supprime un utilisateur

### 2. Page de registre modifiée (`lib/features/auth/presentation/screens/register_screen.dart`)

**Améliorations apportées :**
- Intégration du service Firebase
- Sauvegarde complète des données du formulaire :
  - Nom et prénom
  - Email
  - Rôle (admin ou prestataire)
  - Chemin de l'image de profil
  - Timestamps de création et dernière connexion
- Gestion d'erreurs améliorée
- Messages de confirmation

### 3. Dépendances ajoutées (`pubspec.yaml`)

```yaml
firebase_storage: ^12.1.2
```

## Structure des données utilisateur dans Firestore

```json
{
  "id": "user_uid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "displayName": "John Doe",
  "role": "admin",
  "photoURL": "path/to/image.jpg",
  "createdAt": "timestamp",
  "lastSeen": "timestamp",
  "isActive": true
}
```

## Utilisation

1. **Remplir le formulaire d'inscription** avec :
   - Nom et prénom
   - Email valide
   - Mot de passe (minimum 6 caractères)
   - Sélection du rôle
   - Image de profil (optionnel)
   - Validation du captcha

2. **Cliquer sur "S'INSCRIRE"**

3. **Le système va :**
   - Créer l'utilisateur dans Firebase Auth
   - Sauvegarder toutes les données dans Firestore
   - Afficher un message de succès
   - Rediriger vers la page de connexion

## Gestion des erreurs

Le système gère les erreurs suivantes :
- Email déjà utilisé
- Email invalide
- Mot de passe trop faible
- Champs manquants
- Erreurs de connexion Firebase

## Configuration Firebase

Assurez-vous que votre projet Firebase est configuré avec :
- Firebase Auth activé
- Firestore Database activé
- Règles de sécurité appropriées

### Règles Firestore recommandées

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }
  }
}
```

## Test

Pour tester la fonctionnalité :
1. Lancer l'application : `flutter run -d chrome`
2. Aller à la page d'inscription
3. Remplir le formulaire
4. Vérifier dans la console Firebase que l'utilisateur est créé
5. Vérifier dans Firestore que les données sont sauvegardées 