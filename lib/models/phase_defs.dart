/// 실험 phase 구성의 단일 정의 (프론트).
///
/// 백엔드 CONNECTIVITY_PHASES / 클라이언트 utils/phase_defs.py 와 같은 계약을
/// 공유한다. 키 하나 = 라벨 하나 (모드와 무관). 6-phase 가 recovery1/2 대신
/// 별도의 'recovery' 키를 쓰는 것도 그 원칙 때문이다. 9-phase 의 마지막 회복은
/// 'recovery4' 이고 6-phase 의 'recovery' 와는 별개 키다 (같은 세션에 함께
/// 나오지 않는다).
///
/// 지원 모드:
///   1: baseline
///   3: baseline, stimulation1, recovery1
///   5: baseline, stimulation1, recovery1, stimulation2, recovery2
///   6: baseline, stimulation1, stimulation2, stimulation3, stimulation4, recovery
///   9: baseline, stimulation1, recovery1, stimulation2, recovery2,
///      stimulation3, recovery3, stimulation4, recovery4
///
/// phase 개수 판정 (클라이언트와 같은 규칙):
///   n = trigger 경계값 개수 - 1 (= 마커 개수).
///   - n == 6 이면 6-phase 구성.
///   - 그 밖의 n 은 9-phase 순서의 앞 min(n, 9) 개. 1, 3, 5, 9 는 정식 모드와
///     같고 2, 4, 7, 8 은 '중간에 끝난 세션' 이다.
///   - n >= 10 이면 앞 9개 마커만 쓰고 9번째 phase(recovery4)가 녹화 끝까지 간다.
///   - n <= 0 이면 1-phase.
///   한계: 마커 6개에서 끝난 9-phase 세션은 6-phase 로 해석된다 (개수만으로는
///   구분할 수 없다).
library;

import 'package:flutter/material.dart';

class PhaseCol {
  final String key;        // JSON/DB 키
  final String label;      // 'Stimulation1' — 차트 열 제목
  final String spaced;     // 'Stimulation 1' — 범례·탭 라벨
  final String short;      // 'Stim1' — 좁은 표 머리글
  const PhaseCol(this.key, this.label, this.spaced, this.short);
}

const kBaseline = PhaseCol('baseline', 'Baseline', 'Baseline', 'Baseline');
const kStim1 = PhaseCol('stimulation1', 'Stimulation1', 'Stimulation 1', 'Stim1');
const kRec1 = PhaseCol('recovery1', 'Recovery1', 'Recovery 1', 'Rec1');
const kStim2 = PhaseCol('stimulation2', 'Stimulation2', 'Stimulation 2', 'Stim2');
const kRec2 = PhaseCol('recovery2', 'Recovery2', 'Recovery 2', 'Rec2');
const kStim3 = PhaseCol('stimulation3', 'Stimulation3', 'Stimulation 3', 'Stim3');
const kRec3 = PhaseCol('recovery3', 'Recovery3', 'Recovery 3', 'Rec3');
const kStim4 = PhaseCol('stimulation4', 'Stimulation4', 'Stimulation 4', 'Stim4');
const kRec4 = PhaseCol('recovery4', 'Recovery4', 'Recovery 4', 'Rec4');
const kRecovery = PhaseCol('recovery', 'Recovery', 'Recovery', 'Rec');

/// 모든 모드(1/3/5/6/9-phase) 키의 합집합, 시간 순서. 세션에 없는 phase 를
/// 걸러내면 어느 모드든 남은 것의 상대 순서가 올바른 시간 순서가 된다.
const kPhaseSuperset = [
  kBaseline, kStim1, kRec1, kStim2, kRec2,
  kStim3, kRec3, kStim4, kRec4, kRecovery,
];

/// 한 세션의 phase 개수 상한 (9-phase).
const int kMaxPhases = 9;

const Map<int, List<PhaseCol>> kPhaseSeq = {
  1: [kBaseline],
  3: [kBaseline, kStim1, kRec1],
  5: [kBaseline, kStim1, kRec1, kStim2, kRec2],
  6: [kBaseline, kStim1, kStim2, kStim3, kStim4, kRecovery],
  9: [kBaseline, kStim1, kRec1, kStim2, kRec2, kStim3, kRec3, kStim4, kRec4],
};

/// phase 개수 -> 그 세션의 phase 목록 (판정 규칙은 파일 머리 주석).
/// 6 이면 6-phase 구성이고, 그 밖은 9-phase 순서의 앞 n 개다 (n 은 1..9 로
/// 자른다). 1/3/5/9 는 위 표의 목록 그대로다.
List<PhaseCol> phaseSeqFor(int phaseCount) {
  final registered = kPhaseSeq[phaseCount];
  if (registered != null) return registered;
  final n = phaseCount < 1
      ? 1
      : (phaseCount > kMaxPhases ? kMaxPhases : phaseCount);
  return List.unmodifiable(kPhaseSeq[kMaxPhases]!.take(n));
}

