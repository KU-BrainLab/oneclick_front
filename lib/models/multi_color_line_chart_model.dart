import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MultiColorLineChartModel {
  List<ChartData> dataList;
  double intervalX;
  double intervalY;
  double minX;
  double minY;
  double maxX;
  double maxY;

  MultiColorLineChartModel({
    required this.dataList,
    required this.intervalX,
    required this.intervalY,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY
  });

  factory MultiColorLineChartModel.fromJson(List<dynamic> jsonList) {

    List<Color> colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue];
    List<ChartData> dataList = [];
    double minX = 0;
    double minY = 99999;
    double maxX = jsonList.length.toDouble();
    double maxY = 0;
    double intervalX = maxX / 5;

    for(int i = 0; i < maxX; i++) {
      double y = jsonList[i] as double;

      if(y < minY) {
        minY = y;
      }

      if(y > maxY) {
        maxY = y;
      }

      dataList.add(ChartData(i.toDouble(), y, colors[(i / intervalX).floor()]));
    }
    double intervalY = maxY / 6;


    minY -= intervalY;
    maxY += intervalY;


    return MultiColorLineChartModel(
      dataList: dataList,
      intervalX: intervalX,
      intervalY: intervalY,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  @override
  String toString() {
    return "MultiColorLineChartModel : { minX : $minX, maxX : $maxX, minY : $minY, maxY : $maxY, intervalX : $intervalX, intervalY : $intervalY, dataList : ${dataList.length} }";
  }

}

class ChartData {
  ChartData(this.x, this.y, this.lineColor);
  final double x;
  final double y;
  final Color lineColor;
}
