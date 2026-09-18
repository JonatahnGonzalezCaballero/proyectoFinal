import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_final/features/auth/domain/perfil_usuario.dart';

void main() {
  test('nombrePublico prioriza el alias sobre el nombre completo', () {
    const conAlias = PerfilUsuario(
      id: '1', nombreCompleto: 'Juan Pérez', correo: 'a@a.com', activo: true,
      rolNombre: 'ciudadano', alias: 'JuanP',
    );
    const sinAlias = PerfilUsuario(
      id: '2', nombreCompleto: 'Ana Ruiz', correo: 'b@b.com', activo: true, rolNombre: 'ciudadano',
    );
    expect(conAlias.nombrePublico, 'JuanP');
    expect(sinAlias.nombrePublico, 'Ana Ruiz');
  });
}