import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/models/general_summary_model.dart';
import 'package:omnifit_front/models/survey_model.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/custom_data_table.dart' as custom;
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/sleep_result/general_summary_widget.dart';

class ReportPage4 extends StatefulWidget {
  final UserModel user;
  static const route = '/report4';
  const ReportPage4({super.key, required this.user});

  @override
  State<ReportPage4> createState() => _SleepResultState();
}

class _SleepResultState extends State<ReportPage4> {
  bool isLoading = true;
  GeneralSummaryModel? summaryData;
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

  void callHttp() async {
    final url = Uri.parse('${BASE_URL}api/v1/report/${widget.user.report}');
    final response = await http.get(url, headers: {
      'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> valuemap =
          jsonDecode(utf8.decode(response.bodyBytes));
      summaryData = GeneralSummaryModel.fromJson(valuemap);

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
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
                          side: const BorderSide(width: 2, color: Colors.green),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                            side: const BorderSide(width: 2, color: Colors.green),
                            foregroundColor: Colors.green,
                            backgroundColor: Colors.green,
                            elevation: 10.0,
                          ),
                          onPressed: () {
                            final fileName =
                                '${DateFormat('yyyyMMdd').format(widget.user.measurement_date)}_${widget.user.name}_NOCTURNAL_POLYSOMNOGRAM.pdf';


                              AppService.instance.managePdfDistribution(
                                fileName: fileName,
                                refreshAfter: true,
                              );                          
                            },
                          child: const Text("PDF 배포", style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),

                // ===== 캡처/배포 대상 영역 시작 =====
                RepaintBoundary(
                  key: AppService.instance.screenKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "${DateFormat('yyyy.MM.dd').format(widget.user.measurement_date)} ${widget.user.name} 피험자 실험 결과 - NOCTURNAL POLYSOMNOGRAM",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          const Spacer(),
                          Center(
                            child: svgIcon(
                              Assets.img.icon_logo,
                              width: 60,
                              height: 30,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Transform.translate(
                            offset: const Offset(0, -3),
                            child: Image.asset(
                              "assets/logo1.png",
                              width: 130,
                              height: 55,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: summaryData == null
                            ? const Center(
                                child: Text(
                                  "데이터를 불러오는데 실패했습니다. (업데이트 이전 검사결과 이거나 EEG 파일 확인 요망)",
                                ),
                              )
                            : GeneralSummaryWidget(data: summaryData!),
                      ),
                      const SizedBox(height: 700),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
}
