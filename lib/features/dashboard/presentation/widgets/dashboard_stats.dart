import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/profile_image_service.dart';

class DashboardStats extends StatelessWidget {
  final UserModel currentUser;
  final Map<String, dynamic>? projectStats; // inclut aussi les stats des tâches
  final Map<String, dynamic>? taskStats;
  final ProfileImageService _profileImageService = ProfileImageService();

  DashboardStats({
    super.key,
    required this.currentUser,
    this.projectStats,
    this.taskStats,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = currentUser.role == UserRole.admin;
    final theme = Theme.of(context);

    // Récupération dynamique des stats
    final int totalProjects = projectStats?['totalProjects'] ?? (isAdmin ? 5 : 2);
    final int activeTasks = projectStats?['activeTasks'] ?? (isAdmin ? 20 : 7);
    final int completedTasks = projectStats?['completedTasks'] ?? (isAdmin ? 8 : 2);
    final int overdueTasks = projectStats?['overdueTasks'] ?? (isAdmin ? 3 : 1);

    final int totalTasks = activeTasks + completedTasks + overdueTasks;
    final double completionPercentage =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Bienvenue avec photo de profil
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildProfileAvatar(theme, isAdmin),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin
                            ? "Bienvenue, ${currentUser.displayName}"
                            : "Bonjour, ${currentUser.displayName}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin ? "Administrateur de la plateforme" : "Membre de l'équipe",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  _buildAdminBadge(theme),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Cartes de statistiques
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              title: 'Projets',
              value: totalProjects.toString(),
              icon: Icons.folder_copy_rounded,
              color: Colors.deepPurple,
              iconColor: Colors.deepPurple[100],
            ),
            _StatCard(
              title: 'Tâches en cours',
              value: activeTasks.toString(),
              icon: Icons.task_alt_rounded,
              color: Colors.blue,
              iconColor: Colors.blue[100],
            ),
            _StatCard(
              title: 'Tâches terminées',
              value: completedTasks.toString(),
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              iconColor: Colors.green[100],
            ),
            _StatCard(
              title: 'Tâches en retard',
              value: overdueTasks.toString(),
              icon: Icons.warning_rounded,
              color: Colors.orange,
              iconColor: Colors.orange[100],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Graphiques
        Row(
          children: [
            Expanded(child: _buildPieChart(completedTasks, activeTasks, overdueTasks)),
            const SizedBox(width: 16),
            Expanded(child: _buildBarChart(activeTasks, completedTasks, overdueTasks)),
          ],
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildProfileAvatar(ThemeData theme, bool isAdmin) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: currentUser.photoURL != null && currentUser.photoURL!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                currentUser.photoURL!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar(theme, isAdmin);
                },
              ),
            )
          : _buildFallbackAvatar(theme, isAdmin),
    );
  }

  Widget _buildFallbackAvatar(ThemeData theme, bool isAdmin) {
    return Center(
      child: Icon(
        isAdmin ? Icons.admin_panel_settings : Icons.person,
        color: theme.primaryColor,
        size: 32,
      ),
    );
  }

  Widget _buildAdminBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            'ADMIN',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(int completed, int active, int overdue) {
    final total = completed + active + overdue;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Répartition des tâches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: completed.toDouble(),
                      color: Colors.green,
                      title: '${((completed / total) * 100).toStringAsFixed(1)}%',
                      radius: 25,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: active.toDouble(),
                      color: Colors.blue,
                      title: '${((active / total) * 100).toStringAsFixed(1)}%',
                      radius: 25,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: overdue.toDouble(),
                      color: Colors.orange,
                      title: '${((overdue / total) * 100).toStringAsFixed(1)}%',
                      radius: 25,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(int active, int completed, int overdue) {
    final maxY = (active + completed + overdue).toDouble();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Progression des tâches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY == 0 ? 1 : maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey[800],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Terminées');
                            case 1:
                              return const Text('En cours');
                            case 2:
                              return const Text('En retard');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [BarChartRodData(toY: completed.toDouble(), color: Colors.green, width: 20, borderRadius: BorderRadius.circular(4))],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [BarChartRodData(toY: active.toDouble(), color: Colors.blue, width: 20, borderRadius: BorderRadius.circular(4))],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [BarChartRodData(toY: overdue.toDouble(), color: Colors.orange, width: 20, borderRadius: BorderRadius.circular(4))],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.green, 'Terminées'),
        _buildLegendItem(Colors.blue, 'En cours'),
        _buildLegendItem(Colors.orange, 'En retard'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor ?? color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
