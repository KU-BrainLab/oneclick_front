import 'package:flutter/material.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MultiColorLineChartWidget extends StatelessWidget {
  final MultiColorLineChartModel model;
  const MultiColorLineChartWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SfCartesianChart(
          primaryXAxis: NumericAxis(minimum: model.minX, maximum: model.maxX, interval: model.intervalX, title: const AxisTitle(text: "Time(m)")),
          primaryYAxis: NumericAxis(minimum: model.minY, maximum: model.maxY, interval: model.intervalY),
          series: <LineSeries<ChartData, double>>[
            LineSeries<ChartData, double>(
              animationDuration: 0,
              dataSource: model.dataList,
              xValueMapper: (ChartData sales, _) => sales.x,
              yValueMapper: (ChartData sales, _) => sales.y,
              width: 2,
              pointColorMapper: (ChartData sales, _) => sales.lineColor,
            )
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.4))),
            width: 140,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.red,
                    ),
                    const Spacer(),
                    const Text("Baseline", style: TextStyle(fontSize: 10)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.orange,
                    ),
                    const Spacer(),
                    const Text("Stimulation 1", style: TextStyle(fontSize: 10)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.yellow,
                    ),
                    const Spacer(),
                    const Text("Recovery 1", style: TextStyle(fontSize: 10)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.green,
                    ),
                    const Spacer(),
                    const Text("Stimulation 2", style: TextStyle(fontSize: 10)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.blue,
                    ),
                    const Spacer(),
                    const Text("Recovery 2", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}