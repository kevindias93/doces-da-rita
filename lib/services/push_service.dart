import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cliente_service.dart';

class PushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // NÃO roda em Windows desktop
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      print("⚠️ Push desativado no Windows");
      return;
    }

    await _messaging.requestPermission();

    String? token = await _messaging.getToken();

    print("🔥 FCM TOKEN: $token");

    final clienteId = await ClienteService.getClienteId();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(clienteId)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }
}
