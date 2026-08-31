class Categoria {
  final String id;
  final String nombre;

  const Categoria({required this.id, required this.nombre});

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
      );
}