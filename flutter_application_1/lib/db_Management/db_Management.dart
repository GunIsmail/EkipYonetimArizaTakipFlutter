import 'package:http/http.dart' as http;
import 'dart:convert';

// Yeni bir kullanıcı kaydetmek için bu fonksiyonu çağıracaksın.
Future<void> registerNewUser(String username, String password) async {
  //Sunucunun ip adresi buradan cekilmeli
  const String registerUrl = 'http://10.0.2.2:8000/api/register/';

  try {
    // Garson siparişi mutfağa iletiyor (POST isteği gönderiliyor)
    final response = await http.post(
      Uri.parse(registerUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8', // Dilimiz JSON
      },
      body: jsonEncode({
        // Siparişin detayları JSON olarak kodlanıyor
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      // 201 = Başarıyla Oluşturuldu

      print('Kullanıcı başarıyla oluşturuldu!');
      print('Mutfaktan gelen cevap: ${response.body}');
    } else {
      //  bu kullanıcı adı zaten var
      print('Kullanıcı oluşturulamadı. Hata kodu: ${response.statusCode}');
      print('Mutfaktan gelen hata mesajı: ${response.body}');
    }
  } catch (e) {
    print('Sunucuya ulaşılamadı. Hata: $e');
  }
}
