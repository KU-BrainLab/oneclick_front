import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:omnifit_front/models/survey_model.dart';

/// 설문 척도 정의.
///
/// 통합 리포트와 FC 통합 리포트가 같은 목록을 써야 한다. 예전에는 두 파일이
/// 각자 PSQI 와 ISI 만 하드코딩하고 있어서, 척도를 추가하려면 양쪽을 똑같이
/// 고쳐야 했고 한쪽만 고치면 조용히 어긋났다.
///
/// 구간(cutoff)은 각 척도의 표준 기준을 따른다. 색이 진해질수록 중증도가 높다.
class SurveyScale {
  const SurveyScale({
    required this.label,
    required this.max,
    required this.interval,
    required this.cutoffs,
    required this.read,
  });

  /// 차트 제목.
  final String label;

  /// Y축 최대값. 척도의 만점보다 조금 크게 잡아 꼭대기 점이 잘리지 않게 한다.
  final double max;

  /// Y축 눈금 간격.
  final double interval;

  /// 중증도 경계값. [8, 15] 이면 구간이 0~8 / 8~15 / 15~max 세 개가 된다.
  final List<double> cutoffs;

  /// 이 척도의 값을 Questionnaire 에서 꺼내는 방법.
  final String? Function(Questionnaire q) read;
}

/// 색이 진해질수록 중증도가 높다. 통합 리포트의 기존 팔레트를 그대로 쓴다.
const _bandColors = [
  Color(0xff6db290),
  Color(0xFF44948f),
  Color(0xFF24768b),
  Color(0xFF14587a),
];

/// 경계값 목록을 구간 밴드로 바꾼다.
///
/// cutoffs 가 [8, 15], max 가 30 이면 0~8, 8~15, 15~30 세 밴드가 나온다.
/// 시작을 -1 로 두는 건 0점이 밴드 밖으로 밀려 보이지 않게 하기 위함이다.
List<PlotBand> bandsFor(SurveyScale s) {
  final edges = <double>[-1, ...s.cutoffs, s.max + 1];
  return List.generate(edges.length - 1, (i) {
    return PlotBand(
      isVisible: true,
      color: _bandColors[i.clamp(0, _bandColors.length - 1)].withAlpha(102),
      start: edges[i],
      end: edges[i + 1],
    );
  });
}

/// 리포트에 실을 설문 척도 전체.
///
/// 순서가 리포트에 그대로 나온다. 수면 관련(PSQI·ISI·ESS·IRLS)을 앞에,
/// 정서·자율신경(BAI·BDI-II·COMPASS31)을 뒤에 둔다.
const surveyScales = <SurveyScale>[
  SurveyScale(
    label: 'PSQI-K',          // 수면의 질 0~21, 5점 초과면 나쁜 편
    max: 25, interval: 5, cutoffs: [8],
    read: _psql,
  ),
  SurveyScale(
    label: 'ISI',             // 불면 심각도 0~28
    max: 35, interval: 5, cutoffs: [7, 15],
    read: _isi,
  ),
  SurveyScale(
    label: 'ESS',             // 주간 졸림 0~24
    max: 25, interval: 5, cutoffs: [10, 15],
    read: _ess,
  ),
  SurveyScale(
    label: 'IRLS',            // 하지불안 0~40
    max: 40, interval: 10, cutoffs: [10, 20, 30],
    read: _irls,
  ),
  SurveyScale(
    label: 'BAI',             // 불안 0~63
    max: 63, interval: 10, cutoffs: [7, 15, 25],
    read: _bai,
  ),
  SurveyScale(
    label: 'BDI-II',          // 우울 0~63
    max: 63, interval: 10, cutoffs: [13, 19, 28],
    read: _bdi2,
  ),
  SurveyScale(
    label: 'COMPASS-31',      // 자율신경 증상 0~100
    max: 100, interval: 20, cutoffs: [20, 40],
    read: _compass31,
  ),
];

// const 생성자에 넘기려면 톱레벨 함수여야 한다(클로저는 const 가 아니다).
String? _psql(Questionnaire q) => q.psql;
String? _isi(Questionnaire q) => q.isi;
String? _ess(Questionnaire q) => q.ess;
String? _irls(Questionnaire q) => q.irls;
String? _bai(Questionnaire q) => q.bai;
String? _bdi2(Questionnaire q) => q.bdi2;
String? _compass31(Questionnaire q) => q.compass31;
