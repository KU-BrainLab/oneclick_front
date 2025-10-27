import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/models/graph1_model.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:omnifit_front/models/page1_tab_model.dart';

import 'package:omnifit_front/models/brain_connectivity_model.dart';
import 'package:omnifit_front/models/color_area_chart_model.dart';
import 'package:omnifit_front/models/connectivity2_model.dart';
import 'package:omnifit_front/models/connectivity_model.dart';
import 'package:omnifit_front/models/diff_connectivity2_model.dart';
import 'package:omnifit_front/models/diff_connectivity_model.dart';
import 'package:omnifit_front/models/diff_topography_model.dart';
import 'package:omnifit_front/models/faa_model.dart';
import 'package:omnifit_front/models/frontal_limbic_model.dart';
import 'package:omnifit_front/models/graph1_model.dart';
import 'package:omnifit_front/models/hypnogram_model.dart';
import 'package:omnifit_front/models/region_psd_model.dart';
import 'package:omnifit_front/models/related_psd_model.dart';
import 'package:omnifit_front/models/sleep_stage_prob_model.dart';
import 'package:omnifit_front/models/topography_model.dart';

import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/page1/graph1.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/widget/page1/multi_color_line_chart_widget.dart';
import 'package:omnifit_front/widget/page1/page1_tab1.dart';
import 'package:intl/intl.dart';

import 'package:omnifit_front/models/page1_tab_model.dart';
import 'package:omnifit_front/widget/page1/frequency_domain_widget.dart';
import 'package:omnifit_front/widget/page1/time_domain_widget.dart';
import 'package:omnifit_front/widget/page1/default_line_chart.dart';

class ReportPage1 extends StatefulWidget {
  final UserModel user;

  static const route = '/report1';

  const ReportPage1({Key? key, required this.user}) : super(key: key);

