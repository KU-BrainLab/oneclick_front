import 'package:flutter/material.dart';
import 'package:omnifit_front/models/related_psd_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CircleChartWidget extends StatelessWidget {
  final RelatedPsdModel model;
  CircleChartWidget({Key? key, required this.model}) : super(key: key);

  late List<ChartData> chartData = [
    ChartData('Delta', model.colorList[0], const Color(0xFFBEE9E8)),
    ChartData('Theta', model.colorList[1], const Color(0xFF62B6CB)),
    ChartData('Alpha', model.colorList[2], const Color(0xFF1B4965)),
    ChartData('Beta', model.colorList[3], const Color(0xFFCAE9FF)),
    ChartData('Gamma', model.colorList[4], const Color(0xFF5FA8D3)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black)
      ),
      child: Center(
          child: SfCircularChart(
            title: ChartTitle(text: "Related PSD"),
            legend: const Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap, toggleSeriesVisibility: false,
            position: LegendPosition.bottom,
              textStyle: TextStyle(fontSize: 12),
            ),
              series: <CircularSeries>[
                DoughnutSeries<ChartData, String>(
                    dataLabelSettings: DataLabelSettings(isVisible: true,
                    builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                         return Text("${data.y.toStringAsFixed(2)}%", style: TextStyle(color: pointIndex == 2 ? Colors.white : Colors.black, fontSize: 10));
                       }
                    ),
                    animationDuration: 0,
                    dataSource: chartData,
                    pointColorMapper:(ChartData data,  _) => data.color,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                  legendIconType: LegendIconType.rectangle,
                )
              ]
          )
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}