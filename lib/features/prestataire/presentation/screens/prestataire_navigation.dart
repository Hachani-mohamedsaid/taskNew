import 'package:collaborative_task_manager/core/models/user_model.dart';
import 'package:flutter/material.dart';

import 'dashboard_tab.dart';
import 'tasks_tab.dart';
import 'calendar_tab.dart';
import 'reports_tab.dart';

class PrestataireNavigation extends StatefulWidget {
  final UserModel currentUser;

  const PrestataireNavigation({
    super.key,
    required this.currentUser,
  });

  @override
  State<PrestataireNavigation> createState() => _PrestataireNavigationState();
}

class _PrestataireNavigationState extends State<PrestataireNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _widgetOptions.addAll([
      DashboardTab(currentUser: widget.currentUser),
      const TasksTab(),
      const CalendarTab(),
      const ReportsTab(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        ],
      ),
    );
  }
}