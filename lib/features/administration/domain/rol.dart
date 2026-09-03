class Rol {
  final String id;
  final String nombre;

  const Rol({required this.id, required this.nombre});

  factory Rol.fromMap(Map<String, dynamic> map) => Rol(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
      );
}