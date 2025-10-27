import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:omnifit_front/models/survey_model.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/custom_data_table.dart' as custom;
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportPage3 extends StatefulWidget {
  final UserModel user;
  static const route = '/report3';
  const ReportPage3({super.key, required this.user});

  @override
  State<ReportPage3> createState() => _ReportPage3State();
}

class _ReportPage3State extends State<ReportPage3> {
  bool isLoading = true;
  List<SurveyModel> list = [];
  List<SalesData> irlsList = [];
  List<SalesData> psqlkList = [];
  List<SalesData> isiList = [];
  List<SalesData> essList = [];
  List<SalesData> compass31List = [];
  List<SalesData> baiList = [];
  List<SalesData> bdi2List = [];

  TextStyle bumraeStyle = const TextStyle(fontSize: 11, color: Colors.black);

  @override
  void initState() {
    super.initState();
    callHttp();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void callHttp() async {
    final url = Uri.parse(
        '${BASE_URL}api/v1/survey/?name=${widget.user.name}&sex=${widget.user.sex}&birth=${widget.user.birth}&age=${widget.user.age}');
    final response = await http.get(url, headers: {
      'Authorization': 'JWT ${AppService.instance.currentUser?.id}',
    });

    if (response.statusCode == 200) {
      List<dynamic> valueList = jsonDecode(utf8.decode(response.bodyBytes));

      list.clear();
      irlsList.clear();
      psqlkList.clear();
      isiList.clear();
      essList.clear();
      compass31List.clear();
      baiList.clear();
      bdi2List.clear();

      for (Map<String, dynamic> value in valueList.reversed) {
        SurveyModel surveyModel = SurveyModel.fromJson(value);
        list.add(surveyModel);

        if (surveyModel.questionnaire.irls != null) {
          irlsList.add(SalesData(
              DateFormat("yy.MM.dd").format(surveyModel.measuementDate!),
              double.parse(surveyModel.questionnaire.irls!)));
        }
        if (surveyModel.questionnaire.psql != null) {
          psqlkList.add(SalesData(
              DateFormat("yy.MM.dd").format(surveyModel.measuementDate!),
              double.parse(surveyModel.questionnaire.psql!)));
        }
        if (surveyModel.questionnaire.isi != null) {
          isiList.add(SalesData(
              DateFormat("yy.MM.dd").format(surveyModel.measuementDate!),
              double.parse(surveyModel.questionnaire.isi!)));
        }
        if (surveyModel.questionnaire.ess != null) {
          essList.add(SalesData(
              DateFormat("yy.MM.dd").format(surveyModel.measuementDate!),
              double.parse(surveyModel.questionnaire.ess!)));
        }
        if (surveyModel.questionnaire.compass31 != null) {
          double ori = double.parse(surveyModel.questionnaire.compass31!);
          double tmp = (ori * 100).round() / 100.0;
          compass31List.add(SalesData(
              DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), tmp));
        }
        if (surveyModel.questionnaire.bai != null) {
          baiList.add(SalesData(
              DateFormat("yy.MM.dd").format(surveyModel.measuementDate!),
              double.parse(surveyModel.questionnaire.bai!)));
        }
        if (surveyModel.questionnaire.bdi2 != null) {
          bdi2List.add(SalesData(
              DateFormat("yy.MM.dd").format(surveyModel.measuementDate!),
              double.parse(surveyModel.questionnaire.bdi2!)));
        }
      }

      isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          side:
                              const BorderSide(width: 2, color: Colors.green),
                          foregroundColor:
                              const Color.fromARGB(255, 137, 146, 138),
                          backgroundColor: Colors.green,
                          elevation: 10.0,
                        ),
                        onPressed: AppService.instance.manageBack,
                        child: const Text(
                          "뒤로가기",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          side:
                              const BorderSide(width: 2, color: Colors.green),
                          foregroundColor: Colors.green,
                          backgroundColor: Colors.green,
                          elevation: 10.0,
                        ),
                        onPressed: AppService.instance.managePdfDistribution,
                        child: const Text(
                          "PDF 배포",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // === 캡처/배포 대상 영역 ===
                RepaintBoundary(
                  key: AppService.instance.screenKey,
                  child: Column(
                    children: [
                        Row(
                          children: [
                            Text(
                              "${DateFormat('yyyy.MM.dd').format(widget.user.measurement_date)} ${widget.user.name} 피험자 실험 결과 - Questionnaire",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20),
                            ),
                            const Spacer(),
                            Center(
                                child: svgIcon(Assets.img.icon_logo,
                                    width: 60, height: 30)),
                            const SizedBox(width: 10),
                            Transform.translate(
                              offset: const Offset(0, -3),
                              child: Image.asset("assets/logo1.png",
                                  width: 130, height: 55),
                            ),
                          ],
                        ),


                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            Column(
                              children: [
                                if (irlsList.isNotEmpty)
                                  _buildChart("IRLS", irlsList, 35, [
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xff6db290)
                                            .withAlpha(102),
                                        start: -1,
                                        end: 10),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF44948f)
                                            .withAlpha(102),
                                        start: 10,
                                        end: 14),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF24768b)
                                            .withAlpha(102),
                                        start: 14,
                                        end: 20),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF215584)
                                            .withAlpha(102),
                                        start: 20,
                                        end: 36),
                                  ]),
                                  const SizedBox(height: 20),
                                if (psqlkList.isNotEmpty)
                                  _buildChart("PSQI-K", psqlkList, 25, [
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xff6db290)
                                            .withAlpha(102),
                                        start: -1,
                                        end: 8),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF44948f)
                                            .withAlpha(102),
                                        start: 8,
                                        end: 26),
                                  ]),
                                if (isiList.isNotEmpty)
                                  _buildChart("ISI", isiList, 35, [
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xff6db290)
                                            .withAlpha(102),
                                        start: -1,
                                        end: 7),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF44948f)
                                            .withAlpha(102),
                                        start: 7,
                                        end: 15),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF24768b)
                                            .withAlpha(102),
                                        start: 15,
                                        end: 36),
                                  ]),
                                 const SizedBox(height: 20),

                                if (essList.isNotEmpty)
                                  _buildChart("ESS", essList, 30, [
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xff6db290)
                                            .withAlpha(102),
                                        start: -1,
                                        end: 9),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF44948f)
                                            .withAlpha(102),
                                        start: 9,
                                        end: 31),
                                  ]),
                                if (compass31List.isNotEmpty)
                                  _buildChart(
                                      "COMPASS 31", compass31List, 100, []),
                                if (baiList.isNotEmpty)
                                  _buildChart("BAI", baiList, 70, [
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xff6db290)
                                            .withAlpha(102),
                                        start: -1,
                                        end: 9),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF44948f)
                                            .withAlpha(102),
                                        start: 9,
                                        end: 18),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF24768b)
                                            .withAlpha(102),
                                        start: 18,
                                        end: 29),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF215584)
                                            .withAlpha(102),
                                        start: 29,
                                        end: 71),
                                  ]),
                                    const SizedBox(height: 20),

                                if (bdi2List.isNotEmpty)
                                  _buildChart("BDI2", bdi2List, 70, [
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xff6db290)
                                            .withAlpha(102),
                                        start: -1,
                                        end: 13),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF44948f)
                                            .withAlpha(102),
                                        start: 13,
                                        end: 19),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF24768b)
                                            .withAlpha(102),
                                        start: 19,
                                        end: 28),
                                    PlotBand(
                                        isVisible: true,
                                        color: const Color(0xFF215584)
                                            .withAlpha(102),
                                        start: 28,
                                        end: 71),
                                  ]),
                                  const SizedBox(height: 20),
                              ],
                            ),
                          ],
                        ),
                        
                      ),
                        const SizedBox(height: 600),
                    ],
                  ),
                ),
                // === 캡처/배포 영역 끝 ===
              ],
            ),
          ),
        ),
      ),
    );
  }

  NumericAxis _buildPrimaryYAxis(
      String title, double maximum, List<PlotBand> plotBand) {
    if (title == 'COMPASS 31') {
      return NumericAxis(
          maximum: maximum, minimum: 0, interval: 20, plotBands: plotBand);
    } else if (title == 'BAI' || title == 'BDI2') {
      return NumericAxis(
          maximum: maximum, minimum: 0, interval: 10, plotBands: plotBand);
    } else {
      return NumericAxis(
          maximum: maximum, minimum: 0, interval: 5, plotBands: plotBand);
    }
  }

  Widget _buildChart(String title, List<SalesData> list, double maximum,
      List<PlotBand> plotBand) {
    return Container(
      margin: title == 'IRLS'
          ? const EdgeInsets.symmetric(vertical: 0)
          : const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        children: [
          SfCartesianChart(
            primaryXAxis: const CategoryAxis(),
            primaryYAxis: _buildPrimaryYAxis(title, maximum, plotBand),
            title: ChartTitle(text: title),
            legend: const Legend(isVisible: true),
            series: <LineSeries<SalesData, String>>[
              LineSeries<SalesData, String>(
                dataSource: list,
                xValueMapper: (SalesData sales, _) => sales.year,
                yValueMapper: (SalesData sales, _) => sales.sales,
                color: Colors.blueAccent,
                animationDuration: 0,
                isVisibleInLegend: false,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                markerSettings:
                    const MarkerSettings(isVisible: true, color: Colors.blueAccent),
              ),
            ],
          ),
          if (title != 'COMPASS 31')
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(top: 50, right: 15),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: Colors.grey.withOpacity(0.4), width: 1),
                ),
                child: _buildType(title),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildType(String title) {
    if (title == 'IRLS') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(0xff6db290), "경도 (0-10)"),
          _legendRow(const Color(0xFF44948f), "중증도 (11-14)"),
          _legendRow(const Color(0xFF24768b), "중증 (15-20)"),
          _legendRow(const Color(0xFF215584), "최중증 (21-30)"),
        ],
      );
    } else if (title == 'PSQI-K') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(0xff6db290), "수면의 질이 좋은 상태 (0-8)"),
          _legendRow(const Color(0xFF44948f), "수면의 질이 나쁜 상태 (9-21)"),
        ],
      );
    } else if (title == 'ISI') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(0xff6db290),
              "No clinically significant insomnia (0-7)"),
          _legendRow(const Color(0xFF44948f), "Subthreshold insomnia (9-21)"),
          _legendRow(const Color(0xFF24768b),
              "Clinical insomnia (moderate severity) (15-21)"),
        ],
      );
    } else if (title == 'ESS') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(0xff6db290), "정상 (0-9)"),
          _legendRow(const Color(0xFF44948f), "과도한 주간 졸림 (10-24)"),
        ],
      );
    } else if (title == 'BAI') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(0xff6db290), "정상 (0-9)"),
          _legendRow(const Color(0xFF44948f), "경도의 불안 (10-18)"),
          _legendRow(const Color(0xFF24768b), "중증도의 불안 (19-29)"),
          _legendRow(const Color(0xFF215584), "심한 불안 (30-63)"),
        ],
      );
    } else if (title == 'BDI2') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(0xff6db290), "약간의 우울 (0-13)"),
          _legendRow(const Color(0xFF44948f), "경미한 우울 (14-19)"),
          _legendRow(const Color(0xFF24768b), "중증도 우울 (20-28)"),
          _legendRow(const Color(0xFF215584), "심각한 우울 (29-63)"),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _legendRow(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 8, color: color),
        const SizedBox(width: 5),
        Text(text, style: bumraeStyle),
      ],
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
}
