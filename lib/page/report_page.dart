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

import 'package:omnifit_front/widget/page2/brain_connectivity_widget.dart';
import 'package:omnifit_front/widget/page2/bsrsr1_chart.dart';
import 'package:omnifit_front/widget/page2/bsrsr2_chart_widget.dart';
import 'package:omnifit_front/widget/page2/bsrsr_chart.dart';
import 'package:omnifit_front/widget/page2/cicle_chart_widget.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/page2/diff_connectivity_widget.dart';
import 'package:omnifit_front/widget/page2/diff_topography_widget.dart';
import 'package:omnifit_front/widget/page2/faa_widget.dart';
import 'package:omnifit_front/widget/page2/frontal_limbic_widget.dart';
import 'package:omnifit_front/widget/page2/horizontal_bar_widget.dart';
import 'package:omnifit_front/widget/page2/hypnogram_widget.dart';
import 'package:omnifit_front/widget/page2/stacked_chart_widget.dart';

class ReportPage extends StatefulWidget {
  final UserModel user;

  static const route = '/report';
  static const route2 = '/eeg/analysis';

  const ReportPage({Key? key, required this.user}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
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
      animationDuration: const Duration(milliseconds: 800));

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
      final response = await http.get(url, headers: {
        'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
      });

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

    // === EEG (안전 파싱) ===
    try {
      final url =
          Uri.parse('${BASE_URL}api/v1/eeg/analysis/${widget.user.eeg}');
      final response = await http.get(url, headers: {
        'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
      });

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes).trim();
        if (body.isEmpty || body == 'null') {
          setState(() {
            _errorMessage = "데이터를 불러오는데 실패했습니다. (EEG 파일 확인 요망)";
          });
          return;
        }

        final decoded = jsonDecode(body);
        Map<String, dynamic> valueMap;

