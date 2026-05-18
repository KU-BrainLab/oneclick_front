import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/models/graph1_model.dart';
import 'package:omnifit_front/models/hypnogram_model.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:omnifit_front/models/related_psd_model.dart';
import 'package:omnifit_front/models/survey_model.dart';
import 'package:omnifit_front/models/topography_model.dart';
import 'package:omnifit_front/page/users_page_report.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/page1/graph1.dart';
import 'package:omnifit_front/widget/page1/multi_color_line_chart_widget.dart';
import 'package:omnifit_front/widget/page2/cicle_chart_widget.dart';
import 'package:omnifit_front/widget/page2/default_line_chart.dart';
import 'package:omnifit_front/widget/page2/hypnogram_widget.dart';

class ReportMerged extends StatefulWidget {
  final UserModel user;
  final List<double>? trigger;
  static const route = '/report_merged';

  const ReportMerged({Key? key, required this.user, this.trigger}) : super(key: key);

  @override
  State<ReportMerged> createState() => _ReportMergedState();
}

class _ReportMergedState extends State<ReportMerged> {
  bool isLoading = true;

  // 이 인스턴스 전용 RepaintBoundary key (AppService.screenKey 공유 시 동일 키 충돌 방지)
  final GlobalKey _screenKey = GlobalKey();

  // EEG
  List<TopographyModel> topographyList = [];
  RelatedPsdModel? relatedPsdModel;
  Graph1Model? rawPsdModel;
  HypnogramModel? hypnogramModel;

  // Survey
  List<_SalesData> psqiList = [];
  List<_SalesData> isiList = [];

  // HRV
  Graph1Model? nniModel;
  MultiColorLineChartModel? rmssdModel;

  static const _bandNames = ['Delta', 'Theta', 'Alpha', 'Beta', 'Gamma', 'Sigma'];
  static const _bandKeys = ['delta', 'theta', 'alpha', 'beta', 'gamma', 'sigma'];