class DiffCol {
  final int index;         // diff{index+1} 슬롯
  final String label;      // 'Stimulation1-Baseline'
  final String short;      // 'Stim1-Base'
  const DiffCol(this.index, this.label, this.short);
}

/// 인접 phase 쌍. diff 슬롯(diff1~8)은 위치 기반이라 모드마다 뜻이 다르다 —
/// 라벨은 반드시 여기서 가져와야 한다.
const Map<int, List<DiffCol>> kDiffSeq = {
  1: [],
  3: [
    DiffCol(0, 'Stimulation1-Baseline', 'Stim1-Base'),
    DiffCol(1, 'Recovery1-Stimulation1', 'Rec1-Stim1'),
  ],
  5: [
    DiffCol(0, 'Stimulation1-Baseline', 'Stim1-Base'),
    DiffCol(1, 'Recovery1-Stimulation1', 'Rec1-Stim1'),
    DiffCol(2, 'Stimulation2-Recovery1', 'Stim2-Rec1'),
    DiffCol(3, 'Recovery2-Stimulation2', 'Rec2-Stim2'),
  ],
  6: [
    DiffCol(0, 'Stimulation1-Baseline', 'Stim1-Base'),
    DiffCol(1, 'Stimulation2-Stimulation1', 'Stim2-Stim1'),
    DiffCol(2, 'Stimulation3-Stimulation2', 'Stim3-Stim2'),
    DiffCol(3, 'Stimulation4-Stimulation3', 'Stim4-Stim3'),
    DiffCol(4, 'Recovery-Stimulation4', 'Rec-Stim4'),
  ],
  9: [
    DiffCol(0, 'Stimulation1-Baseline', 'Stim1-Base'),
    DiffCol(1, 'Recovery1-Stimulation1', 'Rec1-Stim1'),
    DiffCol(2, 'Stimulation2-Recovery1', 'Stim2-Rec1'),
    DiffCol(3, 'Recovery2-Stimulation2', 'Rec2-Stim2'),
    DiffCol(4, 'Stimulation3-Recovery2', 'Stim3-Rec2'),
    DiffCol(5, 'Recovery3-Stimulation3', 'Rec3-Stim3'),
    DiffCol(6, 'Stimulation4-Recovery3', 'Stim4-Rec3'),
    DiffCol(7, 'Recovery4-Stimulation4', 'Rec4-Stim4'),
  ],
};

/// phase 목록에서 인접 쌍(diff 열)을 만든다: diffK = phase[K] - phase[K-1].
/// 라벨은 '뒤-앞' 순서('Stimulation1-Baseline')이고, 짧은 표기는 phase 의
/// short 를 쓰되 Baseline 만 'Base' 로 줄인다('Stim1-Base') — kDiffSeq 에
/// 적힌 목록과 같은 규칙이다.
List<DiffCol> diffSeqOf(List<PhaseCol> phases) => List.unmodifiable([
      for (int i = 0; i + 1 < phases.length; i++)
        DiffCol(
          i,
          '${phases[i + 1].label}-${phases[i].label}',
          '${_diffShort(phases[i + 1])}-${_diffShort(phases[i])}',
        ),
    ]);

String _diffShort(PhaseCol p) => p.key == kBaseline.key ? 'Base' : p.short;

/// phase 개수 -> diff 열 목록. 등록된 모드(3/5/6/9)는 kDiffSeq 그대로다.
/// 중간에 끝난 세션(2, 4, 7, 8)은 그 세션의 phase 목록에서 유도하고,
/// 1 이하는 diff 가 없으며 10 이상은 9 와 같다.
List<DiffCol> diffSeqFor(int phaseCount) {
  if (phaseCount <= 1) return const [];
  final n = phaseCount > kMaxPhases ? kMaxPhases : phaseCount;
  return kDiffSeq[n] ?? diffSeqOf(phaseSeqFor(n));
}

