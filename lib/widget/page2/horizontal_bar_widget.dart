import 'package:flutter/material.dart';
import 'package:omnifit_front/models/region_psd_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HorizontalBarWidget extends StatelessWidget {
  final RegionPsdModel model;
  HorizontalBarWidget({Key? key, required this.model}): super(key: key);


  late List<_ChartData> left = [
  _ChartData('delta', model.left[4], const Color(0xFF5FA8D3)),
  _ChartData('theta', model.left[3], const Color(0xFFCAE9FF)),
  _ChartData('alpha', model.left[2], const Color(0xFF1B4965)),
  _ChartData('beta', model.left[1], const Color(0xFF62B6CB)),
  _ChartData('gamma', model.left[0], const Color(0xFFBEE9E8)),
  ];

  late List<_ChartData> right = [
    _ChartData('delta', model.right[4], const Color(0xFF5FA8D3)),
    _ChartData('theta', model.right[3], const Color(0xFFCAE9FF)),
    _ChartData('alpha', model.right[2], const Color(0xFF1B4965)),
    _ChartData('beta', model.right[1], const Color(0xFF62B6CB)),
    _ChartData('gamma', model.right[0], const Color(0xFFBEE9E8)),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 300,
          child: SfCartesianChart(
              title: const ChartTitle(text: "Left", alignment: ChartAlignment.near),
              primaryXAxis: const CategoryAxis(isVisible: false, opposedPosition: true),
              primaryYAxis: NumericAxis(minimum: 0, maximum: model.max + 2*(model.interval), interval: model.interval, isInversed: true,
                axisLabelFormatter: (AxisLabelRenderDetails args) {
                  return ChartAxisLabel('${double.parse(args.text).toInt()}', null);
                },
              ),
              series: <CartesianSeries<_ChartData, String>>[
                BarSeries<_ChartData, String>(
                    dataSource: left,
                    width:1,
                    xValueMapper: (_ChartData data, _) => data.x,
                    yValueMapper: (_ChartData data, _) => data.y,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    animationDuration: 0,
                    dataLabelSettings: DataLabelSettings(isVisible: true,
                        builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                          return Transform.translate(offset: Offset(-15, -5),
                              child: Text("${data.y.toStringAsFixed(2)}"));
                        },
                      alignment: ChartAlignment.far
                    ),
                )
              ]),
        ),
        const SizedBox(
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: 57),
              Text("delta"),
              SizedBox(height: 25.5),
              Text("theta"),
              SizedBox(height: 25.5),
              Text("alpha"),
              SizedBox(height: 25),
              Text("beta"),
              SizedBox(height: 25),
              Text("gamma"),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: SfCartesianChart(
              enableAxisAnimation: false,
              title: const ChartTitle(text: "Right", alignment: ChartAlignment.far),
              primaryXAxis: const CategoryAxis(isVisible: false, opposedPosition: false),
              primaryYAxis: NumericAxis(minimum: 0, maximum: model.max + 2*(model.interval), interval: model.interval,
                axisLabelFormatter: (AxisLabelRenderDetails args) {
                  return ChartAxisLabel('${double.parse(args.text).toInt()}', null);
                },
              ),
              series: <CartesianSeries<_ChartData, String>>[
                BarSeries<_ChartData, String>(
                    dataSource: right,
                    width:1,
                    xValueMapper: (_ChartData data, _) => data.x,
                    yValueMapper: (_ChartData data, _) => data.y,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    animationDuration: 0,
                  dataLabelSettings: DataLabelSettings(isVisible: true,
                      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                         return Transform.translate(
                           offset: const Offset(30, -5),

                             child: Text("${data.y.toStringAsFixed(2)}"));
                       },
                      alignment: ChartAlignment.far,
                  ),
                )
              ]),
        ),
      ],
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y, this.color);

  final String x;
  final double y;
  final Color color;
}