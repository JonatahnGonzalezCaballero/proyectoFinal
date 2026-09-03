class Notificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final String? tipo;
  final bool leida;
  final DateTime fecha;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.tipo,
    required this.leida,
    required this.fecha,
  });

  factory Notificacion.fromMap(Map<String, dynamic> map) => Notificacion(
        id: map['id'] as String,
        titulo: map['titulo'] as String,
        mensaje: map['mensaje'] as String,
        tipo: map['tipo'] as String?,
        leida: map['leida'] as bool,
        fecha: DateTime.parse(map['fecha'] as String),
      );
}