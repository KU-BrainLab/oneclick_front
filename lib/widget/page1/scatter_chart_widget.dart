import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ScatterChartWidget extends StatelessWidget {
  ScatterChartWidget({Key? key}) : super(key: key);

  final black = Colors.black;

  List<_ChartData>? chartData = <_ChartData>[
    _ChartData(x: 1000, y: 1000),
    _ChartData(x: 700, y: 700),
    _ChartData(x: 705, y: 705),
    _ChartData(x: 710, y: 710),
    _ChartData(x: 800, y: 800),
    _ChartData(x: 710, y: 710),
    _ChartData(x: 810, y: 810),
    _ChartData(x: 920, y: 920),
    _ChartData(x: 840, y: 840),
    _ChartData(x: 600, y: 600),
    _ChartData(x: 800, y: 800),
  ];

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: ChartTitle(text: "123213", alignment: ChartAlignment.center, textStyle: TextStyle(fontSize: 10)),
      primaryXAxis: const NumericAxis(
        interval: 100,
        minimum: 500,
        maximum: 1100,
        labelIntersectAction: AxisLabelIntersectAction.none,
        title: AxisTitle(text: "Time(m)", textStyle: TextStyle(fontSize: 12)),
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        interval: 100,
        minimum: 500,
        maximum: 1100,
        labelIntersectAction: AxisLabelIntersectAction.none,
        title: AxisTitle(text: "Time(m)", textStyle: TextStyle(fontSize: 12)),
        majorGridLines: MajorGridLines(width: 0),
      ),
      tooltipBehavior: TooltipBehavior(enable: false),
      series: <CartesianSeries>[
        // Renders scatter chart
        ScatterSeries<_ChartData, double>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          animationDuration: 0,
          enableTooltip: false,
          color: Colors.black,
        )
      ],
    );
  }
}

class _ChartData {
  _ChartData({
    required this.x,
    required this.y,
  });
  final double x;
  final double y;
}
