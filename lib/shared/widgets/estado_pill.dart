import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class EstadoPill extends StatelessWidget {
  const EstadoPill({super.key, required this.estado, required this.etiqueta});
  final String estado;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final colores = EstadoPillColors.para(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: colores.fondo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(colores.icono, size: 14, color: colores.texto),
          const SizedBox(width: 6),
          Text(etiqueta, style: TextStyle(color: colores.texto, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}