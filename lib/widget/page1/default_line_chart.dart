import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:omnifit_front/models/graph1_model.dart';
import 'dart:math';
/// Chart import
import 'package:syncfusion_flutter_charts/charts.dart';


///Renders default line series chart
class DefaultLineChart extends StatelessWidget {
  final Graph1Model model;
  DefaultLineChart({Key? key, required this.model}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return _buildDefaultLineChart();
  }

  Widget _buildDefaultLineChart() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                'Raw PSD',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(10),
          height: 300,
          child: SfCartesianChart(
            primaryXAxis: NumericAxis(
              minimum: 0,
              interval: 50,
              maximum: model.maxX,
              labelIntersectAction: AxisLabelIntersectAction.none,
              majorGridLines: const MajorGridLines(width: 1),
              title: const AxisTitle(text: "Frequency (Hz)"),
              axisLabelFormatter: (AxisLabelRenderDetails args) {
                return ChartAxisLabel('${double.parse(args.text)/1000}', null);
              },
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: max(0.04, model.maxY),
              interval: max(0.005, (model.maxY/5)),
              labelIntersectAction: AxisLabelIntersectAction.none,
              majorGridLines: const MajorGridLines(width: 1),
              axisLabelFormatter: (AxisLabelRenderDetails args) {
                return ChartAxisLabel('${double.parse(args.text)}', null);
              },
              title: const AxisTitle(text: "Power (s²/Hz)"),
            ),
            series: <CartesianSeries>[
              FastLineSeries<FlSpot, double>(
                dataSource: model.dataList,
                xValueMapper: (FlSpot data, _) => data.x,
                yValueMapper: (FlSpot data, _) => data.y,
                animationDuration: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}