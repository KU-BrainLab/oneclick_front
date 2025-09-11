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

  factory MultiColorLineChartModel.fromJson(List<dynamic> actualDataList, {required int totalDurationInSeconds}) {
    if (actualDataList.isEmpty) {
      return MultiColorLineChartModel(dataList: [], intervalX: 1, intervalY: 1, minX: 0, maxX: 1, minY: 0, maxY: 1);
    }
    if (actualDataList.length == 1) {
      double yValue = (actualDataList[0] as num).toDouble();
      return MultiColorLineChartModel(dataList: [ChartData(0, yValue, Colors.red)], intervalX: 1, intervalY: 1, minX: 0, maxX: 1, minY: yValue - 1, maxY: yValue + 1);
    }

    List<Color> colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue];
    List<ChartData> stretchedDataList = [];
    
    double overallMinY = 99999;
    double overallMaxY = -99999;

    double maxXInMinutes = totalDurationInSeconds / 60.0;
    
    double spacing = maxXInMinutes / (actualDataList.length - 1);

    for (int i = 0; i < actualDataList.length; i++) {
      double y = (actualDataList[i] as num).toDouble();
      
      double newX = i * spacing;

      if (y < overallMinY) overallMinY = y;
      if (y > overallMaxY) overallMaxY = y;

      int colorIndex = (newX / maxXInMinutes * colors.length).floor();
      stretchedDataList.add(ChartData(newX, y, colors[colorIndex % colors.length]));
    }

    double intervalY = (overallMaxY > overallMinY) ? (overallMaxY - overallMinY) / 5.0 : 1;
    if (intervalY == 0) intervalY = 1;

    overallMinY -= intervalY;
    overallMaxY += intervalY;

    return MultiColorLineChartModel(
      dataList: stretchedDataList,
      intervalX: maxXInMinutes / 5.0,
      intervalY: intervalY,
      minX: 0.0,
      maxX: maxXInMinutes,
      minY: overallMinY,
      maxY: overallMaxY,
    );
  }
}

class ChartData {
  ChartData(this.x, this.y, this.lineColor);
  final double x;
  final double y;
  final Color lineColor;
}