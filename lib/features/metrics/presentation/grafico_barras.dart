import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoBarras extends StatelessWidget {
  const GraficoBarras({super.key, required this.titulo, required this.datos});
  final String titulo;
  final List<(String etiqueta, int valor, Color color)> datos;

  @override
  Widget build(BuildContext context) {
    final maxValor = datos.map((d) => d.$2).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxValor == 0 ? 1.0 : maxValor * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Theme.of(context).colorScheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                        '${datos[group.x.toInt()].$1}\n${rod.toY.round()}',
                        TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString(), style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= datos.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              datos[index].$1,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < datos.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: datos[i].$2.toDouble(),
                          color: datos[i].$3,
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}