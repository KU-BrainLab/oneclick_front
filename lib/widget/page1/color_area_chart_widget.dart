import 'package:flutter/material.dart';
import 'package:omnifit_front/models/color_area_chart_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:ui' as ui;

class ColorAreaChartWidget extends StatelessWidget {
  final ColorAreaChartModel model;
  const ColorAreaChartWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: SfCartesianChart(
              primaryXAxis: NumericAxis(interval: model.intervalX, maximum: model.maxX, minimum: model.minX, title: const AxisTitle(text: "X축", textStyle: TextStyle(fontSize: 12))),
              primaryYAxis: NumericAxis(minimum: model.minY, maximum: model.maxY, interval: model.intervalY, title: const AxisTitle(text: "Y축", textStyle: TextStyle(fontSize: 12))),
              series: <CartesianSeries<ChartData, double>>[
                AreaSeries<ChartData, double>(
                    animationDuration: 0,
                    dataSource: model.chartList,
                    onCreateShader: (ShaderDetails details) {
                      return ui.Gradient.linear(
                        details.rect.bottomLeft,
                        details.rect.bottomRight,
                        const <Color>[Colors.purple, Colors.purple, Colors.blue, Colors.blue, Colors.green, Colors.green, Colors.orange, Colors.orange, Colors.red, Colors.red],
                        <double>[0, 0.2, 0.2, 0.4, 0.4, 0.6, 0.6, 0.8, 0.8, 0.8], // 곱하기 2를 해야됨
                      );
                    },
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y)
              ]),
        ),

        // Align(
        //   alignment: Alignment.topRight,
        //   child: Transform.translate(
        //     offset: Offset(0, 30),
        //     child: Container(
        //       padding: const EdgeInsets.all(4),
        //       decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.4))),
        //       width: 80,
        //       child: Column(
        //         children: [
        //           Row(
        //             children: [
        //               Container(
        //                 width: 20,
        //                 height: 4,
        //                 color: Colors.purple,
        //               ),
        //               const Spacer(),
        //               const Text("123", style: TextStyle(fontSize: 10)),
        //             ],
        //           ),
        //           Row(
        //             children: [
        //               Container(
        //                 width: 20,
        //                 height: 4,
        //                 color: Colors.blue,
        //               ),
        //               const Spacer(),
        //               const Text("123", style: TextStyle(fontSize: 10)),
        //             ],
        //           ),
        //           Row(
        //             children: [
        //               Container(
        //                 width: 20,
        //                 height: 4,
        //                 color: Colors.green,
        //               ),
        //               const Spacer(),
        //               const Text("123", style: TextStyle(fontSize: 10)),
        //             ],
        //           ),
        //           Row(
        //             children: [
        //               Container(
        //                 width: 20,
        //                 height: 4,
        //                 color: Colors.orange,
        //               ),
        //               const Spacer(),
        //               const Text("123", style: TextStyle(fontSize: 10)),
        //             ],
        //           ),
        //           Row(
        //             children: [
        //               Container(
        //                 width: 20,
        //                 height: 4,
        //                 color: Colors.red,
        //               ),
        //               const Spacer(),
        //               const Text("123", style: TextStyle(fontSize: 10)),
        //             ],
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // )
      ],
    );
  }
}