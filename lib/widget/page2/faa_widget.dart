import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/faa_model.dart';
import 'package:omnifit_front/models/phase_defs.dart';
import 'package:omnifit_front/widget/phase_columns.dart';

class FaaWidget extends StatelessWidget {
  final FaaModel model;
  final int phaseCount;
  const FaaWidget({super.key, required this.model, this.phaseCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          width: double.infinity,
          // 테두리 안쪽의 실제 폭을 넘긴다 (7열 이상일 때 그림 폭을 여기서 나눈다).
          child: LayoutBuilder(
            builder: (_, constraints) => _buildTab(context, constraints.maxWidth),
          ),
        ),
      ],
    );
  }

  Widget _phaseColumn(BuildContext context, Widget label, String? path, double imgWidth) {
    if (path == null || path.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: imgWidth, height: imgWidth, child: const Center(child: Text("No data"))),
          label,
        ],
      );
    }
    final url = "$BASE_URL$path";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => showDialog1(context, url),
            child: Image.network(url, width: imgWidth, filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                SizedBox(width: imgWidth, height: imgWidth, child: const Center(child: Text("No data"))),
            ),
          ),
        ),
        label,
      ],
    );
  }

  /// [rowWidth] 는 그림 줄이 쓸 수 있는 실제 폭이다.
  Widget _buildTab(BuildContext context, double rowWidth) {
    // phase 열 구성은 phase_defs.dart 한 곳에서만 정의한다.
    final phases = phaseSeqFor(phaseCount);
    // 6열까지 쓰는 그림 폭. 7열 이상(9-phase 는 9열)은 이 폭으로 한 줄에 안
    // 들어가므로, 줄 양끝의 20px 여백을 뺀 폭을 열 수로 나눈다. 그때는 라벨도
    // 짧은 표기(Stim1)로 그림 폭 안에 쓴다 (phase_columns.dart).
    final double legacyWidth = phaseCount >= 6
        ? 110.0
        : phaseCount >= 5
            ? 130.0
            : phaseCount >= 3
                ? 180.0
                : 250.0;
    final imgWidth = phaseColumnWidth(
        columns: phases.length, available: rowWidth - 40, legacyWidth: legacyWidth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 20),
        for (final p in phases)
          _phaseColumn(
              context,
              phaseColumnLabel(p, columns: phases.length, width: imgWidth),
              model.byKey(p.key),
              imgWidth),
        const SizedBox(width: 20),
      ],
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
