import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ResultadoBarra extends StatelessWidget {
  const ResultadoBarra({
    super.key,
    required this.etiqueta,
    required this.votos,
    required this.totalVotos,
    required this.esLider,
  });
  final String etiqueta;
  final int votos;
  final int totalVotos;
  final bool esLider;

  @override
  Widget build(BuildContext context) {
    final porcentaje = totalVotos == 0 ? 0.0 : votos / totalVotos;
    final colorFondo = esLider ? AppColors.menta.withOpacity(0.35) : AppColors.periwinkle.withOpacity(0.35);
    final colorRelleno = esLider ? const Color(0xFF2C6A00) : AppColors.violeta;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorFondo, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(etiqueta, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: porcentaje,
                minHeight: 10,
                backgroundColor: AppColors.guijarro,
                valueColor: AlwaysStoppedAnimation(colorRelleno),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('$votos voto(s)', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: colorFondo, borderRadius: BorderRadius.circular(999)),
            child: Text('${(porcentaje * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w600, color: colorRelleno, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}