// lib/screens/task_list_screen.dart
import 'package:flutter/material.dart';

import '../model/task_model.dart';
import '../services/api/api_service.dart';
import 'case_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  final TaskCategory category;
  const TaskListScreen({super.key, required this.category});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTasksFromAPI();
  }

  /// Load tasks from API
  Future<void> _loadTasksFromAPI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getTaskList(
        taskType: widget.category == TaskCategory.accident
            ? 'SOLVING'
            : 'RESOLVING',
        status: null, // Load all statuses
      );

      if (response.isSuccess) {
        final tasks = response.getDataArray<Task>(
          'claims',
          (json) => Task.fromJson(json),
        );

        setState(() {
          _tasks = tasks;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ເກີດຂໍ້ຜິດພາດ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0099FF)),
      );
    }

    if (_errorMessage.isNotEmpty && _tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasksFromAPI,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0099FF),
              ),
              child: const Text(
                'ລອງໃໝ່',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ບໍ່ມີວຽກ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ REFRESH INDICATOR HERE!
    return RefreshIndicator(
      onRefresh: _loadTasksFromAPI,
      color: const Color(0xFF0099FF),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(), // Important!
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Navigate to detail screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaseDetailScreen(task: task),
            ),
          );

          // If detail screen returns true, reload list
          if (result == true) {
            _loadTasksFromAPI();
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _getStatusChip(task.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    task.customerName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.assignedDate),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              if (task.isUrgent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 14,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ດ່ວນ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getStatusChip(TaskStatus status) {
    String text;
    Color color;

    switch (status) {
      case TaskStatus.newTask:
        text = 'ໃໝ່';
        color = Colors.blue;
        break;
      case TaskStatus.inProgress:
        text = 'ກຳລັງດຳເນີນການ';
        color = Colors.orange;
        break;
      case TaskStatus.completed:
        text = 'ສຳເລັດ';
        color = Colors.green;
        break;
      case TaskStatus.cancelled:
        text = 'ຍົກເລີກ';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
