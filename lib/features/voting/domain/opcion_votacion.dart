class OpcionVotacion {
  final String id;
  final String propuestaId;
  final String propuestaTitulo;
  final int orden;

  const OpcionVotacion({
    required this.id,
    required this.propuestaId,
    required this.propuestaTitulo,
    required this.orden,
  });

  factory OpcionVotacion.fromMap(Map<String, dynamic> map) {
    final propuesta = map['propuestas'] as Map<String, dynamic>?;
    return OpcionVotacion(
      id: map['id'] as String,
      propuestaId: map['propuesta_id'] as String,
      propuestaTitulo: propuesta?['titulo'] as String? ?? '',
      orden: map['orden'] as int? ?? 0,
    );
  }
}