  @override
  State<ReportPage1> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage1>
    with SingleTickerProviderStateMixin {
  Graph1Model? graph1model;
  MultiColorLineChartModel? multiColorLineChartModel;
  List<Page1TabModel> page1TabModelList = [];
  TextEditingController textEditingController = TextEditingController();

  bool isLoading = true;
  String? _errorMessage;

  List<TopographyModel> topographyList = [];
  List<DiffTopographyModel> diffTopographyList = [];
  List<ConnectivityModel> connectivityList = [];
  List<DiffConnectivityModel> diffConnectivityList = [];
  List<Connectivity2Model> connectivity2List = [];
  List<DiffConnectivity2Model> diffConnectivity2List = [];

  late BrainConnectivityModel brainConnectivityModel;
  late RelatedPsdModel relatedPsdModel;
  late RegionPsdModel regionPsdModel;
  late HypnogramModel hypnogramModel;
  late SleepStageProbModel sleepStageProbModel;
  late ColorAreaChartModel colorAreaChartModel;
  late FrontalLimbicModel frontalLimbicModel;
  FaaModel? faaModel;

  late TabController tabController = TabController(
    length: 5,
    vsync: this,
    initialIndex: 0,
    animationDuration: const Duration(milliseconds: 800),
  );

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
    // === HRV ===
    try {
      final url = Uri.parse('${BASE_URL}api/v1/ecg/hrv/${widget.user.hrv}');
      final response = await http.get(
        url,
        headers: {'Authorization': 'JWT ${AppService.instance.currentUser?.id}'},
      );

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty ||
            utf8.decode(response.bodyBytes) == 'null') {
          setState(() {
            _errorMessage = "데이터를 불러오는데 실패했습니다. (HRV 파일 확인 요망)";
          });
          return;
        }

        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        Map<String, dynamic> valueMap;

        if (responseData is List && responseData.isNotEmpty) {
          valueMap = responseData[0];
        } else if (responseData is Map) {
          valueMap = responseData as Map<String, dynamic>;
        } else {
          setState(() {
            _errorMessage = "데이터를 불러오는데 실패했습니다. (HRV 파일 확인 요망)";
          });
          return;
        }

        final nniData = valueMap['nni'] as List<dynamic>? ?? [];
        final rmssdData = valueMap['rmssd'] as List<dynamic>? ?? [];

        graph1model = Graph1Model.fromJson(nniData);

        if (graph1model != null) {
          final double finalMaxX = graph1model!.maxX.round().toDouble();

          multiColorLineChartModel = MultiColorLineChartModel.fromJson(
            rmssdData,
            finalAxisMaxX: finalMaxX,
          );
        }

        page1TabModelList.add(Page1TabModel.fromJson(valueMap['baseline']));
        page1TabModelList.add(Page1TabModel.fromJson(valueMap['stimulation1']));
        page1TabModelList.add(Page1TabModel.fromJson(valueMap['recovery1']));
        page1TabModelList.add(Page1TabModel.fromJson(valueMap['stimulation2']));
        page1TabModelList.add(Page1TabModel.fromJson(valueMap['recovery2']));

        textEditingController.text = valueMap['note'] ?? "";
      } else {
        setState(() {
          _errorMessage = "데이터를 불러오는데 실패했습니다. (HRV 파일 확인 요망)";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "데이터 처리 중 오류가 발생했습니다.";
      });
      debugPrint("Error in callHttp: $e");
    } finally {
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
                          foregroundColor: Colors.green,
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
                          side: const BorderSide(width: 2, color: Colors.green),
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

                // ▼▼▼ Row(제목/로고)부터 아래 전체를 하나의 RepaintBoundary로 감싼다 ▼▼▼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: RepaintBoundary(
                    key: AppService.instance.screenKey, // ✅ 캡처 구역 시작(제목+로고 포함)
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "${DateFormat('yyyy.MM.dd').format(widget.user.measurement_date)} ${widget.user.name} 피험자 실험 결과 - HRV",
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

                        _errorMessage != null
                            ? Center(child: Text(_errorMessage!))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (graph1model != null &&
                                      multiColorLineChartModel != null) ...[
                                    Graph1(
                                      graph1model: graph1model!,
                                    ),
                                    const SizedBox(height: 40),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            const SizedBox(width: 42),
                                            Expanded(
                                              child: Text(
                                                'rmssd',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        MultiColorLineChartWidget(
                                          model: multiColorLineChartModel!,
                                          maxX: graph1model!.maxX
                                              .round()
                                              .toDouble(),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 700),

                                  // 각 HRV 섹션: 길이 체크만 추가 (구조 동일)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'HRV_Baseline',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 30),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            TimeDomainWidget(
                                              model: page1TabModelList[0],
                                            ),
                                            FrequencyDomainWidget(
                                              model: page1TabModelList[0],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                          model: page1TabModelList[0]
                                              .graph1model,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            const SizedBox(width: 40),
                                            Expanded(
                                              child: Text(
                                                'Heart Rate Heat Plot',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[0].heart_rate}",
                                            width: 500,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[0].comparison}",
                                            width: 500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 65),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'HRV_Stimulation1',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 30),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            TimeDomainWidget(
                                              model: page1TabModelList[1],
                                            ),
                                            FrequencyDomainWidget(
                                              model: page1TabModelList[1],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                          model: page1TabModelList[1]
                                              .graph1model,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            const SizedBox(width: 40),
                                            Expanded(
                                              child: Text(
                                                'Heart Rate Heat Plot',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[1].heart_rate}",
                                            width: 500,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[1].comparison}",
                                            width: 500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 65),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'HRV_Recovery1',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 30),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            TimeDomainWidget(
                                              model: page1TabModelList[2],
                                            ),
                                            FrequencyDomainWidget(
                                              model: page1TabModelList[2],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                          model: page1TabModelList[2]
                                              .graph1model,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            const SizedBox(width: 40),
                                            Expanded(
                                              child: Text(
                                                'Heart Rate Heat Plot',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[2].heart_rate}",
                                            width: 500,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[2].comparison}",
                                            width: 500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 65),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'HRV_Stimulation2',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 30),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            TimeDomainWidget(
                                              model: page1TabModelList[3],
                                            ),
                                            FrequencyDomainWidget(
                                              model: page1TabModelList[3],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                          model: page1TabModelList[3]
                                              .graph1model,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            const SizedBox(width: 40),
                                            Expanded(
                                              child: Text(
                                                'Heart Rate Heat Plot',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[3].heart_rate}",
                                            width: 500,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[3].comparison}",
                                            width: 500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 65),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'HRV_Recovery2',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 30),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            TimeDomainWidget(
                                              model: page1TabModelList[4],
                                            ),
                                            FrequencyDomainWidget(
                                              model: page1TabModelList[4],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                          model: page1TabModelList[4]
                                              .graph1model,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            const SizedBox(width: 40),
                                            Expanded(
                                              child: Text(
                                                'Heart Rate Heat Plot',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[4].heart_rate}",
                                            width: 500,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                            "$BASE_URL${page1TabModelList[4].comparison}",
                                            width: 500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
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