        if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          valueMap = decoded.first as Map<String, dynamic>;
        } else if (decoded is Map<String, dynamic>) {
          valueMap = decoded;
        } else {
          setState(() {
            _errorMessage = "데이터를 불러오는데 실패했습니다. (EEG 응답 형식 확인 요망)";
          });
          return;
        }

        // Safely parse the data
        hypnogramModel =
            HypnogramModel.fromJson(valueMap['sleep_staging']?['sleep_stage']);
        topographyList.addAll([
          TopographyModel.fromJson(valueMap, "delta"),
          TopographyModel.fromJson(valueMap, "theta"),
          TopographyModel.fromJson(valueMap, "alpha"),
          TopographyModel.fromJson(valueMap, "beta"),
          TopographyModel.fromJson(valueMap, "gamma"),
        ]);

        if (valueMap['diff1'] != null) {
          diffTopographyList.addAll([
            DiffTopographyModel.fromJson(valueMap, "delta"),
            DiffTopographyModel.fromJson(valueMap, "theta"),
            DiffTopographyModel.fromJson(valueMap, "alpha"),
            DiffTopographyModel.fromJson(valueMap, "beta"),
            DiffTopographyModel.fromJson(valueMap, "gamma"),
          ]);
        }

        connectivityList.addAll([
          ConnectivityModel.fromJson(valueMap, "delta"),
          ConnectivityModel.fromJson(valueMap, "theta"),
          ConnectivityModel.fromJson(valueMap, "alpha"),
          ConnectivityModel.fromJson(valueMap, "beta"),
          ConnectivityModel.fromJson(valueMap, "gamma"),
        ]);

        if (valueMap['diff1'] != null) {
          diffConnectivityList.addAll([
            DiffConnectivityModel.fromJson(valueMap, "delta"),
            DiffConnectivityModel.fromJson(valueMap, "theta"),
            DiffConnectivityModel.fromJson(valueMap, "alpha"),
            DiffConnectivityModel.fromJson(valueMap, "beta"),
            DiffConnectivityModel.fromJson(valueMap, "gamma"),
          ]);
        }

        if (valueMap['diff1'] != null &&
            valueMap['diff1']['connectivity2_alpha'] != null) {
          connectivity2List.addAll([
            Connectivity2Model.fromJson(valueMap, "delta"),
            Connectivity2Model.fromJson(valueMap, "theta"),
            Connectivity2Model.fromJson(valueMap, "alpha"),
            Connectivity2Model.fromJson(valueMap, "beta"),
            Connectivity2Model.fromJson(valueMap, "gamma"),
          ]);

          diffConnectivity2List.addAll([
            DiffConnectivity2Model.fromJson(valueMap, "delta"),
            DiffConnectivity2Model.fromJson(valueMap, "theta"),
            DiffConnectivity2Model.fromJson(valueMap, "alpha"),
            DiffConnectivity2Model.fromJson(valueMap, "beta"),
            DiffConnectivity2Model.fromJson(valueMap, "gamma"),
          ]);
        }

        relatedPsdModel =
            RelatedPsdModel.fromJson(valueMap['psd']?['related_psd']);
        regionPsdModel = RegionPsdModel.fromJson(
            valueMap['psd']?['region_psd']?['left'],
            valueMap['psd']?['region_psd']?['right']);
        sleepStageProbModel = SleepStageProbModel.fromJson(
            valueMap['sleep_staging']?['sleep_stage_prob']);
        colorAreaChartModel =
            ColorAreaChartModel.fromJson(valueMap['psd']?['raw_psd']);
        graph1model =
            Graph1Model.fromJson2(valueMap['psd']?['raw_psd']?['mean']);
        frontalLimbicModel =
            FrontalLimbicModel.fromJson(valueMap['frontal_limbic']);

        if (valueMap['faa'] != null) {
          faaModel = FaaModel.fromJson(valueMap['faa']);
        }

        brainConnectivityModel =
            BrainConnectivityModel.fromJson(valueMap['frontal_limbic']);
        textEditingController.text = valueMap['note'] ?? "";
      } else {
        setState(() {
          _errorMessage = "데이터를 불러오는데 실패했습니다. (EEG 파일 확인 요망)";
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
          body: Center(child: CircularProgressIndicator()));
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
                        child: const Text("뒤로가기",
                            style: TextStyle(color: Colors.white)),
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
                        child: const Text("PDF 배포",
                            style: TextStyle(color: Colors.white)),
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
                              "${DateFormat('yyyy.MM.dd').format(widget.user.measurement_date)} ${widget.user.name} 피험자 실험 결과",
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
                                                fontSize: 18,
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
                                                model: page1TabModelList[0]),
                                            FrequencyDomainWidget(
                                                model: page1TabModelList[0]),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                            model: page1TabModelList[0]
                                                .graph1model),
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
                                              width: 500),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                              "$BASE_URL${page1TabModelList[0].comparison}",
                                              width: 500),
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
                                                fontSize: 18,
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
                                                model: page1TabModelList[1]),
                                            FrequencyDomainWidget(
                                                model: page1TabModelList[1]),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                            model: page1TabModelList[1]
                                                .graph1model),
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
                                              width: 500),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                              "$BASE_URL${page1TabModelList[1].comparison}",
                                              width: 500),
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
                                                fontSize: 18,
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
                                                model: page1TabModelList[2]),
                                            FrequencyDomainWidget(
                                                model: page1TabModelList[2]),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                            model: page1TabModelList[2]
                                                .graph1model),
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
                                              width: 500),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                              "$BASE_URL${page1TabModelList[2].comparison}",
                                              width: 500),
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
                                                fontSize: 18,
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
                                                model: page1TabModelList[3]),
                                            FrequencyDomainWidget(
                                                model: page1TabModelList[3]),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                            model: page1TabModelList[3]
                                                .graph1model),
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
                                              width: 500),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                              "$BASE_URL${page1TabModelList[3].comparison}",
                                              width: 500),
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
                                                fontSize: 18,
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
                                                model: page1TabModelList[4]),
                                            FrequencyDomainWidget(
                                                model: page1TabModelList[4]),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        DefaultLineChart(
                                            model: page1TabModelList[4]
                                                .graph1model),
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
                                              width: 500),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Image.network(
                                              "$BASE_URL${page1TabModelList[4].comparison}",
                                              width: 500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 65),

                                  // EEG Delta 섹션(존재할 때만)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'EEG_Delta',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 100),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 20),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${topographyList[0].baseline}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Baseline"),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${topographyList[0].stimulation1}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Stimulation1"),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${topographyList[0].recovery1}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Recovery1"),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${topographyList[0].stimulation2}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Stimulation2"),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${topographyList[0].recovery2}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Recovery2"),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      const SizedBox(width: 20),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${diffTopographyList[0].diff1}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Stimulation1-Baseline"),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${diffTopographyList[0].diff2}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Recovery1-Stimulation1"),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${diffTopographyList[0].diff3}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Stimulation2-Recovery1"),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              child: Image.network(
                                                  "$BASE_URL${diffTopographyList[0].diff4}",
                                                  width: 150,
                                                  filterQuality:
                                                      FilterQuality.high),
                                            ),
                                          ),
                                          const Text("Recovery2-Stimulation2"),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                    ],
                                  ),
                                ],
                              ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[0].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[0].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[0].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[0].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[0].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[0].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[0].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[0].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[0].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[0].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[0].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[0].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[0].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[0].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[0].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[0].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[0].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[0].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            )
                          ],
                        ),

                        // ====================== EEG_Theta (index 1) ======================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'EEG_Theta',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[1].baseline}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[1].stimulation1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[1].recovery1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[1].stimulation2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[1].recovery2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[1].diff1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1-Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[1].diff2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1-Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[1].diff3}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2-Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[1].diff4}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2-Stimulation2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[1].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[1].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[1].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[1].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[1].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[1].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[1].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[1].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[1].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[1].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[1].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[1].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[1].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[1].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[1].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[1].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[1].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[1].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),

                        // ====================== EEG_Alpha (index 2) ======================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'EEG_Alpha',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[2].baseline}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[2].stimulation1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[2].recovery1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[2].stimulation2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[2].recovery2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[2].diff1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1-Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[2].diff2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1-Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[2].diff3}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2-Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[2].diff4}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2-Stimulation2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[2].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[2].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[2].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[2].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[2].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[2].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[2].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[2].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[2].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[2].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[2].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[2].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[2].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[2].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[2].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[2].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[2].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[2].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),

