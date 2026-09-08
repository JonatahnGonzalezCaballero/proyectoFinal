import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

FirebaseOptions get firebaseOptionsActuales {
  if (kIsWeb) {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBqtTcj6MrLT75TxhuP9wkjV66yI2CSzFI',
      appId: '1:893278207474:web:2611d8610c1809c6553f6b',
      messagingSenderId: '893278207474',
      projectId: 'proyecto-de-grado-40a5e',
      authDomain: 'proyecto-de-grado-40a5e.firebaseapp.com',
      storageBucket: 'proyecto-de-grado-40a5e.firebasestorage.app',
    );
  }
  return const FirebaseOptions(
    apiKey: 'AIzaSyCz_4FOIL8YL39FHxaZSeVjsrCCO4HSKM4',
    appId: '1:893278207474:android:9e0ed10f43ce4ba9553f6b',
    messagingSenderId: '893278207474',
    projectId: 'proyecto-de-grado-40a5e',
    storageBucket: 'proyecto-de-grado-40a5e.firebasestorage.app',
  );
}

const vapidKeyWeb = 'BIqj_1si1Yqpsg0Ad2xSf3ruT5q8CVpnLLnvRLDIJs0XPNVZezrEWR9WioSHz66PzxJEOM9r9_Z65XdBAkbsn9U';