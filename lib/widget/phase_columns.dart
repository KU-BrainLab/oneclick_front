/// phase·diff 그림을 한 줄에 나란히 놓는 화면들이 같이 쓰는 배치 규칙
/// (EEG 결과서의 지형도·연결성·FAA, 통합·FC 통합 리포트의 그림 줄).
///
/// 6열까지는 기존 배치 그대로다. 그림 폭은 화면마다 정해 둔 값을 쓰고 라벨은
/// 긴 표기('Stimulation1')·기본 글자 크기다. 창이 좁아도 줄이지 않는다 —
/// 1/3/5/6-phase 세션의 화면은 바뀌지 않는다.
///
/// 7열([kShortLabelColumns]) 이상은 그 폭으로는 한 줄에 들어가지 않을 수 있어
/// (9-phase 는 phase 9열·diff 8열) '좁은 배치' 로 그린다:
///   - 그림 폭은 줄의 실제 폭을 열 수로 나눈 값까지 줄인다 ([phaseImageWidth]).
///   - 라벨은 짧은 표기('Stim1')·12px 로 쓰고 그림 폭 안에 가둔다. 라벨이
///     그림보다 넓으면 열 폭이 라벨을 따라가 줄 전체가 다시 넘치기 때문이다.
library;

import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/phase_defs.dart';

/// 그림 열이 [columns] 개인 줄을 좁은 배치로 그리는가.
bool isCompactPhaseRow(int columns) => columns >= kShortLabelColumns;

/// 좁은 배치의 라벨 글자 크기. diff 줄의 짧은 표기와 같은 크기다.
const double kCompactLabelFontSize = 12;

/// 그림 한 칸의 폭.
///
/// [legacyWidth] 는 그 화면이 6열까지 쓰는 폭이고, 좁은 배치에서는 넘지 않는
/// 상한이 된다. [available] 은 열들이 나눠 쓰는 폭(줄의 실제 폭에서 양끝 여백을
/// 뺀 값), [perColumnExtra] 는 열마다 그림 폭에 더 붙는 폭(테두리)이다.
double phaseColumnWidth({
  required int columns,
  required double available,
  required double legacyWidth,
  double perColumnExtra = 0,
}) {
  if (!isCompactPhaseRow(columns)) return legacyWidth;
  return phaseImageWidth(
    columns: columns,
    available: available,
    maxWidth: legacyWidth,
    perColumnExtra: perColumnExtra,
  );
}

/// 좁은 배치에서는 [label] 을 그림 폭 [width] 안에 가둔다 (그보다 넓으면 줄여
/// 그린다). 6열까지는 [label] 그대로다.
Widget fitColumnLabel(
  Widget label, {
  required int columns,
  required double width,
}) {
  if (!isCompactPhaseRow(columns)) return label;
  return SizedBox(
    width: width,
    child: FittedBox(fit: BoxFit.scaleDown, child: label),
  );
}

/// phase 그림 밑의 라벨. 6열까지는 긴 표기, 좁은 배치에서는 짧은 표기다.
Widget phaseColumnLabel(
  PhaseCol phase, {
  required int columns,
  required double width,
}) {
  if (!isCompactPhaseRow(columns)) return Text(phase.label);
  return fitColumnLabel(
    Text(phase.short, style: const TextStyle(fontSize: kCompactLabelFontSize)),
    columns: columns,
    width: width,
  );
}

/// 통합·FC 통합 리포트의 phase 그림 한 줄 (지형도·wPLI·PLV 가 같이 쓴다).
///
/// 이 줄은 화면을 캡처한 것이 그대로 PDF 가 된다. 캡처 영역 밖으로 넘친 열은
/// 오류 없이 PDF 에서 빠지므로, 열이 몇 개든 줄의 폭 안에 들어가야 한다.
class ReportPhaseImageRow extends StatelessWidget {
  /// (phase, 그림 경로). 경로가 null 이면 'No data' 칸이 된다.
  final List<(PhaseCol, String?)> phases;

  /// 통합 리포트는 spaceEvenly, FC 통합 리포트는 spaceBetween 이다.
  final MainAxisAlignment mainAxisAlignment;

  const ReportPhaseImageRow({
    super.key,
    required this.phases,
    required this.mainAxisAlignment,
  });

  /// 모든 모드 키의 합집합(시간 순서)에서 이 세션에 있는 phase 만 고른다.
  /// [byKey] 는 모델의 byKey (phase 키 -> 그림 경로) 다. 세션에 없는 phase 는
  /// null 이라 걸러지고, 남은 것의 순서가 어느 모드든 올바르다. Baseline 은
  /// 그림이 없어도 열을 둔다.
  static List<(PhaseCol, String?)> present(String? Function(String key) byKey) =>
      [
        for (final p in kPhaseSuperset)
          if (p.key == kBaseline.key || byKey(p.key) != null) (p, byKey(p.key)),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      // 6열이면 900px 폭을 넘지 않게 칸을 줄인다. 7열 이상은 줄의 실제 폭에서
      // 양끝 여백(20px 씩)을 뺀 폭을 열 수로 나눈다 — 칸마다 테두리 1px 이
      // 양쪽에 붙는다.
      final w = phaseColumnWidth(
        columns: phases.length,
        available: constraints.maxWidth - 40,
        legacyWidth: phases.length >= 6 ? 120 : 150,
        perColumnExtra: 2,
      );
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          const SizedBox(width: 20),
          for (final phase in phases)
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.3), width: 1)),
              child: Column(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: phase.$2 != null
                        ? Image.network(
                            "$BASE_URL${phase.$2}",
                            width: w,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => SizedBox(
                                width: w,
                                height: w,
                                child: const Center(child: Text("No data"))),
                          )
                        : SizedBox(
                            width: w,
                            height: w,
                            child: const Center(child: Text("No data"))),
                  ),
                  phaseColumnLabel(phase.$1, columns: phases.length, width: w),
                ],
              ),
            ),
          const SizedBox(width: 20),
        ],
      );
    });
  }
}
