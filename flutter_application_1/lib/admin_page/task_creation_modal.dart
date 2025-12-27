import 'package:flutter/material.dart';
import '../services/task_service.dart';

class TaskCreationModal extends StatefulWidget {
  final VoidCallback onTaskCreated;

  const TaskCreationModal({required this.onTaskCreated, super.key});

  @override
  State<TaskCreationModal> createState() => _TaskCreationModalState();
}

class _TaskCreationModalState extends State<TaskCreationModal> {
  final TaskService _taskService = TaskService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Servisi çağır task_service.dart cagırılacak.
    final result = await _taskService.createTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Başarılı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
      widget.onTaskCreated(); // Listeyi yenilemesi için ana sayfaya haber ver
    } else {
      // Hata
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt Başarısız: ${result['message']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Arıza Kaydı Oluştur'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Başlık
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık / Özet',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Başlık zorunludur' : null,
              ),
              const SizedBox(height: 12),

              // 2. Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Arıza Detayı / Tanım',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Açıklama zorunludur' : null,
              ),
              const SizedBox(height: 12),

              // 3. Müşteri Adresi
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Müşteri Adresi',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Adres zorunludur' : null,
              ),
              const SizedBox(height: 12),

              // 4. Müşteri Telefonu
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Müşteri Telefonu',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _handleCreateTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
          child: const Text('Kaydet ve Yönlendir'),
        ),
      ],
    );
  }
}