// ====================== EEG_Beta (index 3) ======================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'EEG_Beta',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[3].baseline}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[3].stimulation1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[3].recovery1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[3].stimulation2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[3].recovery2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[3].diff1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1-Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[3].diff2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1-Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[3].diff3}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2-Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[3].diff4}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2-Stimulation2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[3].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[3].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[3].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[3].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[3].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[3].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[3].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[3].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[3].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[3].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[3].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[3].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[3].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[3].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[3].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[3].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[3].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[3].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),

// ====================== EEG_Gamma (index 4) ======================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'EEG_Gamma',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[4].baseline}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[4].stimulation1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[4].recovery1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[4].stimulation2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${topographyList[4].recovery2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[4].diff1}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation1-Baseline"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[4].diff2}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery1-Stimulation1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[4].diff3}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Stimulation2-Recovery1"),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    child: Image.network(
                                        "$BASE_URL${diffTopographyList[4].diff4}",
                                        width: 150,
                                        filterQuality: FilterQuality.high),
                                  ),
                                ),
                                const Text("Recovery2-Stimulation2"),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[4].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[4].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[4].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[4].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivityList[4].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[4].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[4].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[4].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivityList[4].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[4].baseline}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[4].stimulation1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[4].recovery1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[4].stimulation2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${connectivity2List[4].recovery2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[4].diff1}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation1-Baseline"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[4].diff2}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery1-Stimulation1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[4].diff3}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Stimulation2-Recovery1"),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                          child: Image.network(
                                              "$BASE_URL${diffConnectivity2List[4].diff4}",
                                              width: 150,
                                              filterQuality:
                                                  FilterQuality.high)),
                                    ),
                                    const Text("Recovery2-Stimulation2"),
                                  ],
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
