import 'package:flutter/material.dart';

class SurveyModel {

  DateTime? measuementDate;
  int? pk;
  Questionnaire questionnaire;

  SurveyModel({
    required this.measuementDate,
    required this.pk,
    required this.questionnaire,
  });

  factory SurveyModel.fromJson(dynamic json) {

    late Questionnaire questionnaire;
    if(json['questionnaire'] != null) {
      questionnaire = Questionnaire.fromJson(json['questionnaire']);
    } else {
      questionnaire = Questionnaire();
    }

    return SurveyModel(
      measuementDate: DateTime.parse(json['measurement_date']),
      pk: json['pk'],
      questionnaire: questionnaire,
    );
  }

}

class Questionnaire {
  String? bai;
  String? bdi2;
  String? compass31;
  String? ess;
  String? irls;
  String? isi;
  String? psql;

  Questionnaire({
    this.bai,
    this.bdi2,
    this.compass31,
    this.ess,
    this.irls,
    this.isi,
    this.psql,
  });

  factory Questionnaire.fromJson(dynamic json) {

    debugPrint("json : $json");

    return Questionnaire(
      bai: json['bai'] != null ? "${json['bai']}" : null,
      bdi2: json['bdi2'] != null ? "${json['bdi2']}" : null,
      compass31: json['compass31'] != null ? "${json['compass31']}" : null,
      ess: json['ess'] != null ? "${json['ess']}" : null,
      irls: json['irls'] != null ? "${json['irls']}" : null,
      isi: json['isi'] != null ? "${json['isi']}" : null,
      psql: json['psql'] != null ? "${json['psql']}" : null,
    );
  }

  Map<String, String> toJson() {

    Map<String, String> json = {};

    if(bai != null) json.putIfAbsent("bai", () => "$bai");
    if(bdi2 != null) json.putIfAbsent("bdi2", () => "$bdi2");
    if(compass31 != null) json.putIfAbsent("compass31", () => "$compass31");
    if(irls != null) json.putIfAbsent("irls", () => "$irls");
    if(ess != null) json.putIfAbsent("ess", () => "$ess");
    if(isi != null) json.putIfAbsent("isi", () => "$isi");
    if(psql != null) json.putIfAbsent("psql", () => "$psql");

    return json;
  }
}