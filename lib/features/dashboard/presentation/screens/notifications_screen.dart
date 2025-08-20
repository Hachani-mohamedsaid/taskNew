import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';

class NotificationsScreen extends StatelessWidget {
  final UserModel currentUser;
  const NotificationsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text('Écran des notifications'),
      ),
    );
  }
}