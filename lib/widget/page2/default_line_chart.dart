import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:omnifit_front/models/graph1_model.dart';

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

  /// Get the cartesian chart with default line series
  Container _buildDefaultLineChart() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black)
      ),
      child: SfCartesianChart(
        title: const ChartTitle(text: "Raw PSD", alignment: ChartAlignment.center),
          primaryXAxis: NumericAxis(
            minimum: model.minX,
            interval: 5,
            maximum: model.maxX,
            labelIntersectAction: AxisLabelIntersectAction.none,
            majorGridLines: const MajorGridLines(width: 1),
            title: const AxisTitle(text: "Frequency (Hz)"),
          ),
          primaryYAxis: NumericAxis(
            minimum: model.minY,
            maximum: model.maxY,
            interval: 5,
            labelIntersectAction: AxisLabelIntersectAction.none,
            majorGridLines: const MajorGridLines(width: 1),
            axisLabelFormatter: (AxisLabelRenderDetails args) {
              return ChartAxisLabel('${double.parse(args.text).toInt()}', null);
            },
            title: const AxisTitle(text: "10*log10(Power)"),
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
    );
  }
}