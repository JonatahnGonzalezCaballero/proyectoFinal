class Votacion {
  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final String tipo;
  final DateTime fechaCreacion;

  const Votacion({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.tipo,
    required this.fechaCreacion,
  });

  factory Votacion.fromMap(Map<String, dynamic> map) => Votacion(
        id: map['id'] as String,
        titulo: map['titulo'] as String,
        descripcion: map['descripcion'] as String?,
        fechaInicio: DateTime.parse(map['fecha_inicio'] as String),
        fechaFin: DateTime.parse(map['fecha_fin'] as String),
        estado: map['estado'] as String,
        tipo: map['tipo'] as String? ?? 'seleccion_multiple',
        fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      );

  String get estadoLegible => switch (estado) {
        'programada' => 'Programada',
        'activa' => 'Activa',
        'finalizada' => 'Finalizada',
        'cancelada' => 'Cancelada',
        _ => estado,
      };

  bool get esSiNo => tipo == 'si_no';

  bool get estaAbierta {
    final ahora = DateTime.now();
    return estado == 'activa' && ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
  }
}