import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
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
import 'package:omnifit_front/widget/page2/brain_connectivity_widget.dart';
import 'package:omnifit_front/widget/page2/bsrsr1_chart.dart';
import 'package:omnifit_front/widget/page2/bsrsr2_chart_widget.dart';
import 'package:omnifit_front/widget/page2/bsrsr_chart.dart';
import 'package:omnifit_front/widget/page2/cicle_chart_widget.dart';
import 'package:omnifit_front/widget/header.dart';
import 'package:omnifit_front/widget/page2/default_line_chart.dart';
import 'package:omnifit_front/widget/page2/diff_connectivity_widget.dart';
import 'package:omnifit_front/widget/page2/diff_topography_widget.dart';
import 'package:omnifit_front/widget/page2/faa_widget.dart';
import 'package:omnifit_front/widget/page2/frontal_limbic_widget.dart';
import 'package:omnifit_front/widget/page2/horizontal_bar_widget.dart';
import 'package:omnifit_front/widget/page2/hypnogram_widget.dart';
import 'package:omnifit_front/widget/page2/stacked_chart_widget.dart';

class Page2 extends StatefulWidget {
  final UserModel user;
  static const route = '/eeg/analysis';
  const Page2({Key? key, required this.user}) : super(key: key);

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> with TickerProviderStateMixin { // Changed to TickerProviderStateMixin for multiple TabControllers
  bool isLoading = true;
  String? _errorMessage;

  List<TopographyModel> topographyList = [];
  List<DiffTopographyModel> diffTopographyList = [];
  List<ConnectivityModel> connectivityList = [];
  List<DiffConnectivityModel> diffConnectivityList = [];
  List<Connectivity2Model> connectivity2List = [];
  List<DiffConnectivity2Model> diffConnectivity2List = [];

  TextEditingController textEditingController = TextEditingController();
  late Graph1Model graph1model;
  late RelatedPsdModel relatedPsdModel;
  late RegionPsdModel regionPsdModel;
  late HypnogramModel hypnogramModel;
  late SleepStageProbModel sleepStageProbModel;
  late ColorAreaChartModel colorAreaChartModel;
  late FrontalLimbicModel frontalLimbicModel;
  FaaModel? faaModel;

  late BrainConnectivityModel brainConnectivityModel;
  // NOTE: TabControllers are initialized but not used in the provided code.
  // If they are used elsewhere, ensure they are properly managed.
  late TabController tabController1 = TabController(length: 5, vsync: this, initialIndex: 0, animationDuration: const Duration(milliseconds: 800));
  late TabController tabController2 = TabController(length: 5, vsync: this, initialIndex: 0, animationDuration: const Duration(milliseconds: 800));
  String? note;

  @override
  void initState() {
    super.initState();
    callHttp();
  }

  @override
  void dispose() {
    tabController1.dispose();
    tabController2.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void callHttp() async {
    try {
      final url = Uri.parse('${BASE_URL}api/v1/eeg/analysis/${widget.user.eeg}');
      final response = await http.get(url, headers: {
        'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
      });

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty || utf8.decode(response.bodyBytes) == 'null') {
          setState(() {
            _errorMessage = "데이터를 불러오는데 실패했습니다. (EEG 파일 확인 요망)";
          });
          return;
        }
        
        final valueMap = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        // Safely parse the data
        hypnogramModel = HypnogramModel.fromJson(valueMap['sleep_staging']['sleep_stage']);
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

        if (valueMap['diff1'] != null && valueMap['diff1']['connectivity2_alpha'] != null) {
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
        
        relatedPsdModel = RelatedPsdModel.fromJson(valueMap['psd']['related_psd']);
        regionPsdModel = RegionPsdModel.fromJson(valueMap['psd']['region_psd']['left'], valueMap['psd']['region_psd']['right']);
        sleepStageProbModel = SleepStageProbModel.fromJson(valueMap['sleep_staging']['sleep_stage_prob']);
        colorAreaChartModel = ColorAreaChartModel.fromJson(valueMap['psd']['raw_psd']);
        graph1model = Graph1Model.fromJson2(valueMap['psd']['raw_psd']['mean']);
        frontalLimbicModel = FrontalLimbicModel.fromJson(valueMap['frontal_limbic']);

        if (valueMap['faa'] != null) {
          faaModel = FaaModel.fromJson(valueMap['faa']);
        }

        brainConnectivityModel = BrainConnectivityModel.fromJson(valueMap['frontal_limbic']);
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
                Header(headText: "EEG 결과서", userModel: widget.user),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      // 데이터 로드 성공 시 결과 내용 표시
                      : Column(
                          children: [
                            BsrsrChartWidget(topographyList: topographyList, diffTopographyList: diffTopographyList,),
                            const SizedBox(height: 20),
                            Bsrsr1ChartWidget(connectivityList: connectivityList, diffConnectivityList: diffConnectivityList),
                            const SizedBox(height: 20),
                            if (connectivity2List.isNotEmpty)
                              Bsrsr2ChartWidget(connectivityList: connectivity2List, diffConnectivityList: diffConnectivity2List),
                            if (connectivity2List.isNotEmpty) const SizedBox(height: 20),
                            FrontalLimbicWidget(model: frontalLimbicModel),
                            const SizedBox(height: 20),
                            if (faaModel != null) ...[
                              FaaWidget(model: faaModel!),
                              const SizedBox(height: 20),
                            ],
                            Row(
                              children: [
                                Expanded(child: CircleChartWidget(model: relatedPsdModel)),
                                const SizedBox(width: 10),
                                Expanded(child: DefaultLineChart(model: graph1model)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            HorizontalBarWidget(model: regionPsdModel),
                            const SizedBox(height: 20),
                            HypnogramWidget(model: hypnogramModel),
                            const SizedBox(height: 20),
                            StackedChartWidget(model: sleepStageProbModel),
                            const SizedBox(height: 20), // Added for spacing before the note field
                            Column(
                              children: [
                                TextField(
                                  controller: textEditingController,
                                  minLines: 5,
                                  maxLines: 5,
                                  keyboardType: TextInputType.multiline,
                                  style: const TextStyle(
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
                                    )),
                                  ),
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
                                        final url = Uri.parse('${BASE_URL}api/v1/eeg/analysis/${widget.user.eeg}/note/');
                                        debugPrint('url : $url');
                                        final response = await http.put(url, headers: {
                                          'Authorization': 'JWT ${AppService.instance.currentUser?.id}'
                                        }, body: {
                                          "note": textEditingController.text
                                        });

                                        late String text;
                                        if (response.statusCode == 200) {
                                          text = "완료 되었습니다.";
                                        } else {
                                          text = "실패 했습니다.";
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
                                      },
                                      child: const Text("등록", style: TextStyle(color: Colors.white),),
                                    ),
                                  ],
                                )
                              ],
                            ),
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