import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class BarChartWidget extends StatelessWidget {
  BarChartWidget({Key? key}) : super(key: key);

  final List<_ChartData> chartData = [
    _ChartData(650, 15),
    _ChartData(700, 20),
    _ChartData(750, 65),
    _ChartData(800, 130),
    _ChartData(850, 120),
    _ChartData(900, 130),
    _ChartData(950, 65),
    _ChartData(1000, 35),
    _ChartData(1050, 5),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 400,
      child: SfCartesianChart(
          title: ChartTitle(text: "123213", alignment: ChartAlignment.center, textStyle: TextStyle(fontSize: 10)),
          enableAxisAnimation: false,
          primaryXAxis: const NumericAxis(minimum: 500, maximum: 1200, interval: 100, title: AxisTitle(text: "Y축", textStyle: TextStyle(fontSize: 12))),
          primaryYAxis: const NumericAxis(
            minimum: 0,
            maximum: 140,
            interval: 20,
          ),
          series: <CartesianSeries<_ChartData, double>>[
            ColumnSeries<_ChartData, double>(
              animationDuration: 0,
              dataSource: chartData,
              xValueMapper: (_ChartData data, _) => data.x,
              yValueMapper: (_ChartData data, _) => data.y,
              color: Colors.blueAccent,
            )
          ]),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);

  final double x;
  final double y;
}
