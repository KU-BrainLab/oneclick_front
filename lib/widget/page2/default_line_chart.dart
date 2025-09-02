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
  /// Get the cartesian chart with default line series
  Container _buildDefaultLineChart() {
    double y0 = min(0.0, model.minY);
    if(y0 == -5){
      y0 = 0;
    }

    final List<Color> fillColors = [
      const Color(0xFFBEE9E8).withOpacity(0.7),
      const Color(0xFF62B6CB).withOpacity(0.7),
      const Color(0xFF1B4965).withOpacity(0.7),
      const Color(0xFFCAE9FF).withOpacity(0.7),
      const Color(0xFF5FA8D3).withOpacity(0.7),
    ];

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
            rangePadding: ChartRangePadding.none,
            labelIntersectAction: AxisLabelIntersectAction.none,
            majorGridLines: const MajorGridLines(width: 1),
            title: const AxisTitle(text: "Frequency (Hz)"),
            
            plotBands: <PlotBand>[
              PlotBand(start: 0, end: 4, color: fillColors[0]),
              PlotBand(start: 4, end: 8, color: fillColors[1]),
              PlotBand(start: 8, end: 12, color: fillColors[2]),
              PlotBand(start: 12, end: 30, color: fillColors[3]),
              PlotBand(start: 30, end: 45, color: fillColors[4]),
            ],
          ),
          primaryYAxis: NumericAxis(
            minimum: y0,
            maximum: model.maxY,
            interval: 5,
            labelIntersectAction: AxisLabelIntersectAction.none,
            majorGridLines: const MajorGridLines(width: 1),
            axisLabelFormatter: (AxisLabelRenderDetails args) {
              return ChartAxisLabel('${double.parse(args.text).toInt()}', null);
            },
            title: const AxisTitle(text: "10*log10(Power) + C"),
          ),

          annotations: <CartesianChartAnnotation>[
            CartesianChartAnnotation(
              widget: const Text('δ', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              coordinateUnit: CoordinateUnit.point,
              x: 2,
              y: model.maxY * 0.95,
            ),
            CartesianChartAnnotation(
              widget: const Text('θ', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              coordinateUnit: CoordinateUnit.point,
              x: 6, 
              y: model.maxY * 0.95,
            ),
            CartesianChartAnnotation(
              widget: const Text('α', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              coordinateUnit: CoordinateUnit.point,
              x: 10,
              y: model.maxY * 0.95,
            ),
            CartesianChartAnnotation(
              widget: const Text('β', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              coordinateUnit: CoordinateUnit.point,
              x: 21,
              y: model.maxY * 0.95,
            ),
            CartesianChartAnnotation(
              widget: const Text('γ', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              coordinateUnit: CoordinateUnit.point,
              x: 35,
              y: model.maxY * 0.95,
            ),
          ],


          series: <CartesianSeries>[
            FastLineSeries<FlSpot, double>(
                dataSource: model.dataList,
                xValueMapper: (FlSpot data, _) => data.x,
                yValueMapper: (FlSpot data, _) => data.y,
                animationDuration: 0,
                color: const Color(0xFF264653),
                opacity: 0.6,
            ),
          ],
      ),
    );
  }
}