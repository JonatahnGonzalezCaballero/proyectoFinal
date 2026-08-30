class PerfilUsuario {
  final String id;
  final String nombreCompleto;
  final String correo;
  final bool activo;
  final String rolNombre;

  const PerfilUsuario({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.activo,
    required this.rolNombre,
  });

  bool get esAdministrador => rolNombre == 'administrador';

  factory PerfilUsuario.fromMap(Map<String, dynamic> map) {
    final rol = map['roles'] as Map<String, dynamic>?;
    return PerfilUsuario(
      id: map['id'] as String,
      nombreCompleto: map['nombre_completo'] as String? ?? '',
      correo: map['correo'] as String,
      activo: map['activo'] as bool? ?? true,
      rolNombre: rol?['nombre'] as String? ?? 'ciudadano',
    );
  }
}