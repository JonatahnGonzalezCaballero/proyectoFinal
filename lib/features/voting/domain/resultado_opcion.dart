class ResultadoOpcion {
  final String votacionOpcionId;
  final String propuestaTitulo;
  final int totalVotos;

  const ResultadoOpcion({
    required this.votacionOpcionId,
    required this.propuestaTitulo,
    required this.totalVotos,
  });

  factory ResultadoOpcion.fromMap(Map<String, dynamic> map) => ResultadoOpcion(
        votacionOpcionId: map['votacion_opcion_id'] as String,
        propuestaTitulo: map['propuesta_titulo'] as String,
        totalVotos: map['total_votos'] as int,
      );
}