  @override
  void initState() {
    super.initState();
    if (widget.trigger != null && widget.trigger!.isNotEmpty) {
      AppService.instance.setIntervals(widget.trigger!);
    }
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadEeg(), _loadSurvey(), _loadHrv()]);
    setState(() => isLoading = false);
  }

  Future<void> _loadEeg() async {
    if (widget.user.eeg == null) return;
    try {
      final url = Uri.parse('${BASE_URL}api/v1/eeg/analysis/${widget.user.eeg}');
      final response = await http.get(url, headers: {
        'Authorization': 'JWT ${AppService.instance.currentUser?.id}',
      });
      if (response.statusCode != 200) return;
      final body = utf8.decode(response.bodyBytes);
      if (body.isEmpty || body == 'null') return;

      final valueMap = jsonDecode(body) as Map<String, dynamic>;

      for (final key in _bandKeys) {
        topographyList.add(TopographyModel.fromJson(valueMap, key));
      }

      relatedPsdModel = RelatedPsdModel.fromJson(valueMap['psd']['related_psd']);
      rawPsdModel = Graph1Model.fromJson2(valueMap['psd']['raw_psd']['mean']);
      hypnogramModel = HypnogramModel.fromJson(valueMap['sleep_staging']['sleep_stage']);
    } catch (e) {
      debugPrint("EEG load error: $e");
    }
  }

  Future<void> _loadSurvey() async {
    try {
      final url = Uri.parse(
        '${BASE_URL}api/v1/survey/?name=${widget.user.name}&sex=${widget.user.sex}&birth=${widget.user.birth}&age=${widget.user.age}',
      );
      final response = await http.get(url, headers: {
        'Authorization': 'JWT ${AppService.instance.currentUser?.id}',
      });
      if (response.statusCode != 200) return;

      final List<dynamic> valueList = jsonDecode(utf8.decode(response.bodyBytes));
      for (final value in valueList.reversed) {
        final survey = SurveyModel.fromJson(value);
        if (survey.measuementDate == null) continue;
        final dateStr = DateFormat("yy.MM.dd").format(survey.measuementDate!);
        if (survey.questionnaire.psql != null) {
          psqiList.add(_SalesData(dateStr, double.parse(survey.questionnaire.psql!)));
        }
        if (survey.questionnaire.isi != null) {
          isiList.add(_SalesData(dateStr, double.parse(survey.questionnaire.isi!)));
        }
      }
    } catch (e) {
      debugPrint("Survey load error: $e");
    }
  }

  Future<void> _loadHrv() async {
    if (widget.user.hrv == null) return;
    try {
      final url = Uri.parse('${BASE_URL}api/v1/ecg/hrv/${widget.user.hrv}');
      final response = await http.get(url, headers: {
        'Authorization': 'JWT ${AppService.instance.currentUser?.id}',
      });
      if (response.statusCode != 200) return;
      final body = utf8.decode(response.bodyBytes);
      if (body.isEmpty || body == 'null') return;

      final responseData = jsonDecode(body);
      Map<String, dynamic> valueMap;
      if (responseData is List && responseData.isNotEmpty) {
        valueMap = responseData[0];
      } else if (responseData is Map) {
        valueMap = responseData as Map<String, dynamic>;
      } else {
        return;
      }

      final nniData = valueMap['nni'] as List<dynamic>? ?? [];
      final rmssdData = valueMap['rmssd'] as List<dynamic>? ?? [];
      final intervals = widget.trigger ?? [];
      final double finalMaxX = intervals.isNotEmpty
          ? intervals.last.toDouble()
          : (AppService.instance.intervals?.last.toDouble() ?? 50.0);

      nniModel = Graph1Model.fromJson(nniData);
      if (nniModel != null) {
        rmssdModel = MultiColorLineChartModel.fromJson(
          rmssdData,
          finalAxisMaxX: finalMaxX,
          intervals: intervals,
        );
      }
    } catch (e) {
      debugPrint("HRV load error: $e");
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                          side: const BorderSide(width: 2, color: Colors.green),
                          backgroundColor: Colors.green,
                          elevation: 10.0,
                        ),
                        onPressed: () => context.go(UsersPageReport.route),
                        child: const Text("뒤로가기", style: TextStyle(color: Colors.white)),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                          side: const BorderSide(width: 2, color: Colors.green),
                          backgroundColor: Colors.green,
                          elevation: 10.0,
                        ),
                        onPressed: () {
                          final fileName =
                              '${DateFormat('yyyyMMdd').format(widget.user.measurement_date)}_${widget.user.name}_통합.pdf';
                          AppService.instance.managePdfDistributionFromKey(
                            repaintKey: _screenKey,
                            fileName: fileName,
                            refreshAfter: true,
                          );
                        },
                        child: const Text("PDF 배포", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: RepaintBoundary(
                    key: _screenKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 헤더
                        Row(
                          children: [
                            Text(
                              "${DateFormat('yyyy.MM.dd').format(widget.user.measurement_date)} ${widget.user.name} 통합 리포트",
                              style: const TextStyle(
                                  color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20),
                            ),
                            const Spacer(),
                            Center(child: svgIcon(Assets.img.icon_logo, width: 60, height: 30)),
                            const SizedBox(width: 10),
                            Transform.translate(
                              offset: const Offset(0, -3),
                              child: Image.asset("assets/logo1.png", width: 130, height: 55),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 1. 피험자 정보
                        _sectionTitle("피험자 정보"),
                        const SizedBox(height: 12),
                        _buildUserInfo(),
                        const SizedBox(height: 40),

                        // 2. 토포그래픽 (Delta ~ Sigma)
                        for (int i = 0; i < _bandNames.length; i++) ...[
                          // Beta(3)→Gamma(4) 사이 페이지 넘김 여백
                          if (i == 4) const SizedBox(height: 90),
                          if (i < topographyList.length) ...[
                            _sectionTitle("EEG_${_bandNames[i]}"),
                            const SizedBox(height: 16),
                            _buildTopographyRow(topographyList[i]),
                            const SizedBox(height: 40),
                          ] else ...[
                            _sectionTitle("EEG_${_bandNames[i]}"),
                            const SizedBox(height: 16),
                            const Center(child: Text("데이터 없음")),
                            const SizedBox(height: 40),
                          ],
                        ],

                        // 3. Related PSD + Raw PSD
                        _sectionTitle("PSD"),
                        const SizedBox(height: 16),
                        if (relatedPsdModel != null && rawPsdModel != null)
                          Row(
                            children: [
                              Expanded(child: CircleChartWidget(model: relatedPsdModel!)),
                              const SizedBox(width: 10),
                              Expanded(child: DefaultLineChart(model: rawPsdModel!)),
                            ],
                          )
                        else
                          const Center(child: Text("데이터 없음")),
                        const SizedBox(height: 40),

                        // 4. Sleep Stage
                        _sectionTitle("Sleep Stage"),
                        const SizedBox(height: 16),
                        if (hypnogramModel != null)
                          HypnogramWidget(model: hypnogramModel!)
                        else
                          const Center(child: Text("데이터 없음")),
                        // ── 강제 페이지 분리 마커 ──
                        Container(height: 4, color: const Color(0xFFFF0080)),

                        // 5. PSQI / ISI
                        _sectionTitle("Questionnaire"),
                        const SizedBox(height: 16),
                        if (psqiList.isNotEmpty)
                          _buildSurveyChart("PSQI-K", psqiList, 25, [
                            PlotBand(
                                isVisible: true,
                                color: const Color(0xff6db290).withAlpha(102),
                                start: -1,
                                end: 8),
                            PlotBand(
                                isVisible: true,
                                color: const Color(0xFF44948f).withAlpha(102),
                                start: 8,
                                end: 26),
                          ])
                        else
                          const Center(child: Text("PSQI 데이터 없음")),
                        if (isiList.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSurveyChart("ISI", isiList, 35, [
                            PlotBand(
                                isVisible: true,
                                color: const Color(0xff6db290).withAlpha(102),
                                start: -1,
                                end: 7),
                            PlotBand(
                                isVisible: true,
                                color: const Color(0xFF44948f).withAlpha(102),
                                start: 7,
                                end: 15),
                            PlotBand(
                                isVisible: true,
                                color: const Color(0xFF24768b).withAlpha(102),
                                start: 15,
                                end: 36),
                          ]),
                          const SizedBox(height: 40),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Center(child: Text("ISI 데이터 없음")),
                        ],


                        // ── 강제 페이지 분리 마커 (PDF 빌더가 감지해 여기서 절단) ──
                        Container(height: 4, color: const Color(0xFFFF0080)),

                        // 6. NNI
                        _sectionTitle("HRV - NNI"),
                        const SizedBox(height: 16),
                        if (nniModel != null)
                          Graph1(graph1model: nniModel!)
                        else
                          const Center(child: Text("데이터 없음")),
                        const SizedBox(height: 40),

                        // 7. RMSSD
                        _sectionTitle("HRV - RMSSD"),
                        const SizedBox(height: 16),
                        if (rmssdModel != null)
                          MultiColorLineChartWidget(model: rmssdModel!, maxX: rmssdModel!.maxX)
                        else
                          const Center(child: Text("데이터 없음")),

                        const SizedBox(height: 200),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem("이름", widget.user.name),
          _infoItem("성별", widget.user.sexName),
          _infoItem("나이", widget.user.age != null ? "${widget.user.age}세" : "-"),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTopographyRow(TopographyModel topo) {
    final phases = [
      ('Baseline', topo.baseline),
      ('Stimulation1', topo.stimulation1),
      ('Recovery1', topo.recovery1),
      ('Stimulation2', topo.stimulation2),
      ('Recovery2', topo.recovery2),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 20),
        for (final phase in phases)
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: phase.$2 != null
                      ? Image.network(
                          "$BASE_URL${phase.$2}",
                          width: 150,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 150, height: 150, child: Center(child: Text("No data"))),
                        )
                      : const SizedBox(width: 150, height: 150, child: Center(child: Text("No data"))),
                ),
                Text(phase.$1),
              ],
            ),
          ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildSurveyChart(
      String title, List<_SalesData> list, double maximum, List<PlotBand> plotBands) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: NumericAxis(maximum: maximum, minimum: 0, interval: 5, plotBands: plotBands),
      title: ChartTitle(text: title),
      series: <LineSeries<_SalesData, String>>[
        LineSeries<_SalesData, String>(
          dataSource: list,
          xValueMapper: (_SalesData s, _) => s.year,
          yValueMapper: (_SalesData s, _) => s.sales,
          color: Colors.blueAccent,
          animationDuration: 0,
          isVisibleInLegend: false,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          markerSettings: const MarkerSettings(isVisible: true, color: Colors.blueAccent),
        ),
      ],
    );
  }
}

class _SalesData {
  _SalesData(this.year, this.sales);
  final String year;
  final double sales;
}
