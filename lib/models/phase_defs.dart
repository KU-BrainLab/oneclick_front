/// 실험 phase 구성의 단일 정의 (프론트).
///
/// 백엔드 CONNECTIVITY_PHASES / 클라이언트 utils/phase_defs.py 와 같은 계약을
/// 공유한다. 키 하나 = 라벨 하나 (모드와 무관). 6-phase 가 recovery1/2 대신
/// 별도의 'recovery' 키를 쓰는 것도 그 원칙 때문이다.
///
/// 지원 모드:
///   1: baseline
///   3: baseline, stimulation1, recovery1
///   5: baseline, stimulation1, recovery1, stimulation2, recovery2
///   6: baseline, stimulation1, stimulation2, stimulation3, stimulation4, recovery
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
const kStim4 = PhaseCol('stimulation4', 'Stimulation4', 'Stimulation 4', 'Stim4');
const kRecovery = PhaseCol('recovery', 'Recovery', 'Recovery', 'Rec');

/// 5/6-phase 키의 합집합, 시간 순서. 세션에 없는 phase 를 걸러내면
/// 어느 모드든 남은 것의 상대 순서가 올바른 시간 순서가 된다.
const kPhaseSuperset = [
  kBaseline, kStim1, kRec1, kStim2, kRec2, kStim3, kStim4, kRecovery,
];

const Map<int, List<PhaseCol>> kPhaseSeq = {
  1: [kBaseline],
  3: [kBaseline, kStim1, kRec1],
  5: [kBaseline, kStim1, kRec1, kStim2, kRec2],
  6: [kBaseline, kStim1, kStim2, kStim3, kStim4, kRecovery],
};

List<PhaseCol> phaseSeqFor(int phaseCount) =>
    kPhaseSeq[phaseCount] ?? kPhaseSeq[5]!;

class DiffCol {
  final int index;         // diff{index+1} 슬롯
  final String label;      // 'Stimulation1-Baseline'
  final String short;      // 'Stim1-Base'
  const DiffCol(this.index, this.label, this.short);
}

/// 인접 phase 쌍. diff 슬롯(diff1~5)은 위치 기반이라 모드마다 뜻이 다르다 —
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
};

List<DiffCol> diffSeqFor(int phaseCount) => kDiffSeq[phaseCount] ?? const [];

/// RMSSD 구간 색. 세그먼트 수(intervals-1)가 6이어도 색이 겹치지 않아야 한다.
const kSegmentColors = [
  Colors.red, Colors.orange, Colors.yellow,
  Colors.green, Colors.blue, Colors.purple,
];

/// trigger 경계값 개수(len)로 phase 개수를 판정한다.
/// 경계값은 phase+1 개다: 5-phase=6값, 6-phase=7값.
int phaseCountFromBoundaries(int boundaryCount) {
  final n = boundaryCount - 1;
  if (n >= 6) return 6;
  if (n >= 5) return 5;
  if (n >= 3) return 3;
  return 1;
}
