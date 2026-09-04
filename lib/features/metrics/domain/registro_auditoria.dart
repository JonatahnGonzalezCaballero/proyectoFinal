class RegistroAuditoria {
  final String id;
  final String usuarioNombre;
  final String accion;
  final String entidad;
  final DateTime fecha;

  const RegistroAuditoria({
    required this.id,
    required this.usuarioNombre,
    required this.accion,
    required this.entidad,
    required this.fecha,
  });

  factory RegistroAuditoria.fromMap(Map<String, dynamic> map) {
    final usuario = map['usuarios'] as Map<String, dynamic>?;
    return RegistroAuditoria(
      id: map['id'] as String,
      usuarioNombre: usuario?['nombre_completo'] as String? ?? 'Desconocido',
      accion: map['accion'] as String,
      entidad: map['entidad'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }
}