// lib/services/job_service.dart
import 'package:flutter/material.dart';

// Basit İş Modeli
class Job {
  final String id;
  final String title;
  final String address;
  final String date;

  Job({
    required this.id,
    required this.title,
    required this.address,
    required this.date,
  });
}

class JobService {
  // Bekleyen (Atanmamış) işleri getiren fonksiyon
  Future<List<Job>> fetchPendingJobs() async {
    // Simüle edilmiş veri (Burayı daha sonra API'ye bağlayacağız)
    await Future.delayed(const Duration(milliseconds: 500)); // Ağ gecikmesi
    return [
      Job(
        id: '101',
        title: 'Mutfak Musluğu Tamiri',
        address: 'Çankaya Mh. No:4',
        date: '28.12.2025',
      ),
      Job(
        id: '102',
        title: 'Elektrik Panosu Kontrolü',
        address: 'Kızılay AVM',
        date: '29.12.2025',
      ),
      Job(
        id: '103',
        title: 'Kombi Bakımı',
        address: 'Bahçelievler 7. Cadde',
        date: '29.12.2025',
      ),
      Job(
        id: '104',
        title: 'Banyo Tıkanıklık Açma',
        address: 'Dikmen Vadisi',
        date: '30.12.2025',
      ),
    ];
  }

  // İşi personele atama fonksiyonu (Simüle)
  Future<bool> assignJobToWorker(
    String workerId,
    String jobId,
    String note,
  ) async {
    // Burada API'ye POST isteği atılacak
    print("API İSTEĞİ: Personel $workerId, İş $jobId'ye atandı. Not: $note");
    await Future.delayed(const Duration(seconds: 1)); // Yükleniyor efekti için
    return true; // Başarılı döndü
  }
}
