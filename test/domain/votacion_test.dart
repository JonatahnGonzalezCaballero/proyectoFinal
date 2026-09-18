import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_final/features/voting/domain/votacion.dart';

void main() {
  test('estaAbierta exige estado activa Y estar dentro del rango de fechas', () {
    final ahora = DateTime.now();
    final abierta = Votacion(
      id: '1', titulo: 'V', fechaInicio: ahora.subtract(const Duration(hours: 1)),
      fechaFin: ahora.add(const Duration(hours: 1)), estado: 'activa', tipo: 'si_no',
      fechaCreacion: ahora,
    );
    final programada = Votacion(
      id: '2', titulo: 'V', fechaInicio: ahora.add(const Duration(hours: 1)),
      fechaFin: ahora.add(const Duration(hours: 2)), estado: 'programada', tipo: 'si_no',
      fechaCreacion: ahora,
    );
    expect(abierta.estaAbierta, isTrue);
    expect(programada.estaAbierta, isFalse);
  });
}