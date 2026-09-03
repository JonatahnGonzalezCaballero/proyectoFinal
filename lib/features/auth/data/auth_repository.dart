import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/config/supabase_config.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  Session? get currentSession => _client.auth.currentSession;

  Future<void> registrar({
    required String correo,
    required String password,
    required String nombreCompleto,
  }) async {
    await _client.auth.signUp(
      email: correo,
      password: password,
      data: {'nombre_completo': nombreCompleto},
    );
  }

  Future<void> iniciarSesion({required String correo, required String password}) async {
    await _client.auth.signInWithPassword(email: correo, password: password);

    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      final perfil = await _client.from('usuarios').select('activo').eq('id', userId).maybeSingle();
      if (perfil != null && perfil['activo'] == false) {
        await _client.auth.signOut();
        throw const AppException('Tu cuenta ha sido desactivada. Contacta a un administrador.');
      }
    }
  }

  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  Future<void> enviarCorreoRecuperacion(String correo) async {
    await _client.auth.resetPasswordForEmail(
      correo,
      redirectTo: SupabaseConfig.passwordResetRedirectUrl,
    );
  }

  Future<void> actualizarPassword(String nuevaPassword) async {
    await _client.auth.updateUser(UserAttributes(password: nuevaPassword));
  }
}