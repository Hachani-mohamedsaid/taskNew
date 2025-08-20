import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer tous les projets
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final querySnapshot = await _firestore.collection('projects').get();
      return querySnapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des projets: $e');
      return ProjectModel.demoProjects; // Fallback vers les données de démo
    }
  }

  // Récupérer les projets par utilisateur
  Future<List<ProjectModel>> getProjectsByUser(String userEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('projects')
          .where('assignedUsers', arrayContains: userEmail)
          .get();
      return querySnapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des projets utilisateur: $e');
      return ProjectModel.demoProjects
          .where((project) => project.assignedUsers.contains(userEmail))
          .toList();
    }
  }

  // Récupérer les projets créés par un utilisateur
  Future<List<ProjectModel>> getProjectsCreatedBy(String userEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('projects')
          .where('createdBy', isEqualTo: userEmail)
          .get();
      return querySnapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des projets créés: $e');
      return ProjectModel.demoProjects
          .where((project) => project.createdBy == userEmail)
          .toList();
    }
  }

  // Créer un nouveau projet
  Future<void> createProject(ProjectModel project) async {
    try {
      await _firestore.collection('projects').add(project.toFirestore());
      print('Projet créé avec succès');
    } catch (e) {
      print('Erreur lors de la création du projet: $e');
      throw Exception('Erreur lors de la création du projet: $e');
    }
  }

  // Mettre à jour un projet
  Future<void> updateProject(ProjectModel project) async {
    try {
      await _firestore
          .collection('projects')
          .doc(project.id)
          .update(project.toFirestore());
      print('Projet mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour du projet: $e');
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  // Supprimer un projet
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
      print('Projet supprimé avec succès');
    } catch (e) {
      print('Erreur lors de la suppression du projet: $e');
      throw Exception('Erreur lors de la suppression du projet: $e');
    }
  }

  // Récupérer les statistiques des projets
  Future<Map<String, dynamic>> getProjectStats() async {
    try {
      final projects = await getAllProjects();

      final totalProjects = projects.length;
      final activeProjects = projects.where((p) => p.status == 'active').length;
      final completedProjects =
          projects.where((p) => p.status == 'completed').length;
      final pausedProjects = projects.where((p) => p.status == 'paused').length;

      final urgentProjects =
          projects.where((p) => p.priority == 'urgent').length;
      final highPriorityProjects =
          projects.where((p) => p.priority == 'high').length;

      final averageProgress = projects.isNotEmpty
          ? projects.map((p) => p.progress).reduce((a, b) => a + b) /
              projects.length
          : 0;

      return {
        'totalProjects': totalProjects,
        'activeProjects': activeProjects,
        'completedProjects': completedProjects,
        'pausedProjects': pausedProjects,
        'urgentProjects': urgentProjects,
        'highPriorityProjects': highPriorityProjects,
        'averageProgress': averageProgress.round(),
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {
        'totalProjects': 0,
        'activeProjects': 0,
        'completedProjects': 0,
        'pausedProjects': 0,
        'urgentProjects': 0,
        'highPriorityProjects': 0,
        'averageProgress': 0,
      };
    }
  }

  // Initialiser les données de démonstration dans Firestore
  Future<void> initializeDemoData() async {
    try {
      final projects = ProjectModel.demoProjects;
      for (final project in projects) {
        await _firestore.collection('projects').add(project.toFirestore());
      }
      print('Données de démonstration initialisées avec succès');
    } catch (e) {
      print(
          'Erreur lors de l\'initialisation des données de démonstration: $e');
    }
  }
}
