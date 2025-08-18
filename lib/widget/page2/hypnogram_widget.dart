import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:omnifit_front/models/hypnogram_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HypnogramWidget extends StatelessWidget {

  final HypnogramModel model;
  const HypnogramWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      enableAxisAnimation: false,
        primaryXAxis: const NumericAxis(interval: 10, isVisible: true,  title: AxisTitle(text: "Epoch Index")),
        primaryYAxis: NumericAxis(interval: 1, isVisible: true,  title: const AxisTitle(text: "Sleep Stage"),
          maximum: 4,
          axisLabelFormatter: (AxisLabelRenderDetails details) {

            if(details.value == 0) {
              return ChartAxisLabel("W", null);
            }
            if(details.value == 1) {
              return ChartAxisLabel("N1", null);
            }
            if(details.value == 2) {
              return ChartAxisLabel("N2", null);
            }
            if(details.value == 3) {
              return ChartAxisLabel("N3", null);
            }

            return ChartAxisLabel("REM", null);
          },

        ),
        series: <CartesianSeries>[
          // Renders step line chart
          StepLineSeries<HypnogramData, int>(
              animationDuration: 0,
              dataSource: model.dataList,
              color: const Color(0xFF6BBBC6),
              xValueMapper: (HypnogramData data, _) => data.x,
              yValueMapper: (HypnogramData data, _) => data.y
          )
        ]
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {

    return Text("${value.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10), textAlign: TextAlign.left);
  }
}
