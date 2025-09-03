import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _tasksStream;

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
        .orderBy('dueDate', descending: false)
        .snapshots();
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour: ${_getStatusText(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reportProblem(String taskId, String taskTitle) async {
    final TextEditingController problemController = TextEditingController();
    final currentUser = _auth.currentUser;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tâche: $taskTitle'),
            const SizedBox(height: 16),
            TextField(
              controller: problemController,
              decoration: const InputDecoration(
                labelText: 'Description du problème',
                border: OutlineInputBorder(),
                hintText: 'Décrivez le problème rencontré...',
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (problemController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez décrire le problème'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                // Enregistrer le rapport dans la collection 'problem_reports'
                await _firestore.collection('problem_reports').add({
                  'taskId': taskId,
                  'taskTitle': taskTitle,
                  'description': problemController.text.trim(),
                  'reportedBy': currentUser?.uid,
                  'reportedByName':
                      currentUser?.displayName ?? currentUser?.email,
                  'status': 'pending', // pending, reviewed, resolved
                  'createdAt': Timestamp.now(),
                  'updatedAt': Timestamp.now(),
                });

                // Ajouter également le rapport comme commentaire dans la tâche
                await _firestore.collection('tasks').doc(taskId).update({
                  'comments': FieldValue.arrayUnion([
                    {
                      'type': 'problem_report',
                      'message': problemController.text.trim(),
                      'createdBy': currentUser?.uid,
                      'createdByName':
                          currentUser?.displayName ?? currentUser?.email,
                      'createdAt': Timestamp.now(),
                      'isProblem': true,
                    }
                  ]),
                  'commentsCount': FieldValue.increment(1),
                  'updatedAt': Timestamp.now(),
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Problème signalé à l\'administrateur'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Couleur de fond rouge
              foregroundColor: Colors.white, // Couleur du texte blanc
            ),
            child: const Text('Envoyer le rapport'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  String _formatDueDate(Timestamp timestamp) {
    final now = DateTime.now();
    final dueDate = timestamp.toDate();
    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return 'Dans ${difference.inDays} jour(s)';
    } else if (difference.inHours > 0) {
      return 'Dans ${difference.inHours} heure(s)';
    } else if (difference.inMinutes > 0) {
      return 'Dans ${difference.inMinutes} minute(s)';
    } else if (difference.inMinutes == 0) {
      return 'Maintenant';
    } else {
      return 'En retard';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'todo':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'done':
        return 'Terminé';
      case 'review':
        return 'En revue';
      default:
        return status;
    }
  }

  Widget _buildStatusButton(String taskId, String currentStatus,
      String targetStatus, String buttonText, Color color) {
    return ElevatedButton(
      onPressed: currentStatus == targetStatus
          ? null
          : () => _updateTaskStatus(taskId, targetStatus),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildReportButton(String taskId, String taskTitle) {
    return ElevatedButton.icon(
      onPressed: () => _reportProblem(taskId, taskTitle),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, // Changé en rouge pour plus de visibilité
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(
        Icons.warning_amber, // Icône d'avertissement
        size: 16,
      ),
      label: const Text(
        'Signaler problème',
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildTaskItem(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final taskId = document.id;
    final title = data['title'] ?? 'Sans titre';
    final description = data['description'] ?? 'Aucune description';
    final priority = data['priority'] ?? 'low';
    final status = data['status'] ?? 'todo';
    final dueDate = data['dueDate'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final commentsCount = data['commentsCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(priority),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    priority == 'high'
                        ? 'Élevée'
                        : priority == 'medium'
                            ? 'Moyenne'
                            : 'Basse',
                    style: TextStyle(
                      color: _getPriorityColor(priority),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (commentsCount > 0)
                  Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        commentsCount.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Boutons d'action pour changer le statut
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status != 'in_progress')
                  _buildStatusButton(
                    taskId,
                    status,
                    'in_progress',
                    'Marquer en cours',
                    Colors.blue,
                  ),
                if (status != 'done')
                  _buildStatusButton(
                    taskId,
                    status,
                    'done',
                    'Marquer terminé',
                    Colors.green,
                  ),
                if (status != 'todo')
                  _buildStatusButton(
                    taskId,
                    status,
                    'todo',
                    'Remettre à faire',
                    Colors.grey,
                  ),
                if (status != 'review')
                  _buildStatusButton(
                    taskId,
                    status,
                    'review',
                    'Demander revue',
                    Colors.orange,
                  ),
                // Bouton pour signaler un problème
                _buildReportButton(taskId, title),
              ],
            ),
            const SizedBox(height: 12),
            if (dueDate != null)
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDueDate(dueDate),
                    style: TextStyle(
                      color: dueDate.toDate().isBefore(DateTime.now()) &&
                              status != 'done'
                          ? Colors.red
                          : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: dueDate.toDate().isBefore(DateTime.now()) &&
                              status != 'done'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Échéance: ${DateFormat('dd/MM/yyyy').format(dueDate.toDate())}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Créée le: ${_formatTimestamp(createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucune tâche assignée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez aucune tâche en cours',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
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
            'Chargement des tâches...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tâches'),
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

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _tasksStream = _getTasksStream();
              });
            },
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskItem(tasks[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
