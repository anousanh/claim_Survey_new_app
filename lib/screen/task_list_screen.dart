// lib/screens/task_list_screen.dart
// Updated version using different API based on category

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

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController? _subTabController;
  final ApiService _apiService = ApiService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _loadTasksFromAPI();
  }

  @override
  void dispose() {
    _subTabController?.dispose();
    super.dispose();
  }

  Future<void> _loadTasksFromAPI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use different API based on category
      if (widget.category == TaskCategory.accident) {
        // For Solving category, use the original API
        await _loadSolvingTasks();
      } else {
        // For Resolving category, use the new API
        await _loadResolvingTasks();
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

  // Load tasks for Solving category (original method)
  Future<void> _loadSolvingTasks() async {
    final response = await _apiService.getMotorClaims(search: '', statusId: 0);

    if (response.isSuccess) {
      final tasks = response.getDataArray<Task>(
        'claims',
        (json) => Task.fromJson(json),
      );

      // Filter by category (accident/solving)
      final filteredTasks = tasks
          .where((task) => task.category == TaskCategory.accident)
          .toList();

      setState(() {
        _tasks = filteredTasks;
      });
    } else {
      setState(() {
        _errorMessage = response.message;
      });
    }
  }

  // Load tasks for Resolving category using MTResolveTasks
  Future<void> _loadResolvingTasks() async {
    // Option 1: If you have an API that fetches ALL resolve tasks
    // You might need to check with your backend team for the correct endpoint
    // For example: getMTResolveTasks() without claimNo parameter

    // For now, using the existing getMotorClaims but filtering for resolving
    final response = await _apiService.getMotorClaims(search: '', statusId: 0);

    if (response.isSuccess) {
      final tasks = response.getDataArray<Task>(
        'claims',
        (json) => Task.fromJson(json),
      );

      // Filter by category (insurance/resolving)
      final filteredTasks = tasks
          .where((task) => task.category == TaskCategory.additional)
          .toList();

      setState(() {
        _tasks = filteredTasks;
      });
    } else {
      setState(() {
        _errorMessage = response.message;
      });
    }

    // NOTE: If you need to use mtResolveTasks for individual claims,
    // you would need to:
    // 1. First get a list of claim numbers
    // 2. Then call mtResolveTasks for each claim
    // This would be inefficient and require multiple API calls
  }

  // Alternative: Load individual resolve task details
  Future<void> _loadResolveTaskDetails(int claimNo) async {
    try {
      final response = await _apiService.mtResolveTasks(claimNo);

      if (response.isSuccess) {
        // Process the single task response
        // You might need to adapt this based on the actual response structure
        final taskData = response.data;
        if (taskData != null) {
          final task = Task.fromJson(taskData);

          // Update or add this task to your list
          setState(() {
            final index = _tasks.indexWhere(
              (t) => t.claimNumber == claimNo.toString(),
            );
            if (index != -1) {
              _tasks[index] = task;
            } else {
              _tasks.add(task);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading resolve task details: $e');
    }
  }

  // Filter tasks by status code
  List<Task> _filterByStatusCode(List<int> statusCodes) {
    return _tasks
        .where((task) => statusCodes.contains(task.statusCode))
        .toList();
  }

  // Get tasks for each tab based on category
  List<Task> get _newCaseTasks {
    if (widget.category == TaskCategory.accident) {
      return _filterByStatusCode([6]); // Solving: Status 6 = New
    } else {
      return _filterByStatusCode([17]); // Resolving: Status 17 = Request
    }
  }

  List<Task> get _inProgressTasks {
    if (widget.category == TaskCategory.accident) {
      return _filterByStatusCode([7, 10, 11, 12, 13]); // Solving: In-progress
    } else {
      return _filterByStatusCode([18]); // Resolving: Status 18 = Approved
    }
  }

  List<Task> get _historyTasks {
    if (widget.category == TaskCategory.accident) {
      return _filterByStatusCode([8, 9]); // Solving: Completed/Rejected
    } else {
      return _filterByStatusCode([
        19,
        20,
        21,
      ]); // Resolving: Rejected/Finished/Paid
    }
  }

  int get _newCaseCount => _newCaseTasks.length;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_subTabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isLoading && _tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0099FF)),
      );
    }

    if (_errorMessage.isNotEmpty && _tasks.isEmpty) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Sub-tabs with badge
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController!,
            labelColor: const Color(0xFF0099FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0099FF),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('New Case'),
                    if (_newCaseCount > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(count: _newCaseCount),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'In-Progress'),
              const Tab(text: 'History'),
            ],
          ),
        ),

        // Content
        Expanded(
          child: TabBarView(
            controller: _subTabController!,
            children: [
              _buildTaskList(_newCaseTasks),
              _buildTaskList(_inProgressTasks),
              _buildTaskList(_historyTasks),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTasksFromAPI,
        color: const Color(0xFF0099FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: Center(
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
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasksFromAPI,
      color: const Color(0xFF0099FF),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _ModernTaskCard(
            task: task,
            onTap: () => _navigateToDetail(task),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _loadTasksFromAPI,
      color: const Color(0xFF0099FF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
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
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(Task task) async {
    // If this is a resolving task and you need more details
    if (widget.category == TaskCategory.additional &&
        task.claimNumber != null) {
      // Optionally load more details using mtResolveTasks
      await _loadResolveTaskDetails(int.tryParse(task.claimNumber!) ?? 0);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CaseDetailScreen(task: task)),
    );

    if (result == true) {
      _loadTasksFromAPI();
    }
  }
}

// Keep all the existing _ModernTaskCard, _Badge classes unchanged
class _ModernTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _ModernTaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                        '${task.title} : ${task.claimNumber}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    _getModernStatusChip(task.status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLicensePlate(
                  plateNumber: task.plateNumber ?? '',
                  plateProvince: task.plateProvince ?? '',
                  plateColorID: task.plateColorID ?? '',
                  vehicle: task.vehicle,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.person_outline,
                  'ຜູ້ແຈ້ງ',
                  task.customerName,
                ),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'ເບີໂທ',
                  task.declarerMobile ?? 'ບໍ່ລະບຸ',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'ສະຖານທີ່ເກີດອຸບັດຕິເຫດ',
                  task.accidentPlace ?? task.location,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.accidentDate ?? _formatDate(task.assignedDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (task.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ດ່ວນ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLicensePlate({
    required String plateNumber,
    required String plateProvince,
    required String plateColorID,
    String? vehicle,
  }) {
    Color plateColor = _getPlateColor(plateColorID);
    Color textColor = _getPlateTextColor(plateColorID);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0099FF).withOpacity(0.1),
            const Color(0xFF0099FF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0099FF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: plateColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  plateNumber,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plateProvince,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        vehicle ?? 'ບໍ່ລະບຸ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plateColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: plateColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _getPlateName(plateColorID),
                    style: TextStyle(
                      fontSize: 11,
                      color: plateColor.computeLuminance() > 0.5
                          ? Colors.grey[800]
                          : plateColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlateColor(String colorID) {
    switch (colorID) {
      case '1':
      case '2':
        return Colors.yellow[600]!;
      case '3':
      case '4':
        return Colors.white;
      case '5':
        return Colors.blue[600]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Color _getPlateTextColor(String colorID) {
    switch (colorID) {
      case '1':
      case '4':
        return Colors.black;
      case '2':
      case '3':
        return Colors.blue;
      case '5':
        return Colors.white;
      default:
        return Colors.black;
    }
  }

  String _getPlateName(String colorID) {
    switch (colorID) {
      case '1':
      case '2':
        return 'ເຫຼືອງ';
      case '3':
        return 'ຂາວ-ຟ້າ';
      case '4':
        return 'ຂາວ-ດຳ';
      case '5':
        return 'ຟ້າ';
      default:
        return 'ບໍ່ມີປ້າຍ';
    }
  }

  Widget _getModernStatusChip(TaskStatus status) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case TaskStatus.newTask:
        text = 'ໃໝ່';
        color = const Color(0xFF3B82F6);
        icon = Icons.fiber_new;
        break;
      case TaskStatus.inProgress:
        text = 'ດຳເນີນການ';
        color = const Color(0xFFF59E0B);
        icon = Icons.pending_actions;
        break;
      case TaskStatus.completed:
        text = 'ສຳເລັດ';
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_outline;
        break;
      case TaskStatus.cancelled:
        text = 'ຍົກເລີກ';
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
