// lib/screens/task_list_screen.dart
import 'package:flutter/material.dart';

import '../model/task_model.dart';
import 'case_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  final TaskCategory category;
  const TaskListScreen({super.key, required this.category});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with API calls
  final List<Task> _allTasks = [
    Task(
      id: 'TASK001',
      title: 'ອຸບັດຕິເຫດລົດຈັກ',
      policyNumber: 'POL-2024-001',
      policyType: 'car',
      status: TaskStatus.newTask,
      assignedDate: DateTime.now(),
      customerName: 'ທ. ສົມສັກ',
      location: 'ນະຄອນຫຼວງວຽງຈັນ',
      lat: 17.9659061,
      lng: 102.6135339,
      isUrgent: true,
      category: TaskCategory.accident,
      description: 'ລົດຈັກຊົນກັນ ບໍລິເວນທາງແຍກ ຖະໜົນລ້ານຊ້າງ',
    ),
    Task(
      id: 'TASK002',
      title: 'ໄຟໄໝ້ເຮືອນ',
      policyNumber: 'POL-2024-002',
      policyType: 'home',
      status: TaskStatus.inProgress,
      assignedDate: DateTime.now().subtract(Duration(days: 1)),
      customerName: 'ນ. ມະນີ',
      location: 'ແຂວງຫຼວງພະບາງ',
      category: TaskCategory.additional,
      description: 'ໄຟໄໝ້ເຮືອນບາງສ່ວນ ເນື່ອງຈາກໄຟຟ້າລັດວົງຈອນ',
    ),
    Task(
      id: 'TASK003',
      title: 'ອຸບັດຕິເຫດລົດຍົນ',
      policyNumber: 'POL-2024-003',
      policyType: 'car',
      status: TaskStatus.completed,
      assignedDate: DateTime.now().subtract(Duration(days: 2)),
      customerName: 'ທ. ບຸນມີ',
      location: 'ແຂວງສະຫວັນນະເຂດ',
      category: TaskCategory.accident,
    ),
    Task(
      id: 'TASK004',
      title: 'ຄ່າປິ່ນປົວສຸຂະພາບ',
      policyNumber: 'POL-2024-004',
      policyType: 'health',
      status: TaskStatus.newTask,
      assignedDate: DateTime.now(),
      customerName: 'ນ. ສີປອນ',
      location: 'ນະຄອນຫຼວງວຽງຈັນ',
      category: TaskCategory.additional,
    ),
    Task(
      id: 'TASK005',
      title: 'ລົດເສຍຫາຍຈາກນ້ຳຖ້ວມ',
      policyNumber: 'POL-2024-005',
      policyType: 'car',
      status: TaskStatus.cancelled,
      assignedDate: DateTime.now().subtract(Duration(days: 3)),
      customerName: 'ທ. ຄຳພອນ',
      location: 'ແຂວງຈຳປາສັກ',
      category: TaskCategory.accident,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _getTasksByStatus(TaskStatus status) {
    return _allTasks
        .where(
          (task) => task.category == widget.category && task.status == status,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFF0099FF),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF0099FF),
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'ໃໝ່'),
                Tab(text: 'ກຳລັງດຳເນີນການ'),
                Tab(text: 'ປະຫວັດ'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(TaskStatus.newTask),
                _buildTaskList(TaskStatus.inProgress),
                _buildHistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskStatus status) {
    final tasks = _getTasksByStatus(status);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'ບໍ່ມີລາຍການ',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildHistoryList() {
    final historyTasks = _allTasks
        .where(
          (task) =>
              task.category == widget.category &&
              (task.status == TaskStatus.completed ||
                  task.status == TaskStatus.cancelled),
        )
        .toList();

    if (historyTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'ບໍ່ມີປະຫວັດ',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: historyTasks.length,
      itemBuilder: (context, index) {
        final task = historyTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaseDetailScreen(task: task),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getPolicyIcon(task.policyType),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (task.isUrgent)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ດ່ວນ',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ເລກທີ: ${task.policyNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    task.customerName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(task.assignedDate),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Spacer(),
                  _getStatusChip(task.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPolicyIcon(String policyType) {
    IconData icon;
    Color color;

    switch (policyType) {
      case 'car':
        icon = Icons.directions_car;
        color = Colors.blue;
        break;
      case 'home':
        icon = Icons.home;
        color = Colors.orange;
        break;
      case 'health':
        icon = Icons.local_hospital;
        color = Colors.green;
        break;
      default:
        icon = Icons.policy;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Tooltip(
        message: _getPolicyTypeName(policyType),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  String _getPolicyTypeName(String type) {
    switch (type) {
      case 'car':
        return 'ປະກັນໄພລົດ';
      case 'home':
        return 'ປະກັນໄພເຮືອນ';
      case 'health':
        return 'ປະກັນໄພສຸຂະພາບ';
      default:
        return type;
    }
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
