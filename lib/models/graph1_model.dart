import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Graph1Model {
  List<FlSpot> dataList;
  double intervalX;
  double intervalY;
  double minX;
  double minY;
  double maxX;
  double maxY;

  Graph1Model({
    required this.dataList,
    required this.intervalX,
    required this.intervalY,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY
  });

  factory Graph1Model.fromJson(List<dynamic> jsonList) {

    List<FlSpot> dataList = [];
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
      dataList.add(FlSpot(i.toDouble(), y));
    }
    double intervalY = maxY / 6;

    minY -= intervalY;
    if(minY < 0) {
      minY = 0;
    }

    maxY += intervalY;

    return Graph1Model(
      dataList: dataList,
      intervalX: intervalX,
      intervalY: intervalY,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  factory Graph1Model.fromJson2(List<dynamic> jsonList) {


    List<FlSpot> dataList = [];
    double minX = 0;
    double minY = 99999;
    double maxX = jsonList.length.toDouble();
    double maxY = -99999;
    double intervalX = maxX / 5;

    for(int i = 0; i < maxX; i++) {
      double y = jsonList[i] as double;

      if(y < minY) {
        minY = y;
      }

      if(y > maxY) {
        maxY = y;
      }
      dataList.add(FlSpot(i.toDouble()/20, y));
    }
    double intervalY = maxY.abs() / 5;

    // if(minY < 0) {
    //   minY = 0;
    // }

    maxY += 5;
    minY = minY ~/ 5 * 5 - 5;

    return Graph1Model(
      dataList: dataList,
      intervalX: intervalX,
      intervalY: intervalY,
      minX: minX,
      maxX: maxX / 20,
      minY: minY,
      maxY: maxY,
    );
  }

  factory Graph1Model.fromJson3(List<dynamic> jsonList) {

    List<FlSpot> dataList = [];
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
      dataList.add(FlSpot(i.toDouble(), y));
    }
    double intervalY = maxY / 5;

    return Graph1Model(
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
    return "Graph1Model : { minX : $minX, maxX : $maxX, minY : $minY, maxY : $maxY, intervalX : $intervalX, intervalY : $intervalY, dataList : ${dataList.length} }";
  }
}