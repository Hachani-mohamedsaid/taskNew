import 'dart:async';

import 'package:collaborative_task_manager/features/dashboard/presentation/screens/notifications_screen.dart';
import 'package:collaborative_task_manager/features/prestataire/presentation/screens/calendar_tab.dart';
import 'package:collaborative_task_manager/features/prestataire/presentation/screens/dashboard_tab.dart';
import 'package:collaborative_task_manager/features/prestataire/presentation/screens/profile_tab.dart';
import 'package:collaborative_task_manager/features/prestataire/presentation/screens/reports_tab.dart';
import 'package:collaborative_task_manager/features/prestataire/presentation/screens/tasks_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firebase_service.dart';
import 'prestataire_notification_screen.dart'; // IMPORT AJOUTÉ

class PrestataireNavigation extends StatefulWidget {
  final UserModel currentUser;
  final FirebaseService firebaseService;

  const PrestataireNavigation({
    super.key,
    required this.currentUser,
    required this.firebaseService,
  });

  @override
  State<PrestataireNavigation> createState() => _PrestataireNavigationState();
}

class _PrestataireNavigationState extends State<PrestataireNavigation> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;
  late StreamSubscription<int> _notificationSubscription;

  final List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _widgetOptions.addAll([
      DashboardTab(currentUser: widget.currentUser, firebaseService: widget.firebaseService),
      TasksTab(currentUser: widget.currentUser, firebaseService: widget.firebaseService),
      const CalendarTab(),
      const ReportsTab(),
      ProfileTab(currentUser: widget.currentUser, firebaseService: widget.firebaseService),
    ]);
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  void _setupNotifications() {
    _notificationSubscription = widget.firebaseService
        .getUnreadCountStream(widget.currentUser.id)
        .listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          currentUser: widget.currentUser,
          firebaseService: widget.firebaseService,
        ),
      ),
    );
  }

  // NOUVELLE MÉTHODE POUR CONTACTER LES ADMINS
  void _navigateToContactAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrestataireNotificationScreen(
          currentUser: widget.currentUser,
          firebaseService: widget.firebaseService,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Prestataire - ${widget.currentUser.displayName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // BOUTON POUR CONTACTER LES ADMINS - AJOUTÉ ICI ↓
          IconButton(
            icon: const Icon(Icons.contact_support),
            onPressed: _navigateToContactAdmin,
            tooltip: 'Contacter les administrateurs',
          ),

          // Badge de notifications pour prestataire
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _navigateToNotifications,
                tooltip: 'Notifications',
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                setState(() {
                  _selectedIndex = 4; // Naviguer vers l'onglet Profil
                });
              } else if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paramètres à implémenter'),
                  ),
                );
              } else if (value == 'notifications') {
                _navigateToNotifications();
              } else if (value == 'contact_admin') {
                _navigateToContactAdmin(); // OPTION DANS LE MENU
              } else if (value == 'logout') {
                _logout(context);
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
                value: 'notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications),
                    SizedBox(width: 8),
                    Text('Notifications'),
                  ],
                ),
              ),
              // OPTION POUR CONTACTER LES ADMINS DANS LE MENU
              const PopupMenuItem(
                value: 'contact_admin',
                child: Row(
                  children: [
                    Icon(Icons.contact_support),
                    SizedBox(width: 8),
                    Text('Contacter admin'),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}