import 'package:flutter/material.dart';
import 'package:omnifit_front/models/sleep_phase_distribution_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SleepPhaseDistributionWidget extends StatelessWidget {
  final SleepPhaseDistributionModel model;
  const SleepPhaseDistributionWidget({super.key, required this.model});

  List<CartesianSeries<dynamic, dynamic>> _buildSeries() {
    const colors = <Color>[
      Color(0xFF443B83), // Wake
      Color(0xFF306A90), // N1
      Color(0xFF1E948E), // N2
      Color(0xFF33B979), // N3
      Color(0xFF93C947), // REM
    ];

    final phases = SleepPhaseDistributionModel.phaseLabels;
    final stages = SleepPhaseDistributionModel.stageLabels;

    return List.generate(stages.length, (si) {
      final dataSource = <Map<String, dynamic>>[
        for (int pi = 0; pi < phases.length; pi++)
          {'phase': phases[pi], 'value': model.data[pi][si]},
      ];
      return ColumnSeries<Map<String, dynamic>, String>(
        animationDuration: 0,
        dataSource: dataSource,
        xValueMapper: (d, _) => d['phase'] as String,
        yValueMapper: (d, _) => d['value'] as double,
        name: stages[si],
        color: colors[si],
        legendIconType: LegendIconType.rectangle,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        legend: const Legend(isVisible: true, position: LegendPosition.bottom),
        primaryXAxis: const CategoryAxis(
          title: AxisTitle(text: 'Phase'),
        ),
        primaryYAxis: const NumericAxis(
          minimum: 0,
          maximum: 100,
          interval: 20,
          title: AxisTitle(text: 'Percentage (%)'),
        ),
        series: _buildSeries(),
      ),
    );
  }
}
