class PerfilUsuario {
  final String id;
  final String nombreCompleto;
  final String correo;
  final bool activo;
  final String rolNombre;
  final String? alias;
  final String? telefono;
  final String? avatarUrl;

  const PerfilUsuario({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.activo,
    required this.rolNombre,
    this.alias,
    this.telefono,
    this.avatarUrl,
  });

  bool get esAdministrador => rolNombre == 'administrador';
  String get nombrePublico => (alias != null && alias!.trim().isNotEmpty) ? alias!.trim() : nombreCompleto;

  factory PerfilUsuario.fromMap(Map<String, dynamic> map) {
    final rol = map['roles'] as Map<String, dynamic>?;
    return PerfilUsuario(
      id: map['id'] as String,
      nombreCompleto: map['nombre_completo'] as String? ?? '',
      correo: map['correo'] as String,
      activo: map['activo'] as bool? ?? true,
      rolNombre: rol?['nombre'] as String? ?? 'ciudadano',
      alias: map['alias'] as String?,
      telefono: map['telefono'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}