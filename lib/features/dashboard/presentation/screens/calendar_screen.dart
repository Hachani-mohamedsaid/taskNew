import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../widgets/calendar_view.dart';

class CalendarScreen extends StatelessWidget {
  final UserModel currentUser;
  const CalendarScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
      ),
      body: CalendarView(currentUser: currentUser),
    );
  }
}