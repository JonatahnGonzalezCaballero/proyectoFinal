import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/firebase_options_manual.dart';

class PushRepository {
  PushRepository(this._client);
  final SupabaseClient _client;

  Future<void> registrarDispositivo() async {
    final permiso = await FirebaseMessaging.instance.requestPermission();
    final concedido = permiso.authorizationStatus == AuthorizationStatus.authorized ||
        permiso.authorizationStatus == AuthorizationStatus.provisional;
    if (!concedido) return;

    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? vapidKeyWeb : null,
    );
    final userId = _client.auth.currentUser?.id;
    if (token == null || userId == null) return;

    await _client.from('dispositivos_push').upsert(
      {
        'usuario_id': userId,
        'token': token,
        'plataforma': kIsWeb ? 'web' : 'android',
      },
      onConflict: 'usuario_id, token',
    );
  }
}