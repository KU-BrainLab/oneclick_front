import 'package:flutter/material.dart';

class MultiColorLineChartModel {
  List<ChartData> dataList;
  List<double> intervalX;
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

  factory MultiColorLineChartModel.fromJson(List<dynamic> actualDataList, {required double finalAxisMaxX, required List<double> intervals}) {
    if (actualDataList.isEmpty) {
      return MultiColorLineChartModel(dataList: [], intervalX: [], intervalY: 1, minX: 0, maxX: finalAxisMaxX, minY: 0, maxY: 1);
    }

    List<Color> colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue];
    List<ChartData> dataList = [];
    
    double overallMinY = 99999;
    double overallMaxY = -99999;

    // Trigger 정보가 없으면 finalAxisMaxX 기준 5등분
    List<double> effectiveIntervals = intervals;
    if (effectiveIntervals.length < 2) {
      effectiveIntervals = List.generate(6, (i) => finalAxisMaxX * i / 5);
    }
    
    double maxX = effectiveIntervals.last;

    // 세그먼트 수 (intervals 경계 사이 구간)
    int numSegments = effectiveIntervals.length - 1;
    int totalPoints = actualDataList.length;
    int baseCount = totalPoints ~/ numSegments;
    int remainder = totalPoints % numSegments;

    int dataIndex = 0;
    for (int s = 0; s < numSegments; s++) {
      // 앞쪽 세그먼트에 나머지 포인트를 1개씩 추가 분배
      int segmentCount = baseCount + (s < remainder ? 1 : 0);
      double segStart = effectiveIntervals[s];
      double segEnd = effectiveIntervals[s + 1];
      Color color = colors[s % colors.length];

      for (int j = 0; j < segmentCount; j++) {
        double y = (actualDataList[dataIndex] as num).toDouble();
        double x = segmentCount > 1
            ? segStart + (segEnd - segStart) * j / (segmentCount - 1)
            : segStart;

        if (y < overallMinY) overallMinY = y;
        if (y > overallMaxY) overallMaxY = y;

        dataList.add(ChartData(x, y, color));
        dataIndex++;
      }
    }

    double intervalY = (overallMaxY > overallMinY) ? (overallMaxY - overallMinY) / 5.0 : 1;
    if (intervalY == 0) intervalY = 1;

    overallMinY -= intervalY;
    overallMaxY += intervalY;

    return MultiColorLineChartModel(
      dataList: dataList,
      intervalX: effectiveIntervals,
      intervalY: intervalY,
      minX: 0.0,
      maxX: maxX,
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