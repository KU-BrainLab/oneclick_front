import 'package:flutter/material.dart';

class RelatedPsdModel {
  List<double> colorList;

  RelatedPsdModel({
    required this.colorList,
  });

  factory RelatedPsdModel.fromJson(List<dynamic> jsonList) {
    List<double> list = [];
    jsonList.forEach((element) {
      list.add((element as double) * 100);
    });
    return RelatedPsdModel(colorList: list);
  }
}