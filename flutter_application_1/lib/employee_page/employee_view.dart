// Dosya: lib/pages/employee_view.dart
import 'package:flutter/material.dart';
import '../widgets/worker_task_card.dart';
import '../admin_page/task_model.dart';
// Havuz verisini çekmek için servisi import ediyoruz
import '../services/employee_service.dart';

class EmployeeView extends StatefulWidget {
  final String username;
  final double budget;
  final String currentAvailability;
  final List<String> availabilityOptions;

  // Callback Fonksiyonlar
  final Function(String) onStatusChanged;
  final VoidCallback onLogout;
  final Function(int) onTaskRequest;
  final Function(int taskId, String desc, double amount) onTaskComplete;
  final VoidCallback onShowHistory;

  // Kişisel işleri çekme fonksiyonu (Page'den gelir)
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

  // 3 Sekme Başlığı
  final List<String> _tabTitles = [
    'İş Havuzu',
    'Üzerimdeki İşler',
    'Tamamlanan',
  ];

  @override
  void initState() {
    super.initState();
    // Sekme sayısını 3 yaptık
    _tabController = TabController(length: _tabTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);
    const Color secondaryColor = Color(0xFF4B45B2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Arka Plan Gradyanı
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
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
                _buildInfoCard(primaryColor),
                const SizedBox(height: 20),

                // --- TAB BAR ---
                TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryColor,
                  tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
                ),

                // --- TAB VIEW (İçerikler) ---
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Sekme: HAVUZ (Yeni Fonksiyon - Servisten direkt çeker)
                      _buildPoolList(),

                      // 2. Sekme: SÜREÇTEKİLER (Page'den gelen fonksiyon)
                      _buildMyTaskList('IN_PROGRESS'),

                      // 3. Sekme: TAMAMLANANLAR (Page'den gelen fonksiyon)
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

  // --- 1. HAVUZ LİSTESİ WIDGET'I ---
  Widget _buildPoolList() {
    return FutureBuilder<List<WorkOrder>>(
      future: EmployeeService().fetchPoolTasks(), // Servisten direkt çağrı
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Havuzda açık iş yok."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, i) {
            final task = snapshot.data![i];
            return WorkerTaskCard(
              task: task,
              // Havuzdaki iş için "Talep Et" butonu aktiftir
              onTaskRequest: widget.onTaskRequest,
              // Havuzdaki iş tamamlanamaz, o yüzden burası işlevsiz olabilir veya kontrol edilebilir
              onTaskComplete: widget.onTaskComplete,
            );
          },
        );
      },
    );
  }

  // --- 2. KİŞİSEL GÖREV LİSTESİ WIDGET'I ---
  Widget _buildMyTaskList(String status) {
    return FutureBuilder<List<WorkOrder>>(
      future: widget.fetchTasks(status), // Page'den gelen fonksiyonu kullanır
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          String msg = status == 'IN_PROGRESS'
              ? "Üzerinizde aktif iş yok."
              : "Henüz tamamlanan iş yok.";
          return Center(child: Text(msg));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, i) => WorkerTaskCard(
            task: snapshot.data![i],
            onTaskRequest: widget.onTaskRequest,
            onTaskComplete: widget.onTaskComplete,
          ),
        );
      },
    );
  }

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

  Widget _buildInfoCard(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Text(
                    'Hoş Geldin, ${widget.username}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mevcut Bütçe',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      Text(
                        '${widget.budget.toStringAsFixed(2)} ₺',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.orange),
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
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
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
