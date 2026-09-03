class UsuarioAdmin {
  final String id;
  final String nombreCompleto;
  final String correo;
  final bool activo;
  final String rolId;
  final String rolNombre;
  final DateTime fechaRegistro;

  const UsuarioAdmin({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.activo,
    required this.rolId,
    required this.rolNombre,
    required this.fechaRegistro,
  });

  factory UsuarioAdmin.fromMap(Map<String, dynamic> map) {
    final rol = map['roles'] as Map<String, dynamic>?;
    return UsuarioAdmin(
      id: map['id'] as String,
      nombreCompleto: map['nombre_completo'] as String,
      correo: map['correo'] as String,
      activo: map['activo'] as bool,
      rolId: map['rol_id'] as String,
      rolNombre: rol?['nombre'] as String? ?? '',
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
    );
  }
}