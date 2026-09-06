import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<void> actualizarPerfil({String? alias, String? telefono}) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('usuarios').update({
      'alias': alias,
      'telefono': telefono,
    }).eq('id', userId);
  }

  Future<String> subirAvatar({required Uint8List bytes, required String extension}) async {
    final userId = _client.auth.currentUser!.id;
    final ruta = '$userId/avatar.$extension';

    await _client.storage.from('avatares').uploadBinary(
          ruta,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final urlBase = _client.storage.from('avatares').getPublicUrl(ruta);
    final url = '$urlBase?t=${DateTime.now().millisecondsSinceEpoch}';

    await _client.from('usuarios').update({'avatar_url': url}).eq('id', userId);
    return url;
  }
}