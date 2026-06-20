// File generated manually fixed
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdf8AzLCLlI42COWtcLWnogA0usrHPilk',
    appId: '1:898348869936:android:f2253e8bc67708122b40f5',
    messagingSenderId: '898348869936',
    projectId: 'doces-da-rita',
    storageBucket: 'doces-da-rita.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC_g4NJ_xlhw0Vd_l2VrpTLOWd9634B2fQ',
    appId: '1:898348869936:web:e4d489b369bf77f82b40f5',
    messagingSenderId: '898348869936',
    projectId: 'doces-da-rita',
    authDomain: 'doces-da-rita.firebaseapp.com',
    storageBucket: 'doces-da-rita.firebasestorage.app',
  );

  // 🔥 IMPORTANTE: Web config (usando config do windows web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_g4NJ_xlhw0Vd_l2VrpTLOWd9634B2fQ',
    appId: '1:898348869936:web:e4d489b369bf77f82b40f5',
    messagingSenderId: '898348869936',
    projectId: 'doces-da-rita',
    authDomain: 'doces-da-rita.firebaseapp.com',
    storageBucket: 'doces-da-rita.firebasestorage.app',
  );
}
