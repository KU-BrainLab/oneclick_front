import 'package:flutter/material.dart';
import 'package:omnifit_front/models/sleep_stage_prob_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StackedChartWidget extends StatelessWidget {
  SleepStageProbModel model;
  StackedChartWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildStackedArea100Chart();
  }

  /// Returns the stacked area 100 chart.
  SfCartesianChart _buildStackedArea100Chart() {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      legend: const Legend(position: LegendPosition.bottom,isVisible: true),
      primaryXAxis: const NumericAxis(
          labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 0),
          majorGridLines: MajorGridLines(width: 0),
          isVisible: true,
          title: AxisTitle(text: "Epcho Index")),
      primaryYAxis: const NumericAxis(
        isVisible: true,
        interval: 0.2,
        labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 0),
        title: AxisTitle(text: "Probability"),
        axisLine: AxisLine(width: 0), maximum: 100, minimum: 0),
        series: _getStackedAreaSeries(),
    );
  }

  /// Returns the list of chart series
  /// which need to render on the stacked area 100 chart.
  List<CartesianSeries<ChartData, num>> _getStackedAreaSeries() {
    return <CartesianSeries<ChartData, num>>[
      StackedArea100Series<ChartData, num>(
          animationDuration: 0,
          dataSource: model.list,
          color: const Color(0xFF443B83),
          xValueMapper: (ChartData sales, _) => sales.x,
          yValueMapper: (ChartData sales, _) => sales.w,
          legendIconType: LegendIconType.rectangle,
          name: 'W'),
      StackedArea100Series<ChartData, num>(
          animationDuration: 0,
          dataSource: model.list,
          color: const Color(0xFF306A90),
          xValueMapper: (ChartData sales, _) => sales.x,
          yValueMapper: (ChartData sales, _) => sales.rem,
          legendIconType: LegendIconType.rectangle,
          name: 'N1'),
      StackedArea100Series<ChartData, num>(
          animationDuration: 0,
          dataSource: model.list,
          color: const Color(0xFF1E948E),
          xValueMapper: (ChartData sales, _) => sales.x,
          yValueMapper: (ChartData sales, _) => sales.n1,
          legendIconType: LegendIconType.rectangle,
          name: 'N2'),
      StackedArea100Series<ChartData, num>(
          animationDuration: 0,
          color: const Color(0xFF33B979),
          dataSource: model.list,
          xValueMapper: (ChartData sales, _) => sales.x,
          yValueMapper: (ChartData sales, _) => sales.n2,
          legendIconType: LegendIconType.rectangle,
          name: 'N3'),
      StackedArea100Series<ChartData, num>(
          animationDuration: 0,
          dataSource: model.list,
          color: const Color(0xFF93C947),
          xValueMapper: (ChartData sales, _) => sales.x,
          yValueMapper: (ChartData sales, _) => sales.n3,
          legendIconType: LegendIconType.rectangle,
          name: 'REM')
    ];
  }
}