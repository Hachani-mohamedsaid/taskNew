import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/profile_image_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrestataireDashboardScreen extends StatefulWidget {
  final UserModel currentUser;

  const PrestataireDashboardScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<PrestataireDashboardScreen> createState() =>
      _PrestataireDashboardScreenState();
}

class _PrestataireDashboardScreenState
    extends State<PrestataireDashboardScreen> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  final ProfileImageService _profileImageService = ProfileImageService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Debug: Afficher les informations de l'image de profil
    print('=== DEBUG PROFIL PRESTATAIRE ===');
    print('PhotoURL: ${widget.currentUser.photoURL}');
    print('DisplayName: ${widget.currentUser.displayName}');
    print('Email: ${widget.currentUser.email}');
    print('Role: ${widget.currentUser.role}');
    print(
        'URL valide: ${_profileImageService.isValidImageUrl(widget.currentUser.photoURL)}');
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Dashboard Prestataire - ${widget.currentUser.displayName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Ouvrir les notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                // TODO: Implémenter la déconnexion
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Mes Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendrier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Rapports',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildTasksTab();
      case 2:
        return _buildCalendarTab();
      case 3:
        return _buildReportsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.handshake,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
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
                      // Menu profil
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'profile') {
                            _showProfileDialog();
                          } else if (value == 'logout') {
                            _logout();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person),
                                SizedBox(width: 8),
                                Text('Mon Profil'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text('Déconnexion'),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                  'Tâches en cours', '5', Icons.assignment, Colors.blue),
              _buildStatCard(
                  'Tâches terminées', '12', Icons.check_circle, Colors.green),
              _buildStatCard('Heures travaillées', '24h', Icons.access_time,
                  Colors.orange),
              _buildStatCard(
                  'Projets actifs', '3', Icons.folder, Colors.purple),
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
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
    return Card(
      elevation: 2,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          final tasks = [
            {
              'title': 'Développement Frontend',
              'status': 'En cours',
              'color': Colors.blue
            },
            {
              'title': 'Tests d\'intégration',
              'status': 'En attente',
              'color': Colors.orange
            },
            {
              'title': 'Documentation API',
              'status': 'Terminé',
              'color': Colors.green
            },
          ];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: tasks[index]['color'] as Color,
              child: Icon(Icons.assignment, color: Colors.white),
            ),
            title: Text(tasks[index]['title'] as String),
            subtitle: Text('Projet ${index + 1}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (tasks[index]['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tasks[index]['status'] as String,
                style: TextStyle(
                  color: tasks[index]['color'] as Color,
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

  Widget _buildTasksTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Mes Tâches',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Gérez vos tâches assignées',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Calendrier',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Planifiez vos tâches',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Rapports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Consultez vos performances',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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

  void _showProfileDialog() {
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

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }
}
