import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ClienteService {
  static const String chaveClienteId = 'cliente_id';

  static Future<String> getClienteId() async {
    final prefs = await SharedPreferences.getInstance();

    String? clienteId = prefs.getString(chaveClienteId);

    if (clienteId == null) {
      clienteId = const Uuid().v4();

      await prefs.setString(chaveClienteId, clienteId);
    }

    return clienteId;
  }
}
