import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _tasksStream;
  
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _inProgressTasks = 0;
  int _todoTasks = 0;
  int _overdueTasks = 0;
  Map<String, int> _priorityStats = {};
  Map<String, int> _statusStats = {};

  @override
  void initState() {
    super.initState();
    _tasksStream = _getTasksStream();
  }

  Stream<QuerySnapshot> _getTasksStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('tasks')
        .where('assignedTo', arrayContains: currentUserId)
        .snapshots();
  }

  void _calculateStats(List<DocumentSnapshot> tasks) {
    _totalTasks = tasks.length;
    _completedTasks = 0;
    _inProgressTasks = 0;
    _todoTasks = 0;
    _overdueTasks = 0;
    _priorityStats = {'high': 0, 'medium': 0, 'low': 0};
    _statusStats = {'todo': 0, 'in_progress': 0, 'done': 0, 'review': 0};

    final now = DateTime.now();

    for (final task in tasks) {
      final data = task.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'todo';
      final priority = data['priority'] ?? 'low';
      final dueDate = data['dueDate'] as Timestamp?;

      // Statistiques de statut
      _statusStats[status] = (_statusStats[status] ?? 0) + 1;

      // Statistiques de priorité
      _priorityStats[priority] = (_priorityStats[priority] ?? 0) + 1;

      // Compteurs globaux
      switch (status) {
        case 'done':
          _completedTasks++;
          break;
        case 'in_progress':
          _inProgressTasks++;
          break;
        case 'todo':
          _todoTasks++;
          break;
      }

      // Tâches en retard
      if (dueDate != null && 
          dueDate.toDate().isBefore(now) && 
          status != 'done') {
        _overdueTasks++;
      }
    }
  }

  double _getCompletionRate() {
    return _totalTasks > 0 ? (_completedTasks / _totalTasks) * 100 : 0;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    final chartData = [
      _ChartData('Terminées', _completedTasks, Colors.green),
      _ChartData('En cours', _inProgressTasks, Colors.blue),
      _ChartData('À faire', _todoTasks, Colors.grey),
      _ChartData('En revue', _statusStats['review'] ?? 0, Colors.orange),
    ].where((data) => data.value > 0).toList();

    return SfCircularChart(
      series: <CircularSeries>[
        DoughnutSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.label,
          yValueMapper: (_ChartData data, _) => data.value,
          pointColorMapper: (_ChartData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        )
      ],
    );
  }

  Widget _buildPriorityChart() {
    final chartData = [
      _ChartData('Élevée', _priorityStats['high'] ?? 0, Colors.red),
      _ChartData('Moyenne', _priorityStats['medium'] ?? 0, Colors.orange),
      _ChartData('Basse', _priorityStats['low'] ?? 0, Colors.green),
    ].where((data) => data.value > 0).toList();

    return SfCircularChart(
      series: <CircularSeries>[
        PieSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.label,
          yValueMapper: (_ChartData data, _) => data.value,
          pointColorMapper: (_ChartData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        )
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicateurs de Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricItem(
              'Taux de completion',
              '${_getCompletionRate().toStringAsFixed(1)}%',
              _getCompletionRate() > 70 ? Colors.green : Colors.orange,
            ),
            _buildMetricItem(
              'Tâches en retard',
              _overdueTasks.toString(),
              _overdueTasks > 0 ? Colors.red : Colors.green,
            ),
            _buildMetricItem(
              'Productivité moyenne',
              _totalTasks > 0 ? (_completedTasks / 30).toStringAsFixed(1) : '0',
              Colors.blue,
              subtitle: 'tâches/jour (30 jours)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, {String subtitle = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Chargement des rapports...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucune donnée disponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par compléter des tâches pour voir vos statistiques',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports de Performance'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _tasksStream = _getTasksStream();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final tasks = snapshot.data!.docs;
          _calculateStats(tasks);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _tasksStream = _getTasksStream();
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiques principales
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                    children: [
                      _buildStatCard(
                        'Total des tâches',
                        _totalTasks.toString(),
                        Icons.assignment,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Tâches terminées',
                        _completedTasks.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'En progression',
                        _inProgressTasks.toString(),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Tâches en retard',
                        _overdueTasks.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Graphiques
                  _buildChartCard('Répartition par statut', _buildStatusChart()),
                  const SizedBox(height: 16),
                  _buildChartCard('Répartition par priorité', _buildPriorityChart()),
                  const SizedBox(height: 16),

                  // Indicateurs de performance
                  _buildPerformanceMetrics(),
                  const SizedBox(height: 24),

                  // Résumé
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résumé des performances',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getPerformanceSummary(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getPerformanceSummary() {
    if (_totalTasks == 0) {
      return 'Vous n\'avez aucune tâche assignée. Commencez par accepter des missions pour voir vos statistiques.';
    }

    final completionRate = _getCompletionRate();
    String summary = '';

    if (completionRate >= 80) {
      summary = 'Excellent travail ! Vous avez complété ${completionRate.toStringAsFixed(1)}% de vos tâches. ';
    } else if (completionRate >= 50) {
      summary = 'Bon travail ! Vous avez complété ${completionRate.toStringAsFixed(1)}% de vos tâches. ';
    } else {
      summary = 'Vous avez complété ${completionRate.toStringAsFixed(1)}% de vos tâches. ';
    }

    if (_overdueTasks > 0) {
      summary += 'Attention: vous avez $_overdueTasks tâche(s) en retard. ';
    }

    if (_inProgressTasks > 0) {
      summary += 'Vous avez $_inProgressTasks tâche(s) en cours. ';
    }

    summary += 'Continuez vos efforts !';

    return summary;
  }
}

class _ChartData {
  final String label;
  final int value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}