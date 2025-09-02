import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/profile_image_service.dart';

class DashboardTab extends StatefulWidget {
  final UserModel currentUser;

  const DashboardTab({
    super.key,
    required this.currentUser,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ProfileImageService _profileImageService = ProfileImageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int _tasksInProgress = 0;
  int _tasksCompleted = 0;
  int _activeProjects = 0;
  int _totalHoursWorked = 0;
  List<Map<String, dynamic>> _recentTasks = [];
  Map<String, String> _projectNames = {}; // Cache pour les noms de projets
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadStatistics();
    await _loadRecentTasks();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadStatistics() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Charger les statistiques des tâches
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('assignedTo', arrayContains: currentUserId)
          .get();

      int inProgress = 0;
      int completed = 0;
      Set<String> projectIds = {};

      for (final doc in tasksQuery.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'todo';
        final projectId = data['projectId']?.toString();

        if (status == 'in_progress') {
          inProgress++;
        } else if (status == 'done') {
          completed++;
        }

        if (projectId != null && projectId.isNotEmpty) {
          projectIds.add(projectId);
        }
      }

      // Charger les noms des projets
      await _loadProjectNames(projectIds.toList());

      // Calculer les heures travaillées (exemple simplifié)
      final hoursWorked = completed * 2; // Exemple: 2 heures par tâche terminée

      setState(() {
        _tasksInProgress = inProgress;
        _tasksCompleted = completed;
        _activeProjects = projectIds.length;
        _totalHoursWorked = hoursWorked;
      });
    } catch (error) {
      print('Erreur lors du chargement des statistiques: $error');
    }
  }

  Future<void> _loadProjectNames(List<String> projectIds) async {
    if (projectIds.isEmpty) return;

    try {
      for (final projectId in projectIds) {
        if (!_projectNames.containsKey(projectId)) {
          final projectDoc = await _firestore
              .collection('projects')
              .doc(projectId)
              .get();
          
          if (projectDoc.exists) {
            final projectData = projectDoc.data() as Map<String, dynamic>?;
            final projectName = projectData?['name'] ?? 
                               projectData?['title'] ?? 
                               projectData?['projectName'] ??
                               'Projet sans nom';
            _projectNames[projectId] = projectName;
          } else {
            _projectNames[projectId] = 'Projet inconnu';
          }
        }
      }
    } catch (error) {
      print('Erreur lors du chargement des noms de projets: $error');
    }
  }

  Future<void> _loadRecentTasks() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('assignedTo', arrayContains: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      final List<Map<String, dynamic>> tasks = [];
      final Set<String> projectIds = {};
      
      for (final doc in tasksQuery.docs) {
        final data = doc.data();
        final projectId = data['projectId']?.toString();
        
        tasks.add({
          'id': doc.id,
          'title': data['title'] ?? 'Sans titre',
          'status': data['status'] ?? 'todo',
          'priority': data['priority'] ?? 'low',
          'projectId': projectId,
          'dueDate': data['dueDate'],
        });

        if (projectId != null && projectId.isNotEmpty) {
          projectIds.add(projectId);
        }
      }

      // Charger les noms des projets pour les tâches récentes
      await _loadProjectNames(projectIds.toList());

      setState(() {
        _recentTasks = tasks;
      });
    } catch (error) {
      print('Erreur lors du chargement des tâches récentes: $error');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'review':
        return Colors.orange;
      case 'todo':
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_progress':
        return 'En cours';
      case 'done':
        return 'Terminé';
      case 'review':
        return 'En revue';
      case 'todo':
      default:
        return 'À faire';
    }
  }

  String _getProjectName(String? projectId) {
    if (projectId == null || projectId.isEmpty) {
      return 'Aucun projet';
    }
    return _projectNames[projectId] ?? 'Chargement...';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue avec profil amélioré
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green[400]!,
                    Colors.green[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar avec image de profil ou initiales
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: widget.currentUser.photoURL != null
                              ? NetworkImage(widget.currentUser.photoURL!)
                              : null,
                          child: widget.currentUser.photoURL == null
                              ? Text(
                                  widget.currentUser.displayName
                                      .split(' ')
                                      .map((e) => e.isNotEmpty ? e[0] : '')
                                      .join('')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue,',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.currentUser.displayName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.handshake,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'PRESTATAIRE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Informations supplémentaires
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(Icons.email, widget.currentUser.email),
                        _buildInfoItem(Icons.access_time,
                            'Dernière connexion: ${_formatDate(widget.currentUser.lastSeen)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistiques
            Text(
              'Mes Statistiques',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                    context, 'Tâches en cours', _tasksInProgress.toString(), Icons.assignment, Colors.blue),
                _buildStatCard(
                    context, 'Tâches terminées', _tasksCompleted.toString(), Icons.check_circle, Colors.green),
                _buildStatCard(context, 'Heures travaillées', '${_totalHoursWorked}h', Icons.access_time,
                    Colors.orange),
                _buildStatCard(
                    context, 'Projets actifs', _activeProjects.toString(), Icons.folder, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            // Tâches récentes
            Text(
              'Tâches Récentes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRecentTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasks() {
    if (_recentTasks.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Aucune tâche récente',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentTasks.length,
        itemBuilder: (context, index) {
          final task = _recentTasks[index];
          final statusColor = _getStatusColor(task['status']);
          final projectName = _getProjectName(task['projectId']);
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: const Icon(Icons.assignment, color: Colors.white),
            ),
            title: Text(task['title']),
            subtitle: Text('Projet: $projectName'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(task['status']),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green[100],
                backgroundImage: widget.currentUser.photoURL != null
                    ? NetworkImage(widget.currentUser.photoURL!)
                    : null,
                child: widget.currentUser.photoURL == null
                    ? Text(
                        widget.currentUser.displayName
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .join('')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.currentUser.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PRESTATAIRE',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileInfo(Icons.email, 'Email', widget.currentUser.email),
              const SizedBox(height: 8),
              _buildProfileInfo(Icons.calendar_today, 'Membre depuis',
                  '${widget.currentUser.createdAt.day}/${widget.currentUser.createdAt.month}/${widget.currentUser.createdAt.year}'),
              const SizedBox(height: 8),
              _buildProfileInfo(Icons.access_time, 'Dernière connexion',
                  '${widget.currentUser.lastSeen.day}/${widget.currentUser.lastSeen.month}/${widget.currentUser.lastSeen.year}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }
}