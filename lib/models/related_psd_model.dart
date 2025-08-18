import 'package:flutter/material.dart';

class RelatedPsdModel {
  List<double> colorList;

  RelatedPsdModel({
    required this.colorList,
  });

  factory RelatedPsdModel.fromJson(List<dynamic> jsonList) {
    final values = jsonList
        .map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0)
        .toList(growable: false);

    final total = values.fold<double>(0.0, (a, b) => a + b);

    final percentages = total == 0
        ? List<double>.filled(values.length, 0.0)
        : values.map((v) => (v / total) * 100.0).toList(growable: false);

    return RelatedPsdModel(colorList: percentages);
  }
}