/// RMSSD 구간 색. 세그먼트 수(intervals-1)가 9여도 색이 겹치지 않아야 한다.
/// 앞 6색은 6-phase 때 그대로다 (기존 모드의 색은 바뀌지 않는다). 뒤 3색은
/// 9-phase 의 7~9번째 구간용 갈색·청록·분홍으로, 흰 배경에서 잘 보이고 앞
/// 6색과 헷갈리지 않는 농도를 골랐다 (기본 농도인 Colors.brown·Colors.pink 는
/// 빨강과, Colors.teal 은 초록과 가까워서 더 어두운 갈색·청록과 더 밝은 분홍을
/// 쓴다).
const List<Color> kSegmentColors = [
  Colors.red, Colors.orange, Colors.yellow,
  Colors.green, Colors.blue, Colors.purple,
  Color(0xFF5D4037), // 갈색 (brown 700)
  Color(0xFF00695C), // 청록 (teal 800)
  Color(0xFFFF69B4), // 분홍 (hot pink)
];

/// trigger 경계값 개수(len)로 phase 개수를 판정한다 (규칙은 파일 머리 주석).
/// 경계값은 phase+1 개다: 5-phase=6값, 6-phase=7값, 9-phase=10값.
/// 결과는 1..9 다 — 경계가 11개 이상이어도 9, 2개 미만이어도 1.
int phaseCountFromBoundaries(int boundaryCount) {
  final n = boundaryCount - 1;
  if (n < 1) return 1;
  if (n > kMaxPhases) return kMaxPhases;
  return n;
}

/// trigger 가 없는 세션(옛 세션)의 phase 개수를, 응답에 있는 phase 키로 정한다.
/// 파일 머리 주석의 판정 규칙을 거꾸로 읽은 것이다: 'recovery' 는 6-phase 에만
/// 있는 키라 있으면 6 이고, 그 밖에는 9-phase 순서에서 마지막으로 있는 phase
/// 까지가 그 세션의 phase 다 (앞 n 개). 빠진 데가 없는 세션에서는 있는 phase 의
/// 개수와 같다. 가운데 phase 가 비어 있으면 개수로 세지 않고 자리로 세어서, 뒤에
/// 있는 phase 가 가려지지 않게 한다 (빈 자리는 화면에 'No data' 로 나온다).
/// stimulation3 은 9-phase 에도 있으므로 그 키로 6-phase 를 가리면 안 된다.
/// 합집합에 없는 키는 보지 않는다. 결과는 1..9 (하나도 없으면 1).
int phaseCountFromKeys(Iterable<String> presentKeys) {
  final present = presentKeys.toSet();
  if (present.contains(kRecovery.key)) return 6;
  final last = kPhaseSeq[kMaxPhases]!
      .lastIndexWhere((p) => present.contains(p.key));
  return last < 0 ? 1 : last + 1;
}

/// trigger 경계값 가운데 phase 구간에 실제로 쓰는 것(phase 수 + 1 개)만 고른다.
/// 경계가 그보다 많으면(마커 10개 이상) 앞 9개 마커와 마지막 값(녹화 끝)만
/// 남긴다 — 9번째 phase 가 녹화 끝까지 간다. 그 밖에는 받은 목록 그대로다.
List<T> phaseBoundaries<T>(List<T> boundaries) {
  final n = phaseCountFromBoundaries(boundaries.length);
  if (boundaries.length <= n + 1) return boundaries;
  return [...boundaries.take(n), boundaries.last];
}

/// 그림 열이 이 개수 이상이면 phase 라벨을 짧은 표기(PhaseCol.short)로 쓴다.
/// 기존 모드는 6열까지라 라벨이 바뀌지 않는다. 9열이면 그림 폭이 84~88px 로
/// 줄어 긴 라벨('Stimulation1')이 옆 열과 붙는다.
const int kShortLabelColumns = 7;

/// 그림 열 [columns] 개가 한 줄에 들어가는 가장 큰 그림 폭.
///
/// [available] 은 열들이 나눠 쓰는 폭이다 — 행 양끝의 고정 여백은 부르는 쪽이
/// 빼고 넘긴다. [perColumnExtra] 는 열마다 그림 폭에 더 붙는 폭이다 (양쪽
/// 테두리가 1px 씩이면 2). 즉 columns * (결과 + perColumnExtra) <= available
/// 인 가장 큰 값을 돌려준다.
///
/// [maxWidth] 를 넘지 않는다: 그 폭으로 들어가면 maxWidth 그대로이고(기존
/// 모드의 폭은 바뀌지 않는다), 줄여야 할 때만 정수 px 로 내린다. 음수가 되지는
/// 않는다. columns <= 0 이면 maxWidth.
double phaseImageWidth({
  required int columns,
  required double available,
  required double maxWidth,
  double perColumnExtra = 0,
}) {
  if (columns <= 0) return maxWidth;
  final fit = available / columns - perColumnExtra;
  if (fit.isNaN || fit >= maxWidth) return maxWidth;
  return fit <= 0 ? 0 : fit.floorToDouble();
}
