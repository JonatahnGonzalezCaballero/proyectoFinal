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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colores.fondo, borderRadius: BorderRadius.circular(6)),
      child: Text(etiqueta, style: TextStyle(color: colores.texto, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}