class ResultadoOpcion {
  final String votacionOpcionId;
  final String propuestaTitulo;
  final String etiqueta;
  final String opcionTitulo;
  final int totalVotos;

  const ResultadoOpcion({
    required this.votacionOpcionId,
    required this.propuestaTitulo,
    required this.etiqueta,
    required this.opcionTitulo,
    required this.totalVotos,
  });

  factory ResultadoOpcion.fromMap(Map<String, dynamic> map) => ResultadoOpcion(
        votacionOpcionId: map['votacion_opcion_id'] as String,
        propuestaTitulo: map['propuesta_titulo'] as String,
        etiqueta: map['etiqueta'] as String? ?? '',
        opcionTitulo: map['opcion_titulo'] as String? ?? map['propuesta_titulo'] as String,
        totalVotos: map['total_votos'] as int,
      );
}