class Proyecto {
  final String id;
  final String propuestaId;
  final String propuestaTitulo;
  final String responsableId;
  final String responsableNombre;
  final String titulo;
  final String? descripcion;
  final String estado;
  final int porcentajeAvance;
  final DateTime? fechaInicio;
  final DateTime? fechaFinEstimada;
  final DateTime fechaCreacion;

  const Proyecto({
    required this.id,
    required this.propuestaId,
    required this.propuestaTitulo,
    required this.responsableId,
    required this.responsableNombre,
    required this.titulo,
    this.descripcion,
    required this.estado,
    required this.porcentajeAvance,
    this.fechaInicio,
    this.fechaFinEstimada,
    required this.fechaCreacion,
  });

  factory Proyecto.fromMap(Map<String, dynamic> map) {
    final propuesta = map['propuestas'] as Map<String, dynamic>?;
    final responsable = map['usuarios'] as Map<String, dynamic>?;
    return Proyecto(
      id: map['id'] as String,
      propuestaId: map['propuesta_id'] as String,
      propuestaTitulo: propuesta?['titulo'] as String? ?? '',
      responsableId: map['responsable_id'] as String,
      responsableNombre: responsable?['nombre_completo'] as String? ?? '',
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String?,
      estado: map['estado'] as String,
      porcentajeAvance: map['porcentaje_avance'] as int,
      fechaInicio: map['fecha_inicio'] != null ? DateTime.parse(map['fecha_inicio'] as String) : null,
      fechaFinEstimada:
          map['fecha_fin_estimada'] != null ? DateTime.parse(map['fecha_fin_estimada'] as String) : null,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
    );
  }

  String get estadoLegible => switch (estado) {
        'planeado' => 'Planeado',
        'en_ejecucion' => 'En ejecución',
        'finalizado' => 'Finalizado',
        'suspendido' => 'Suspendido',
        _ => estado,
      };
}