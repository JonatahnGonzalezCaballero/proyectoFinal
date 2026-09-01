class EvidenciaArchivo {
  final String id;
  final String url;

  const EvidenciaArchivo({required this.id, required this.url});

  factory EvidenciaArchivo.fromMap(Map<String, dynamic> map) => EvidenciaArchivo(
        id: map['id'] as String,
        url: map['url'] as String,
      );
}

class ActualizacionProyecto {
  final String id;
  final String proyectoId;
  final String autorNombre;
  final String descripcion;
  final int? porcentajeAvance;
  final DateTime fecha;
  final List<EvidenciaArchivo> archivos;

  const ActualizacionProyecto({
    required this.id,
    required this.proyectoId,
    required this.autorNombre,
    required this.descripcion,
    this.porcentajeAvance,
    required this.fecha,
    this.archivos = const [],
  });

  factory ActualizacionProyecto.fromMap(Map<String, dynamic> map) {
    final autor = map['usuarios'] as Map<String, dynamic>?;
    final archivosRaw = map['proyecto_archivos'] as List<dynamic>? ?? [];
    return ActualizacionProyecto(
      id: map['id'] as String,
      proyectoId: map['proyecto_id'] as String,
      autorNombre: autor?['nombre_completo'] as String? ?? '',
      descripcion: map['descripcion'] as String,
      porcentajeAvance: map['porcentaje_avance'] as int?,
      fecha: DateTime.parse(map['fecha'] as String),
      archivos: archivosRaw.map((e) => EvidenciaArchivo.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }
}