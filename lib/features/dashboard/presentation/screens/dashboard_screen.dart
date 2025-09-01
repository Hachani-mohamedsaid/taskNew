import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/project_service.dart';
import '../../../../core/services/firebase_service.dart';
import 'Task.dart';
import 'dashboard_home_screen.dart';
import 'projects_screen.dart';
import 'calendar_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel currentUser;
  const DashboardScreen({super.key, required this.currentUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

List<UserModel> usersList = []; // 🔹 Ajouté ici
  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final projectService = ProjectService();
    final firebaseService = FirebaseService();

final List<Widget> screens = [
  DashboardHomeScreen(
    currentUser: user,
    projectService: projectService,
    firebaseService: firebaseService,
  ),
  Task(
    currentUser: user,
    projectService: projectService, // 🔹 Ajouté ici
    usersList: usersList,
    firebaseService: firebaseService,
  ),
  ProjectsScreen(
    currentUser: user,
    projectService: projectService,
    
  ),
  CalendarScreen(currentUser: user),
  NotificationsScreen(currentUser: user),
  ProfileScreen(currentUser: user),
];


    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(6, (index) {
            final iconData = [
              Icons.dashboard,
              Icons.task_alt,
              Icons.folder,
              Icons.calendar_today,
              Icons.notifications,
              Icons.person,
            ];
            final labels = [
              'Tableau',
              'Tâches',
              'Projets',
              'Calendrier',
              'Notif.',
              'Profil',
            ];
            final isSelected = _currentIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? 28 : 0,
                          height: isSelected ? 28 : 0,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1976D2).withAlpha(31)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          iconData[index],
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey[400],
                          size: isSelected ? 20 : 18,
                        ),
                        if (index == 4)
                          Positioned(
                            right: 0,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withAlpha(102),
                                    blurRadius: 1.5,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 9, minHeight: 9),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.grey[400],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
