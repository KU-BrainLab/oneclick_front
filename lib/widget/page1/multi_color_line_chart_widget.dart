import 'package:flutter/material.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MultiColorLineChartWidget extends StatelessWidget {
  final MultiColorLineChartModel model;
  // 1. 외부에서 maxX 값을 받기 위한 변수 추가
  final double maxX;

  // 2. 생성자에 required this.maxX 추가
  const MultiColorLineChartWidget({
    Key? key, 
    required this.model,
    required this.maxX,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SfCartesianChart(
        primaryXAxis: NumericAxis(
          minimum: model.minX,
          maximum: maxX,
          title: const AxisTitle(
            text: "Time(m)",
            alignment: ChartAlignment.center, 
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          )
        ),          
        primaryYAxis: NumericAxis(minimum: model.minY, maximum: model.maxY, interval: model.intervalY),
          series: <CartesianSeries>[
            LineSeries<ChartData, double>(
              animationDuration: 0,
              dataSource: model.dataList,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              pointColorMapper: (ChartData data, _) => data.lineColor,
              width: 2,
            ),
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