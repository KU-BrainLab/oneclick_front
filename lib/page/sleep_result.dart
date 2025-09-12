import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/models/general_summary_model.dart';
import 'package:omnifit_front/models/survey_model.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/custom_data_table.dart' as custom;
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/sleep_result/general_summary_widget.dart';

class SleepResult extends StatefulWidget {
  final UserModel user;
  static const route = '/sleepresult';
  const SleepResult({super.key, required this.user});

  @override
  State<SleepResult> createState() => _SleepResultState();
}

class _SleepResultState extends State<SleepResult> {
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

  TextStyle bumraeStyle = TextStyle(fontSize: 11, color: Colors.black);

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
      Map<String, dynamic> valuemap = jsonDecode(utf8.decode(response.bodyBytes));
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
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
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
                          foregroundColor: Colors.green, backgroundColor: Colors.green,
                          elevation: 10.0,
                        ),
                        onPressed: AppService.instance.manageBack,
                        child: const Text("뒤로가기", style: TextStyle(color: Colors.white),),
                      ),
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
                        child: const Text("로그아웃", style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ),
                  Header(headText: "NOCTURNAL POLYSOMNOGRAM RESULTS", userModel: widget.user),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: summaryData == null
                        ? const Center(child: Text("데이터를 불러오는데 실패했습니다. (업데이트 이전 검사결과)"))
                        : GeneralSummaryWidget(data: summaryData!),
                    ),
                    const SizedBox(height: 40),
                  ],
              ),
            ),
          )
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
}