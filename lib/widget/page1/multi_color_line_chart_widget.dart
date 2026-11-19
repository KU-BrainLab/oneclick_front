import 'package:flutter/material.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:omnifit_front/models/phase_defs.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MultiColorLineChartWidget extends StatelessWidget {
  final MultiColorLineChartModel model;
  // 1. 외부에서 maxX 값을 받기 위한 변수 추가
  final double maxX;

  // 2. 생성자에 required this.maxX 추가
  const MultiColorLineChartWidget({
    Key? key, 
    required this.model,
    required this.maxX,
  }) : super(key: key);

  /// 구간이 이 개수 이상이면 범례를 차트 위에 겹치지 않고 아래에 둔다.
  /// 기존 모드는 6구간까지라 범례가 그대로다. 9-phase 는 범례가 9줄(약 140px)
  /// 이라 약 300px 높이의 차트 오른쪽 위 — 마지막 구간들의 곡선 — 를 덮는다.
  static const int _legendBelowSegments = 7;

  /// 아래 범례의 항목 하나 폭. 본문 폭 820px 에 5개가 들어가 9구간이 5 + 4
  /// 두 줄이 된다.
  static const double _legendItemWidth = 150;

  String _segmentLabel(int s) {
    final seq = phaseSeqFor(phaseCountFromBoundaries(model.intervalX.length));
    return s < seq.length ? seq[s].spaced : 'Phase ${s + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final chart = SfCartesianChart(
        primaryXAxis: NumericAxis(
          minimum: model.minX,
          maximum: maxX,
          title: const AxisTitle(
            text: "Time(m)",
            alignment: ChartAlignment.center, 
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          )
        ),          
        primaryYAxis: NumericAxis(minimum: model.minY, maximum: model.maxY, interval: model.intervalY),
          series: <CartesianSeries>[
            LineSeries<ChartData, double>(
              animationDuration: 0,
              dataSource: model.dataList,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              pointColorMapper: (ChartData data, _) => data.lineColor,
              width: 2,
            ),
          ],
        );
    final segments = model.intervalX.length - 1;
    if (segments >= _legendBelowSegments) {
      // 범례를 차트 아래로 내린다. 색과 라벨은 겹쳐 그리는 범례와 같다.
      return Column(
        children: [
          chart,
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 2,
            children: [
              for (int s = 0; s < segments; s++)
                SizedBox(
                  width: _legendItemWidth,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 2,
                        color: kSegmentColors[s % kSegmentColors.length],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_segmentLabel(s),
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      );
    }
    return Stack(
      children: [
        chart,
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.4))),
            width: 140,
            child: Column(
              children: [
                // 세그먼트 수(= phase 수)에 맞춰 범례를 만든다. 색은 차트의
                // 세그먼트 색(kSegmentColors)과 같은 순서다.
                for (int s = 0; s < model.intervalX.length - 1; s++)
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 2,
                        color: kSegmentColors[s % kSegmentColors.length],
                      ),
                      const Spacer(),
                      Text(_segmentLabel(s),
                          style: const TextStyle(fontSize: 10)),
                    ],
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}