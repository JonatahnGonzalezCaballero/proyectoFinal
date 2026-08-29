import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_exception.dart';

/// Traduce las excepciones de Supabase
AppException mapSupabaseError(Object error) {
  if (error is AuthException) {
    return AppException(_mensajeAuth(error.message));
  }
  if (error is PostgrestException) {
    return AppException(_mensajePostgrest(error));
  }
  if (error is StorageException) {
    return AppException('No se pudo procesar el archivo: ${error.message}');
  }
  return const AppException('Ocurrió un error de conexión. Intenta de nuevo.');
}

String _mensajeAuth(String original) {
  if (original.contains('Invalid login credentials')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (original.contains('already registered')) {
    return 'Ya existe una cuenta registrada con ese correo.';
  }
  return original;
}

String _mensajePostgrest(PostgrestException error) {
  if (error.code == '23505') {
    return 'Ya existe un registro con esos datos.';
  }
  if (error.message.toLowerCase().contains('row-level security')) {
    return 'No tienes permisos para realizar esta acción.';
  }
  return 'No se pudo completar la operación. Intenta de nuevo.';
}