class ProyectoPorCategoria {
  final String categoria;
  final int total;

  const ProyectoPorCategoria({required this.categoria, required this.total});

  factory ProyectoPorCategoria.fromMap(Map<String, dynamic> map) => ProyectoPorCategoria(
        categoria: map['categoria'] as String,
        total: (map['total'] as num).toInt(),
      );
}

class Metricas {
  final int usuariosRegistrados;
  final int propuestasRegistradas;
  final int propuestasPendientes;
  final int propuestasEnRevision;
  final int propuestasAprobadas;
  final int propuestasRechazadas;
  final int propuestasConvertidas;
  final int votacionesProgramadas;
  final int votacionesActivas;
  final int votacionesFinalizadas;
  final int votacionesCanceladas;
  final int totalVotos;
  final int proyectosPlaneados;
  final int proyectosActivos;
  final int proyectosFinalizados;
  final int proyectosSuspendidos;
  final double nivelParticipacion;
  final List<ProyectoPorCategoria> proyectosPorCategoria;
  
  const Metricas({
    required this.usuariosRegistrados,
    required this.propuestasRegistradas,
    required this.propuestasPendientes,
    required this.propuestasEnRevision,
    required this.propuestasAprobadas,
    required this.propuestasRechazadas,
    required this.propuestasConvertidas,
    required this.votacionesProgramadas,
    required this.votacionesActivas,
    required this.votacionesFinalizadas,
    required this.votacionesCanceladas,
    required this.totalVotos,
    required this.proyectosPlaneados,
    required this.proyectosActivos,
    required this.proyectosFinalizados,
    required this.proyectosSuspendidos,
    required this.nivelParticipacion,
    required this.proyectosPorCategoria,
  });

  factory Metricas.fromMap(Map<String, dynamic> map) => Metricas(
        usuariosRegistrados: (map['usuarios_registrados'] as num).toInt(),
        propuestasRegistradas: (map['propuestas_registradas'] as num).toInt(),
        propuestasPendientes: (map['propuestas_pendientes'] as num).toInt(),
        propuestasEnRevision: (map['propuestas_en_revision'] as num).toInt(),
        propuestasAprobadas: (map['propuestas_aprobadas'] as num).toInt(),
        propuestasRechazadas: (map['propuestas_rechazadas'] as num).toInt(),
        propuestasConvertidas: (map['propuestas_convertidas'] as num).toInt(),
        votacionesProgramadas: (map['votaciones_programadas'] as num).toInt(),
        votacionesActivas: (map['votaciones_activas'] as num).toInt(),
        votacionesFinalizadas: (map['votaciones_finalizadas'] as num).toInt(),
        votacionesCanceladas: (map['votaciones_canceladas'] as num).toInt(),
        totalVotos: (map['total_votos'] as num).toInt(),
        proyectosPlaneados: (map['proyectos_planeados'] as num).toInt(),
        proyectosActivos: (map['proyectos_activos'] as num).toInt(),
        proyectosFinalizados: (map['proyectos_finalizados'] as num).toInt(),
        proyectosSuspendidos: (map['proyectos_suspendidos'] as num).toInt(),
        nivelParticipacion: (map['nivel_participacion'] as num).toDouble(),
        proyectosPorCategoria: ((map['proyectos_por_categoria'] as List<dynamic>?) ?? []).map((e) => ProyectoPorCategoria.fromMap(e as Map<String, dynamic>)).toList(),
      );

  int get propuestasAprobadasPuras => propuestasAprobadas - propuestasConvertidas;

  String get reporteTexto => '''
Reporte de métricas — Comunidad BGA
Generado: ${DateTime.now().toString().split('.').first}

Usuarios registrados: $usuariosRegistrados
Propuestas registradas: $propuestasRegistradas (pendientes: $propuestasPendientes, en revisión: $propuestasEnRevision, aprobadas: $propuestasAprobadasPuras, convertidas: $propuestasConvertidas, rechazadas: $propuestasRechazadas)
Votaciones: $votacionesProgramadas programadas, $votacionesActivas activas, $votacionesFinalizadas finalizadas, $votacionesCanceladas canceladas
Total de votos emitidos: $totalVotos
Proyectos: $proyectosPlaneados planeados, $proyectosActivos en ejecución, $proyectosFinalizados finalizados, $proyectosSuspendidos suspendidos
Nivel de participación: $nivelParticipacion%
''';
}