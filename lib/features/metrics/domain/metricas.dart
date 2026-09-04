class Metricas {
  final int usuariosRegistrados;
  final int propuestasRegistradas;
  final int propuestasAprobadas;
  final int propuestasRechazadas;
  final int votacionesActivas;
  final int votacionesFinalizadas;
  final int totalVotos;
  final int proyectosActivos;
  final int proyectosFinalizados;
  final double nivelParticipacion;

  const Metricas({
    required this.usuariosRegistrados,
    required this.propuestasRegistradas,
    required this.propuestasAprobadas,
    required this.propuestasRechazadas,
    required this.votacionesActivas,
    required this.votacionesFinalizadas,
    required this.totalVotos,
    required this.proyectosActivos,
    required this.proyectosFinalizados,
    required this.nivelParticipacion,
  });

  factory Metricas.fromMap(Map<String, dynamic> map) => Metricas(
        usuariosRegistrados: (map['usuarios_registrados'] as num).toInt(),
        propuestasRegistradas: (map['propuestas_registradas'] as num).toInt(),
        propuestasAprobadas: (map['propuestas_aprobadas'] as num).toInt(),
        propuestasRechazadas: (map['propuestas_rechazadas'] as num).toInt(),
        votacionesActivas: (map['votaciones_activas'] as num).toInt(),
        votacionesFinalizadas: (map['votaciones_finalizadas'] as num).toInt(),
        totalVotos: (map['total_votos'] as num).toInt(),
        proyectosActivos: (map['proyectos_activos'] as num).toInt(),
        proyectosFinalizados: (map['proyectos_finalizados'] as num).toInt(),
        nivelParticipacion: (map['nivel_participacion'] as num).toDouble(),
      );

  String get reporteTexto => '''
Reporte de métricas — Comunidad BGA
Generado: ${DateTime.now().toString().split('.').first}

Usuarios registrados: $usuariosRegistrados
Propuestas registradas: $propuestasRegistradas
Propuestas aprobadas: $propuestasAprobadas
Propuestas rechazadas: $propuestasRechazadas
Votaciones activas: $votacionesActivas
Votaciones finalizadas: $votacionesFinalizadas
Total de votos emitidos: $totalVotos
Proyectos activos: $proyectosActivos
Proyectos finalizados: $proyectosFinalizados
Nivel de participación: $nivelParticipacion%
''';
}