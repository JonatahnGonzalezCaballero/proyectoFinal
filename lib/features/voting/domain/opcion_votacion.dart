class OpcionVotacion {
  final String id;
  final String propuestaId;
  final String propuestaTitulo;
  final String? propuestaDescripcion;
  final String etiqueta;
  final int orden;

  const OpcionVotacion({
    required this.id,
    required this.propuestaId,
    required this.propuestaTitulo,
    this.propuestaDescripcion,
    required this.etiqueta,
    required this.orden,
  });

  factory OpcionVotacion.fromMap(Map<String, dynamic> map) {
    final propuesta = map['propuestas'] as Map<String, dynamic>?;
    return OpcionVotacion(
      id: map['id'] as String,
      propuestaId: map['propuesta_id'] as String,
      propuestaTitulo: propuesta?['titulo'] as String? ?? '',
      propuestaDescripcion: propuesta?['descripcion'] as String?,
      etiqueta: map['etiqueta'] as String? ?? '',
      orden: map['orden'] as int? ?? 0,
    );
  }

  String get tituloMostrado => etiqueta.isNotEmpty ? etiqueta : propuestaTitulo;
}