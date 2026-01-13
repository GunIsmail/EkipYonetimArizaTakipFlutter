// Dosya: lib/pages/employee_view.dart

import 'package:flutter/material.dart';
import '../widgets/worker_task_grid_card.dart';
import '../admin_page/task_model.dart';
import '../services/employee_service.dart';
import '../constants/app_colors.dart';

class EmployeeView extends StatefulWidget {
  final String username;
  final double budget;
  final String currentAvailability;
  final List<String> availabilityOptions;

  final Function(String) onStatusChanged;
  final VoidCallback onLogout;
  final Function(int) onTaskRequest;
  final Function(int taskId, String desc, double amount) onTaskComplete;
  final VoidCallback onShowHistory;

  final Future<List<WorkOrder>> Function(String statusFilter) fetchTasks;

  const EmployeeView({
    super.key,
    required this.username,
    required this.budget,
    required this.currentAvailability,
    required this.availabilityOptions,
    required this.onStatusChanged,
    required this.onLogout,
    required this.onTaskRequest,
    required this.onTaskComplete,
    required this.onShowHistory,
    required this.fetchTasks,
  });

  @override
  State<EmployeeView> createState() => _EmployeeViewState();
}

class _EmployeeViewState extends State<EmployeeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabTitles = [
    'İş Havuzu',
    'Üzerimdeki İşler',
    'Tamamlanan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Arka Plan Gradyanı
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildInfoCard(),
                const SizedBox(height: 20),

                // --- TAB BAR ---
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
                ),

                // --- TAB VIEW ---
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPoolList(),
                      _buildMyTaskList('IN_PROGRESS'),
                      _buildMyTaskList('COMPLETED'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. HAVUZ (GRID) ---
  Widget _buildPoolList() {
    return FutureBuilder<List<WorkOrder>>(
      future: EmployeeService().fetchPoolTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Hata: ${snapshot.error}",
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "Havuzda açık iş yok.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 sütun
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 200, // ✅ Kart yüksekliğini sabitledik
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, i) {
            final task = snapshot.data![i];
            return WorkerTaskGridCard(
              task: task,
              onTaskRequest: widget.onTaskRequest,
              onTaskComplete: (id, desc, amount) {},
            );
          },
        );
      },
    );
  }

  // --- 2/3. KİŞİSEL GÖREVLER (GRID) ---
  Widget _buildMyTaskList(String status) {
    return FutureBuilder<List<WorkOrder>>(
      future: widget.fetchTasks(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Hata: ${snapshot.error}",
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          String msg = status == 'IN_PROGRESS'
              ? "Üzerinizde aktif iş yok."
              : "Henüz tamamlanan iş yok.";
          return Center(
            child: Text(
              msg,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 200, 
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, i) => WorkerTaskGridCard(
            task: snapshot.data![i],
            onTaskRequest: widget.onTaskRequest,
            onTaskComplete: widget.onTaskComplete,
          ),
        );
      },
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Çalışan Paneli',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: widget.onLogout,
          ),
        ],
      ),
    );
  }

  // --- INFO CARD ---
  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: AppColors.background,
        elevation: 8,
        shadowColor: AppColors.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Hoş Geldin, ${widget.username}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.textSecondary),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mevcut Bütçe',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Row(
                    children: [
                      Text(
                        '${widget.budget.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.history,
                          color: AppColors.warning,
                        ),
                        tooltip: 'Bütçe Geçmişi',
                        onPressed: widget.onShowHistory,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: widget.currentAvailability,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                dropdownColor: AppColors.background,
                style: const TextStyle(color: AppColors.textPrimary),
                items: widget.availabilityOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.onStatusChanged(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
