// lib/admin_page/task_creation_modal.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Definitions.dart';

// ❌ TaskCategory sınıfı artık kullanılmadığı için kaldırılmıştır.

class TaskCreationModal extends StatefulWidget {
  final VoidCallback onTaskCreated;

  const TaskCreationModal({required this.onTaskCreated, super.key});

  @override
  State<TaskCreationModal> createState() => _TaskCreationModalState();
}

class _TaskCreationModalState extends State<TaskCreationModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Kategori Future'ı kaldırıldı.

  @override
  void initState() {
    super.initState();
    // Kategori Future'ı kaldırıldı.
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Gönderilecek veriyi hazırla
    final Map<String, dynamic> bodyData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'customer_address': _addressController.text.trim(),
      'customer_phone': _phoneController.text.trim(),
    };

    final uri = Uri.parse('${Api.baseUrl}/api/tasks/create/');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni iş emri başarıyla oluşturuldu.')),
        );
        Navigator.of(context).pop();
        widget.onTaskCreated();
      } else {
        if (!mounted) return;
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage =
            errorBody['error'] ?? errorBody['detail'] ?? jsonEncode(errorBody);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt Başarısız: $errorMessage')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ağ Hatası: $e')));
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
                decoration: const InputDecoration(labelText: 'Başlık / Özet'),
                validator: (v) => v!.isEmpty ? 'Başlık zorunludur' : null,
              ),
              const SizedBox(height: 10),

              // 2. Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Arıza Detayı / Tanım',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Açıklama zorunludur' : null,
              ),
              const SizedBox(height: 10),

              // 3. Müşteri Adresi
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Müşteri Adresi'),
                validator: (v) => v!.isEmpty ? 'Adres zorunludur' : null,
              ),
              const SizedBox(height: 10),

              // 4. Müşteri Telefonu
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Müşteri Telefonu',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('Kaydet ve Yönlendir'),
        ),
      ],
    );
  }
}
