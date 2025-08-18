import 'package:flutter/material.dart';
import 'package:omnifit_front/models/graph1_model.dart';

class Page1TabModel {
  double sdnn;
  double rmssd;
  double sdsd;
  double nn50;
  double pnn50;
  double tri_index;
  double vlf_rel_power;
  double lf_rel_power;
  double hf_rel_power;
  double lh_ratio;
  double norm_lf;
  double norm_hf;
  String comparison;
  String heart_rate;
  Graph1Model graph1model;

  Page1TabModel({
    required this.sdnn,
    required this.rmssd,
    required this.sdsd,
    required this.nn50,
    required this.pnn50,
    required this.tri_index,
    required this.vlf_rel_power,
    required this.lf_rel_power,
    required this.hf_rel_power,
    required this.lh_ratio,
    required this.norm_lf,
    required this.norm_hf,
    required this.comparison,
    required this.heart_rate,
    required this.graph1model,
  });

  factory Page1TabModel.fromJson(Map<String, dynamic> json) {

    Graph1Model graph1model = Graph1Model.fromJson3(json['psd']['power']);

    debugPrint("graph1model: $graph1model");

    return Page1TabModel(
      sdnn: json['sdnn'],
      rmssd: json['rmssd'],
      sdsd: json['sdsd'],
      nn50: json['nn50'],
      pnn50: json['pnn50'],
      tri_index: json['tri_index'],
      vlf_rel_power: json['vlf_rel_power'],
      lf_rel_power: json['lf_rel_power'],
      hf_rel_power: json['hf_rel_power'],
      lh_ratio: json['lh_ratio'],
      norm_lf: json['norm_lf'],
      norm_hf: json['norm_hf'],
      comparison: json['comparison'],
      heart_rate: json['heart_rate'],
      graph1model: graph1model,
    );
  }

}