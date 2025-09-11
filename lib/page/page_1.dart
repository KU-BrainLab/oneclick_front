import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/models/graph1_model.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:omnifit_front/models/page1_tab_model.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/page1/graph1.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/page1/multi_color_line_chart_widget.dart';
import 'package:omnifit_front/widget/page1/page1_tab1.dart';

class Page1 extends StatefulWidget {
  final UserModel user;
  static const route = '/ecg/hrv';

  const Page1({Key? key, required this.user}) : super(key: key);

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with SingleTickerProviderStateMixin {
  Graph1Model? graph1model;
  MultiColorLineChartModel? multiColorLineChartModel;
  List<Page1TabModel> page1TabModelList = [];
  TextEditingController textEditingController = TextEditingController();

  bool isLoading = true;
  int index = 0;

  late TabController tabController = TabController(length: 5, vsync: this, initialIndex: 0, animationDuration: const Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
    callHttp();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void callHttp() async {
    final url = Uri.parse('${BASE_URL}api/v1/ecg/hrv/${widget.user.hrv}');
    final response = await http.get(url, headers: {
      'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
    });

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      Map<String, dynamic> valueMap;

      if (responseData is List && responseData.isNotEmpty) {
        valueMap = responseData[0];
      } else if (responseData is Map) {
        valueMap = responseData as Map<String, dynamic>;
      } else {
        setState(() { isLoading = false; });
        return;
      }

      final nniData = valueMap['nni'] as List<dynamic>? ?? [];
      final rmssdData = valueMap['rmssd'] as List<dynamic>? ?? [];

      graph1model = Graph1Model.fromJson(nniData);
      
      multiColorLineChartModel = MultiColorLineChartModel.fromJson(
        rmssdData,
        totalDurationInSeconds: nniData.length,
      );

      page1TabModelList.add(Page1TabModel.fromJson(valueMap['baseline']));
      page1TabModelList.add(Page1TabModel.fromJson(valueMap['stimulation1']));
      page1TabModelList.add(Page1TabModel.fromJson(valueMap['recovery1']));
      page1TabModelList.add(Page1TabModel.fromJson(valueMap['stimulation2']));
      page1TabModelList.add(Page1TabModel.fromJson(valueMap['recovery2']));

      textEditingController.text = valueMap['note'] ?? "";
    }

    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
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
                const SizedBox(height: 20),
                Header(headText: "HRV(Heart Rate Variability) 결과서", userModel: widget.user),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (graph1model != null && multiColorLineChartModel != null) ...[
                        Graph1(
                          graph1model: graph1model!,
                        ),
                        const SizedBox(height: 40),
                        MultiColorLineChartWidget(
                          model: multiColorLineChartModel!,
                          maxX: graph1model!.maxX.ceil().toDouble(),
                        ),
                      ],
                      Row(
                        children: [
                          MouseRegion(
                            cursor: MaterialStateMouseCursor.clickable,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  index = 0;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.grey.withOpacity(0.4) : Colors.white,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                width: 100,
                                height: 30,
                                child: const Center(child: Text("Baseline")),
                              ),
                            ),
                          ),
                          MouseRegion(
                            cursor: MaterialStateMouseCursor.clickable,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  index = 1;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == 1 ? Colors.grey.withOpacity(0.4) : Colors.white,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                width: 100,
                                height: 30,
                                child: const Center(child: Text("Stimulation 1")),
                              ),
                            ),
                          ),
                          MouseRegion(
                            cursor: MaterialStateMouseCursor.clickable,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  index = 2;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == 2 ? Colors.grey.withOpacity(0.4) : Colors.white,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                width: 100,
                                height: 30,
                                child: const Center(child: Text("Recovery 1")),
                              ),
                            ),
                          ),
                          MouseRegion(
                            cursor: MaterialStateMouseCursor.clickable,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  index = 3;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == 3 ? Colors.grey.withOpacity(0.4) : Colors.white,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                width: 100,
                                height: 30,
                                child: const Center(child: Text("Stimulation 2")),
                              ),
                            ),
                          ),
                          MouseRegion(
                            cursor: MaterialStateMouseCursor.clickable,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  index = 4;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == 4 ? Colors.grey.withOpacity(0.4) : Colors.white,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                width: 100,
                                height: 30,
                                child: const Center(child: Text("Recovery 2")),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
                        width: double.infinity,
                        child: _buildTab(),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          TextField(
                            controller: textEditingController,
                            minLines: 5,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              decorationThickness: 0,
                            ),
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                disabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2.0,
                                )),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2.0,
                                )),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2.0,
                                ))),
                          ),
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
                                  onPressed: () async {
                                    final url = Uri.parse('${BASE_URL}api/v1/ecg/hrv/${widget.user.eeg}/note/');

                                    debugPrint('url : $url');
                                    final response = await http.put(url, headers: {
                                      'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
                                    }, body: {
                                      "note": textEditingController.text
                                    });

                                    late String text;
                                    if(response.statusCode == 200) {
                                      text="완료 되었습니다.";
                                    } else {
                                      text="실패 했습니다.";
                                    }

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Note'),
                                          content: Text(text),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                  }, child: const Text("등록", style: TextStyle(color: Colors.white),)),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab() {
    return Page1Tab1(page1TabModel: page1TabModelList[index]);
  }
}