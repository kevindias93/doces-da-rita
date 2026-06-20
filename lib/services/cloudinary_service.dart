import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dxslp8g4j';
  static const String uploadPreset = 'confeitaria_upload';

  static Future<String?> uploadImagem(File imagem) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(await http.MultipartFile.fromPath('file', imagem.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resposta = await response.stream.bytesToString();
      final dados = jsonDecode(resposta);

      return dados['secure_url'];
    }

    return null;
  }
}
