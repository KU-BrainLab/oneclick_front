import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:omnifit_front/models/survey_model.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/sleep_result/general_summary_widget.dart';
import 'package:omnifit_front/widget/custom_data_table.dart' as custom;
import 'package:syncfusion_flutter_charts/charts.dart';


class SleepResult extends StatefulWidget {
  final UserModel user;
  static const route = '/sleepresult';
  const SleepResult({super.key, required this.user});

  @override
  State<SleepResult> createState() => _SleepResultState();
}

class _SleepResultState extends State<SleepResult> {

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

      // TODO: JSON Decomposition

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
      return Scaffold(     backgroundColor: Colors.white,body: Container());
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
                  Header(headText: "여기에다 만들거임", userModel: widget.user),
                    const SizedBox(height: 20), // Header 위젯과의 간격
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0), // 좌우 여백
                      child: GeneralSummaryWidget(),
                    ),
                    const SizedBox(height: 40), // 하단 추가 간격
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