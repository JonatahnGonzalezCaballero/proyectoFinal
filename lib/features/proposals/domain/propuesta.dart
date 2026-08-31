class ArchivoPropuesta {
  final String id;
  final String url;

  const ArchivoPropuesta({required this.id, required this.url});

  factory ArchivoPropuesta.fromMap(Map<String, dynamic> map) => ArchivoPropuesta(
        id: map['id'] as String,
        url: map['url'] as String,
      );
}

class Propuesta {
  final String id;
  final String usuarioId;
  final String categoriaId;
  final String categoriaNombre;
  final String titulo;
  final String descripcion;
  final String? ubicacion;
  final String estado;
  final String? observaciones;
  final DateTime fechaCreacion;
  final List<ArchivoPropuesta> archivos;

  const Propuesta({
    required this.id,
    required this.usuarioId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.titulo,
    required this.descripcion,
    this.ubicacion,
    required this.estado,
    this.observaciones,
    required this.fechaCreacion,
    this.archivos = const [],
  });

  factory Propuesta.fromMap(Map<String, dynamic> map) {
    final categoria = map['categorias'] as Map<String, dynamic>?;
    final archivosRaw = map['propuesta_archivos'] as List<dynamic>? ?? [];
    return Propuesta(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      categoriaId: map['categoria_id'] as String,
      categoriaNombre: categoria?['nombre'] as String? ?? '',
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      ubicacion: map['ubicacion'] as String?,
      estado: map['estado'] as String,
      observaciones: map['observaciones'] as String?,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      archivos: archivosRaw
          .map((e) => ArchivoPropuesta.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get estadoLegible => switch (estado) {
        'pendiente' => 'Pendiente de revisión',
        'en_revision' => 'En revisión',
        'aprobada' => 'Aprobada',
        'rechazada' => 'Rechazada',
        'convertida_proyecto' => 'Convertida en proyecto',
        _ => estado,
      };

  bool get esEditable => estado == 'pendiente';
}