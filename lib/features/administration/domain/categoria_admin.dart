class CategoriaAdmin {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  const CategoriaAdmin({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  factory CategoriaAdmin.fromMap(Map<String, dynamic> map) => CategoriaAdmin(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String?,
        activo: map['activo'] as bool,
      );
}