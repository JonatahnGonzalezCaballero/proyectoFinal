import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centraliza el acceso a las variables de entorno de Supabase
class SupabaseConfig {
  SupabaseConfig._();

  static String get url {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError(
        'SUPABASE_URL no esta definida. Verifica que exista un archivo ',
      );
    }
    return value;
  }

  static String get anonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY no está definida. Verifica tu archivo .env.',
      );
    }
    return value;
  }

    static String get passwordResetRedirectUrl {
    final value = dotenv.env['PASSWORD_RESET_REDIRECT_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('PASSWORD_RESET_REDIRECT_URL no está definida en .env.');
    }
    return value;
  }
}