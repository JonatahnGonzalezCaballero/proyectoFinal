import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_final/features/proposals/domain/propuesta.dart';

void main() {
  Propuesta crear({required String estado}) => Propuesta(
        id: '1', usuarioId: 'u', categoriaId: 'c', categoriaNombre: 'Cat',
        titulo: 'Título', descripcion: 'Descripción', estado: estado, fechaCreacion: DateTime(2026),
      );

  group('Propuesta', () {
    test('estadoLegible traduce cada estado', () {
      expect(crear(estado: 'pendiente').estadoLegible, 'Pendiente de revisión');
      expect(crear(estado: 'rechazada').estadoLegible, 'Rechazada');
    });

    test('esEditable solo es true en estado pendiente', () {
      expect(crear(estado: 'pendiente').esEditable, isTrue);
      expect(crear(estado: 'aprobada').esEditable, isFalse);
    });
  });
}