import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:omnifit_front/models/survey_model.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/custom_data_table.dart' as custom;
import 'package:syncfusion_flutter_charts/charts.dart';

class SurveyPage extends StatefulWidget {
  final UserModel user;
  static const route = '/survey';
  const SurveyPage({super.key, required this.user});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {

  bool isLoading = true;
  List<SurveyModel> list = [];
  List<SalesData> irlsList = [];
  List<SalesData> psqlkList = [];
  List<SalesData> isiList = [];
  List<SalesData> essList = [];
  List<SalesData> compass31List = [];
  List<SalesData> baiList = [];
  List<SalesData> bdi2List = [];

  TextStyle bumraeStyle = TextStyle(fontSize: 11, color: Colors.black);

  @override
  void initState() {
    super.initState();
    callHttp();
  }

  void callHttp() async {
    final url = Uri.parse('${BASE_URL}api/v1/survey/?name=${widget.user.name}&sex=${widget.user.sex}&birth=${widget.user.birth}&age=${widget.user.age}');
    final response = await http.get(url, headers: {
      'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
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
      for(Map<String, dynamic> value in valueList.reversed) {
        SurveyModel surveyModel = SurveyModel.fromJson(value);
        list.add(surveyModel);

        if(surveyModel.questionnaire.irls != null) irlsList.add(SalesData(DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), double.parse(surveyModel.questionnaire.irls!)));
        if(surveyModel.questionnaire.psql != null) psqlkList.add(SalesData(DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), double.parse(surveyModel.questionnaire.psql!)));
        if(surveyModel.questionnaire.isi != null) isiList.add(SalesData(DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), double.parse(surveyModel.questionnaire.isi!)));
        if(surveyModel.questionnaire.ess != null) essList.add(SalesData(DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), double.parse(surveyModel.questionnaire.ess!)));
        if(surveyModel.questionnaire.compass31 != null) compass31List.add(SalesData(DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), double.parse(surveyModel.questionnaire.compass31!)));
        if(surveyModel.questionnaire.bai != null) baiList.add(SalesData(DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), double.parse(surveyModel.questionnaire.bai!)));
        if(surveyModel.questionnaire.bdi2 != null) bdi2List.add(SalesData(DateFormat("yy.MM.dd").format(surveyModel.measuementDate!), double.parse(surveyModel.questionnaire.bdi2!)));

      }

      isLoading = false;
      setState(() {});
    }
  }

  void saveHttp(int pk, Questionnaire dto) async {
    final url = Uri.parse('${BASE_URL}api/v1/survey/questionnaire/$pk/');
    final response = await http.post(url, headers: {
      'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
    }, body: dto.toJson());

    debugPrint("response $response");
    if (response.statusCode == 200) {
      callHttp();

    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(backgroundColor: Colors.white,body: Container());
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
                  Row(
                    children: [
                      const Spacer(),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            side: const BorderSide(width: 2, color: Colors.green),
                            foregroundColor: Colors.green, backgroundColor: Colors.green,
                            elevation: 10.0,
                          ),
                          onPressed: AppService.instance.manageAutoLogout,
                          child: const Text("로그아웃", style: TextStyle(color: Colors.white),)),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Header(headText: "${widget.user.name} 설문지", userModel: widget.user),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [

                        Column(
                          children: [
                            if(irlsList.isNotEmpty) _buildChart("IRLS", irlsList, 35, [
                              PlotBand(isVisible:true,color: Color(0xff6db290).withAlpha(102), start: -1, end: 10),
                              PlotBand(isVisible:true,color: Color(0xFF44948f).withAlpha(102), start: 10, end: 14),
                              PlotBand(isVisible:true,color: Color(0xFF24768b).withAlpha(102), start: 14, end: 20),
                              PlotBand(isVisible:true,color: Color(0xFF215584).withAlpha(102), start: 20, end: 36),
                            ],),
                            if(psqlkList.isNotEmpty) _buildChart("PSQI-K", psqlkList, 25, [
                              PlotBand(isVisible:true,color: Color(0xff6db290).withAlpha(102), start: -1, end: 8),
                              PlotBand(isVisible:true,color: Color(0xFF44948f).withAlpha(102), start: 8, end: 26),
                            ]),
                            if(isiList.isNotEmpty) _buildChart("ISI", isiList, 35, [
                              PlotBand(isVisible:true,color: Color(0xff6db290).withAlpha(102), start: -1, end: 7),
                              PlotBand(isVisible:true,color: Color(0xFF44948f).withAlpha(102), start: 7, end: 15),
                              PlotBand(isVisible:true,color: Color(0xFF24768b).withAlpha(102), start:15, end: 36),
                            ]),
                            if(essList.isNotEmpty) _buildChart("ESS", essList, 30, [
                              PlotBand(isVisible:true,color: Color(0xff6db290).withAlpha(102), start: -1, end: 9),
                              PlotBand(isVisible:true,color: Color(0xFF44948f).withAlpha(102), start: 9, end: 31),
                            ]),
                            if(compass31List.isNotEmpty) _buildChart("COMPASS 31", compass31List, 100, []),
                            if(baiList.isNotEmpty) _buildChart("BAI", baiList, 70, [
                              PlotBand(isVisible:true,color: Color(0xff6db290).withAlpha(102), start: -1, end: 9),
                              PlotBand(isVisible:true,color: Color(0xFF44948f).withAlpha(102), start: 9, end: 18),
                              PlotBand(isVisible:true,color: Color(0xFF24768b).withAlpha(102), start: 18, end: 29),
                              PlotBand(isVisible:true,color: Color(0xFF215584).withAlpha(102), start: 29, end: 71),
                            ]),
                            if(bdi2List.isNotEmpty) _buildChart("BDI2", bdi2List, 70, [
                              PlotBand(isVisible:true,color: Color(0xff6db290).withAlpha(102), start: -1, end: 13),
                              PlotBand(isVisible:true,color: Color(0xFF44948f).withAlpha(102), start: 13, end: 19),
                              PlotBand(isVisible:true,color: Color(0xFF24768b).withAlpha(102), start: 19, end: 28),
                              PlotBand(isVisible:true,color: Color(0xFF215584).withAlpha(102), start: 28, end: 71),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 50),
                        custom.CustomDataTable(
                            columns: const <custom.DataColumn>[
                              custom.DataColumn(
                                  label: Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        '',
                                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),),
                              custom.DataColumn(
                                  label: Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'IRLS',
                                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),),
                              custom.DataColumn(
                                  label: Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'PSQI-K',
                                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )),
                              custom.DataColumn(
                                  label: Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'ISI',
                                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )),
                              custom.DataColumn(
                                  label: Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'ESS',
                                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),),
                              custom.DataColumn(
                                label: Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'COMPASS31',
                                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              custom.DataColumn(
                                label: Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'BAI',
                                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              custom.DataColumn(
                                label: Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'BDI2',
                                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, fontWeight: FontWeight.w700),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            rows: list
                                .map((e) => custom.DataRow(cells: [
                              custom.DataCell(
                                Align(alignment: Alignment.center, child: Text(DateFormat('yyyy.MM.dd').format(e.measuementDate!), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12),)),
                              ),
                              custom.DataCell(Align(alignment: Alignment.center, child: TextFormField(
                                style: TextStyle( fontSize: 12),
                                initialValue: e.questionnaire.irls ?? "",
                                onChanged: (str) {
                                  e.questionnaire.irls = str;
                                },
                              )
                              )),
                              custom.DataCell(Align(alignment: Alignment.center, child: TextFormField(
                                style: TextStyle( fontSize: 12),
                                initialValue: e.questionnaire.psql ?? "",
                                onChanged: (str) {
                                  e.questionnaire.psql = str;
                                },
                              )
                              )),
                              custom.DataCell(Align(alignment: Alignment.center, child: TextFormField(
                                style: TextStyle( fontSize: 12),
                                initialValue: e.questionnaire.isi ?? "",
                                onChanged: (str) {

                                  e.questionnaire.isi = str;
                                },
                              )
                              )),
                              custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    style: TextStyle( fontSize: 12),
                                    initialValue: e.questionnaire.ess ?? "",
                                    onChanged: (str) {
                                      e.questionnaire.ess = str;
                                    },
                                  )

                                  // Text(
                                  //   "${e.questionnaire?.ess}",
                                  //   textAlign: TextAlign.center,
                                  // )
                              )),
                              custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    style: const TextStyle( fontSize: 12),
                                    initialValue: e.questionnaire.compass31 ?? "",
                                    onChanged: (str) {

                                      e.questionnaire.compass31 = str;
                                    },
                                  )
                              )),
                              custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    style: const TextStyle( fontSize: 12),
                                    initialValue: e.questionnaire.bai ?? "",
                                    onChanged: (str) {
                                      e.questionnaire.bai = str;
                                    },
                                  )

                              )),
                              custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    style: const TextStyle( fontSize: 12),
                                    initialValue: e.questionnaire.bdi2 ?? "",
                                    onChanged: (str) {

                                      e.questionnaire.bdi2 = str;
                                    },
                                  )
                              )),
                            ]))
                                .toList()),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                  side: const BorderSide(width: 2, color: Colors.green),
                                  foregroundColor: Colors.green, backgroundColor: Colors.green,
                                  elevation: 10.0,
                                ),
                                onPressed: () {

                                  for(int i = 0; i < list.length; i++) {
                                    SurveyModel model = list[i];
                                    saveHttp(model.pk!, model.questionnaire);
                                  }
                                },
                                child: const Text("입력", style: TextStyle(color: Colors.white),)),
                          ],
                        ),

                      ]
                    ),
                  ),
                ],
              ),
            ),
          )
      ),
    );
  }

  Widget _buildChart(String title, List<SalesData> list, double maximum, List<PlotBand> plotBand) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        children: [
          SfCartesianChart(
              primaryXAxis: const CategoryAxis(),
              primaryYAxis: NumericAxis(maximum: maximum, minimum: 0, interval: 5, plotBands: plotBand),
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
                    markerSettings: MarkerSettings(
                        isVisible: true,
                      color: Colors.blueAccent
                    )
                )
              ]
          ),
          if(title != 'COMPASS 31')
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.only(top: 50, right: 15),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1)
              ),
              child: _buildType(title)))
        ],
      ),
    );
  }

  Widget _buildType(String title) {

    if(title == 'IRLS') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // '#FFFFCC', '#A1DAB4', '#41B6C4', '#225EA8'
              Container(
                width: 14,
                height: 8,
                color: const Color(0xff6db290),
              ),
              const SizedBox(width: 5),
              Text("경도 (0-10)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF44948f),
              ),
              const SizedBox(width: 5),
              Text("중증도 (11-14)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF24768b),
              ),
              const SizedBox(width: 5),
              Text("중증 (15-20)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF215584),
              ),
              const SizedBox(width: 5),
              Text("최중증 (21-30)", style: bumraeStyle),
            ],
          ),
        ],
      );
    } else if(title == 'PSQI-K') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: const Color(0xff6db290),
              ),
              const SizedBox(width: 5),
              Text("수면의 질이 좋은 상태 (0-8)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF44948f),
              ),
              const SizedBox(width: 5),
              Text("수면의 질이 나쁜 상태 (9-21)", style: bumraeStyle),
            ],
          ),
        ],
      );
    } else if(title == 'ISI') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: const Color(0xff6db290),
              ),
              const SizedBox(width: 5),
              Text("No clinically significant insomnia (0-7)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF44948f),
              ),
              const SizedBox(width: 5),
              Text("Subthreshold insomnia (9-21)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF24768b),
              ),
              const SizedBox(width: 5),
              Text("Clinical insomnia (moderate severity) (15-21)", style: bumraeStyle),
            ],
          ),
        ],
      );
    } else if(title == 'ESS') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: const Color(0xff6db290),
              ),
              const SizedBox(width: 5),
              Text("정상 (0-9)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF44948f),
              ),
              const SizedBox(width: 5),
              Text("과도한 주간 졸림 (10-24)", style: bumraeStyle),
            ],
          ),
        ],
      );
    } else if(title == 'BAI') {
      return  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: const Color(0xff6db290),
              ),
              const SizedBox(width: 5),
              Text("정상 (0-9)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF44948f),
              ),
              const SizedBox(width: 5),
              Text("경도의 불안 (10-18)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF24768b),
              ),
              const SizedBox(width: 5),
              Text("중증도의 불안 (19-29)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF215584),
              ),
              const SizedBox(width: 5),
              Text("심한 불안 (30-63)", style: bumraeStyle),
            ],
          ),
        ],
      );
    } else if(title == 'BDI2') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: const Color(0xff6db290),
              ),
              const SizedBox(width: 5),
              Text("약간의 우울 (0-13)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF44948f),
              ),
              const SizedBox(width: 5),
              Text("경미한 우울 (14-19)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF24768b),
              ),
              const SizedBox(width: 5),
              Text("중증도 우울 (20-28)", style: bumraeStyle),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 8,
                color: Color(0xFF215584),
              ),
              const SizedBox(width: 5),
              Text("심각한 우울 (29-63)", style: bumraeStyle),
            ],
          ),
        ],
      );
    }

    return Container();
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
}