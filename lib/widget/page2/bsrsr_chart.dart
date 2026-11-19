import 'package:omnifit_front/models/phase_defs.dart';
import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/diff_topography_model.dart';
import 'package:omnifit_front/models/topography_model.dart';
import 'package:omnifit_front/widget/phase_columns.dart';

class BsrsrChartWidget extends StatefulWidget {
  final List<TopographyModel> topographyList;
  final List<DiffTopographyModel> diffTopographyList;
  final int phaseCount;
  const BsrsrChartWidget({Key? key, required this.topographyList, required this.diffTopographyList, this.phaseCount = 5}) : super(key: key);

  @override
  State<BsrsrChartWidget> createState() => _BsrsrChartWidgetState();
}

class _BsrsrChartWidgetState extends State<BsrsrChartWidget> {

  int index = 0;

  static const _bandLabels = ['Delta', 'Theta', 'Alpha', 'Sigma', 'Beta', 'Gamma'];
  static const _oneBandImgWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    if (widget.phaseCount == 1) {
      return _buildAllBandsView();
    }
    return Column(
      children: [
        Row(
          children: [
            _tabButton("Delta", 0),
            _tabButton("Theta", 1),
            _tabButton("Alpha", 2),
            _tabButton("Sigma", 3),
            _tabButton("Beta", 4),
            _tabButton("Gamma", 5),
          ],
        ),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          width: double.infinity,
          // 테두리 안쪽의 실제 폭을 넘긴다 (7열 이상일 때 그림 폭을 여기서 나눈다).
          child: LayoutBuilder(
            builder: (_, constraints) => _buildTab(constraints.maxWidth),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int i) {
    return MouseRegion(
      cursor: MaterialStateMouseCursor.clickable,
      child: GestureDetector(
        onTap: () => setState(() => index = i),
        child: Container(
          decoration: BoxDecoration(
            color: index == i ? Colors.grey.withOpacity(0.4) : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: Colors.black),
          ),
          width: 100,
          height: 30,
          child: Center(child: Text(label)),
        ),
      ),
    );
  }

  // 1-phase: 6개 대역 한 번에 표시 (1×6)
  Widget _buildAllBandsView() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < _bandLabels.length; i++)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_bandLabels[i],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _networkImage(widget.topographyList[i].baseline, width: _oneBandImgWidth),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 6열(6-phase)이 한 줄에 들어가도록 열 수에 따라 줄인다.
  // 7열 이상은 이 값을 상한으로 두고 줄의 실제 폭에 맞춰 더 줄인다 (_buildTab).
  double get _imgWidth => widget.phaseCount >= 6
      ? 110.0
      : widget.phaseCount >= 5
          ? 130.0
          : 190.0;

  /// [rowWidth] 는 그림 줄이 쓸 수 있는 실제 폭이다.
  Widget _buildTab(double rowWidth) {
    // phase 열과 diff 열은 모드(1/3/5/6/9-phase)마다 구성이 다르다.
    // 목록·라벨은 phase_defs.dart 한 곳에서만 정의한다.
    final phases = phaseSeqFor(widget.phaseCount);
    final diffs = diffSeqFor(widget.phaseCount);
    final model = widget.topographyList[index];
    final diffModel =
        widget.diffTopographyList.isNotEmpty ? widget.diffTopographyList[index] : null;
    // 9-phase 는 phase 9열·diff 8열이라 6열용 폭으로는 한 줄에 안 들어간다.
    // 줄 양끝의 20px 여백을 뺀 폭을 열 수로 나눈다 — 줄마다 실제 열 수로
    // 계산한다. 6열 이하는 _imgWidth 그대로다 (phase_columns.dart).
    final phaseWidth = phaseColumnWidth(
        columns: phases.length, available: rowWidth - 40, legacyWidth: _imgWidth);
    final diffWidth = phaseColumnWidth(
        columns: diffs.length, available: rowWidth - 40, legacyWidth: _imgWidth);
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            for (final p in phases)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(model.byKey(p.key), width: phaseWidth),
                  // 7열 이상이면 짧은 표기(Stim1)를 그림 폭 안에 쓴다.
                  phaseColumnLabel(p, columns: phases.length, width: phaseWidth),
                ],
              ),
            const SizedBox(width: 20),
          ],
        ),
        if (diffModel != null && diffs.isNotEmpty) const SizedBox(height: 20),
        if (diffModel != null && diffs.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 20),
              for (final d in diffs)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _networkImage(diffModel.byIndex(d.index), width: diffWidth),
                    // 6-phase 는 diff 가 5열이라 긴 라벨끼리 겹친다. 짧은 표기로.
                    // (7열 이상이면 그 라벨을 그림 폭 안에 가둔다.)
                    fitColumnLabel(
                      Text(diffs.length >= 5 ? d.short : d.label,
                          style: TextStyle(
                              fontSize: diffs.length >= 5 ? 12 : 14)),
                      columns: diffs.length,
                      width: diffWidth,
                    ),
                  ],
                ),
              const SizedBox(width: 20),
            ],
          ),
      ],
    );
  }

  Widget _networkImage(String? path, {double? width}) {
    final w = width ?? _imgWidth;
    if (path == null) {
      return SizedBox(width: w, height: w, child: const Center(child: Text("No data")));
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog1(context, "$BASE_URL$path"),
        child: Image.network(
            "$BASE_URL$path",
            width: w,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
              SizedBox(width: w, height: w, child: const Center(child: Text("No data"))),
          ),
      ),
    );
  }

  void showDialog1(BuildContext context, String image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Icon(Icons.close, color: Colors.white, size: 30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 800,
                height: 800,
                child: Center(child: Image.network(image)),
              ),
            ],
          ),
        );
      },
    );
  }
}
