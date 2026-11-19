// lib/models/phase_defs.dart 의 9-phase 계약 테스트.
//
// 기대값은 계약(9-phase, 2026-11-19)의 문자열을 그대로 적은 것이다 — 구현의
// 상수에서 가져오지 않는다. lib/models 만 import 하므로 dart:html 이 끌려오지
// 않아 VM 에서 돈다:
//   flutter test --no-pub test/phase_defs_test.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnifit_front/models/phase_defs.dart';

// ── 계약의 값 ────────────────────────────────────────────────────────────

/// 합집합(시간 순서, 10키).
const _supersetKeys = [
  'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
  'stimulation3', 'recovery3', 'stimulation4', 'recovery4', 'recovery',
];

/// 지원 모드 (phase 개수 -> 구성).
const _modeKeys = <int, List<String>>{
  1: ['baseline'],
  3: ['baseline', 'stimulation1', 'recovery1'],
  5: ['baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2'],
  6: [
    'baseline', 'stimulation1', 'stimulation2',
    'stimulation3', 'stimulation4', 'recovery',
  ],
  9: [
    'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
    'stimulation3', 'recovery3', 'stimulation4', 'recovery4',
  ],
};

/// 키 -> [label, spaced, short].
const _labels = <String, List<String>>{
  'baseline': ['Baseline', 'Baseline', 'Baseline'],
  'stimulation1': ['Stimulation1', 'Stimulation 1', 'Stim1'],
  'recovery1': ['Recovery1', 'Recovery 1', 'Rec1'],
  'stimulation2': ['Stimulation2', 'Stimulation 2', 'Stim2'],
  'recovery2': ['Recovery2', 'Recovery 2', 'Rec2'],
  'stimulation3': ['Stimulation3', 'Stimulation 3', 'Stim3'],
  'recovery3': ['Recovery3', 'Recovery 3', 'Rec3'],
  'stimulation4': ['Stimulation4', 'Stimulation 4', 'Stim4'],
  'recovery4': ['Recovery4', 'Recovery 4', 'Rec4'],
  'recovery': ['Recovery', 'Recovery', 'Rec'],
};

/// 9-phase 의 diff 8쌍: 'index|긴 표기|짧은 표기'.
const _diff9 = [
  '0|Stimulation1-Baseline|Stim1-Base',
  '1|Recovery1-Stimulation1|Rec1-Stim1',
  '2|Stimulation2-Recovery1|Stim2-Rec1',
  '3|Recovery2-Stimulation2|Rec2-Stim2',
  '4|Stimulation3-Recovery2|Stim3-Rec2',
  '5|Recovery3-Stimulation3|Rec3-Stim3',
  '6|Stimulation4-Recovery3|Stim4-Rec3',
  '7|Recovery4-Stimulation4|Rec4-Stim4',
];

// ── 옛 구현 ──────────────────────────────────────────────────────────────
// git show HEAD:lib/models/phase_defs.dart (14e0b70, 9-phase 를 넣기 전)의 표와
// 함수를 이름만 old* 로 바꿔 그대로 옮긴 것이다. 1/3/5/6-phase 결과가 달라지지
// 않았는지 비교하는 기준이므로 새 상수(kBaseline 등)를 참조하지 않는다.

const _oBaseline = PhaseCol('baseline', 'Baseline', 'Baseline', 'Baseline');
const _oStim1 = PhaseCol('stimulation1', 'Stimulation1', 'Stimulation 1', 'Stim1');
const _oRec1 = PhaseCol('recovery1', 'Recovery1', 'Recovery 1', 'Rec1');
const _oStim2 = PhaseCol('stimulation2', 'Stimulation2', 'Stimulation 2', 'Stim2');
const _oRec2 = PhaseCol('recovery2', 'Recovery2', 'Recovery 2', 'Rec2');
const _oStim3 = PhaseCol('stimulation3', 'Stimulation3', 'Stimulation 3', 'Stim3');
const _oStim4 = PhaseCol('stimulation4', 'Stimulation4', 'Stimulation 4', 'Stim4');
const _oRecovery = PhaseCol('recovery', 'Recovery', 'Recovery', 'Rec');

const oldPhaseSuperset = [
  _oBaseline, _oStim1, _oRec1, _oStim2, _oRec2, _oStim3, _oStim4, _oRecovery,
];

const Map<int, List<PhaseCol>> oldPhaseSeq = {
  1: [_oBaseline],
  3: [_oBaseline, _oStim1, _oRec1],
  5: [_oBaseline, _oStim1, _oRec1, _oStim2, _oRec2],
  6: [_oBaseline, _oStim1, _oStim2, _oStim3, _oStim4, _oRecovery],
};

List<PhaseCol> oldPhaseSeqFor(int phaseCount) =>
    oldPhaseSeq[phaseCount] ?? oldPhaseSeq[5]!;

const Map<int, List<DiffCol>> oldDiffSeq = {
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

List<DiffCol> oldDiffSeqFor(int phaseCount) => oldDiffSeq[phaseCount] ?? const [];

const oldSegmentColors = [
  Colors.red, Colors.orange, Colors.yellow,
  Colors.green, Colors.blue, Colors.purple,
];

int oldPhaseCountFromBoundaries(int boundaryCount) {
  final n = boundaryCount - 1;
  if (n >= 6) return 6;
  if (n >= 5) return 5;
  if (n >= 3) return 3;
  return 1;
}

// ── 비교용 표기 ──────────────────────────────────────────────────────────

List<String> _keys(Iterable<PhaseCol> seq) => [for (final p in seq) p.key];

/// 키와 라벨 3종을 한 줄로 — 목록끼리 통째로 비교한다.
List<String> _phaseRows(Iterable<PhaseCol> seq) =>
    [for (final p in seq) '${p.key}|${p.label}|${p.spaced}|${p.short}'];

List<String> _diffRows(Iterable<DiffCol> seq) =>
    [for (final d in seq) '${d.index}|${d.label}|${d.short}'];

// ── 색 비교 ──────────────────────────────────────────────────────────────

/// 흰 배경과의 대비 (WCAG). 1 이면 흰색과 같고 21 이면 검정이다.
double _contrastOnWhite(Color c) => 1.05 / (c.computeLuminance() + 0.05);

double _linear(double v) => v <= 0.04045
    ? v / 12.92
    : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

/// sRGB -> CIE L*a*b* (D65).
List<double> _lab(Color c) {
  final r = _linear(c.r), g = _linear(c.g), b = _linear(c.b);
  double f(double t) => t > 216 / 24389
      ? math.pow(t, 1 / 3).toDouble()
      : (24389 / 27 * t + 16) / 116;
  final fx = f((0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047);
  final fy = f(0.2126729 * r + 0.7151522 * g + 0.0721750 * b);
  final fz = f((0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

/// 색차 ΔE*ab (CIE76).
double _deltaE(Color a, Color b) {
  final p = _lab(a), q = _lab(b);
  return math.sqrt(math.pow(p[0] - q[0], 2) +
      math.pow(p[1] - q[1], 2) +
      math.pow(p[2] - q[2], 2));
}

void main() {
  group('phase 목록', () {
    test('키와 라벨 3종이 계약의 표와 같다 (recovery3·recovery4 포함)', () {
      for (final p in kPhaseSuperset) {
        expect([p.label, p.spaced, p.short], _labels[p.key], reason: p.key);
      }
      expect(_phaseRows([kRec3, kRec4]), [
        'recovery3|Recovery3|Recovery 3|Rec3',
        'recovery4|Recovery4|Recovery 4|Rec4',
      ]);
    });

    test('합집합은 계약의 10키 순서다', () {
      expect(_keys(kPhaseSuperset), _supersetKeys);
      expect(_keys(kPhaseSuperset).toSet().length, 10);
    });

    test('모드별 목록 (1/3/5/6/9)', () {
      expect(kPhaseSeq.keys.toList()..sort(), [1, 3, 5, 6, 9]);
      expect(kMaxPhases, 9);
      for (final n in [1, 3, 5, 6, 9]) {
        expect(_keys(kPhaseSeq[n]!), _modeKeys[n], reason: '$n-phase 표');
        expect(_keys(phaseSeqFor(n)), _modeKeys[n], reason: '$n-phase');
      }
    });

    test('합집합에서 세션에 있는 키만 거르면 그 모드의 시간 순서다 (1/3/5/6/9)', () {
      for (final n in [1, 3, 5, 6, 9]) {
        final present = _modeKeys[n]!.toSet();
        final filtered = [
          for (final p in kPhaseSuperset)
            if (present.contains(p.key)) p.key,
        ];
        expect(filtered, _modeKeys[n], reason: '$n-phase');
      }
    });

    test('접두 규칙: 6 이 아닌 개수는 9-phase 순서의 앞 n 개다 (0, 2, 4, 7, 8, 10, 12)', () {
      expect(_keys(phaseSeqFor(0)), ['baseline']);
      expect(_keys(phaseSeqFor(2)), ['baseline', 'stimulation1']);
      expect(_keys(phaseSeqFor(4)),
          ['baseline', 'stimulation1', 'recovery1', 'stimulation2']);
      expect(_keys(phaseSeqFor(7)), [
        'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
        'stimulation3', 'recovery3',
      ]);
      expect(_keys(phaseSeqFor(8)), [
        'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
        'stimulation3', 'recovery3', 'stimulation4',
      ]);
      expect(_keys(phaseSeqFor(10)), _modeKeys[9]);
      expect(_keys(phaseSeqFor(12)), _modeKeys[9]);
      // 음수도 1-phase 로 본다.
      expect(_keys(phaseSeqFor(-3)), ['baseline']);
    });

    test('1/3/5 는 9-phase 순서의 앞부분이다 (표와 접두 규칙이 어긋나지 않는다)', () {
      for (final n in [1, 3, 5]) {
        expect(_modeKeys[n], _modeKeys[9]!.sublist(0, n), reason: '$n-phase');
      }
    });

    test('중간에 끝난 세션(2/4/7/8)도 합집합에서 거른 순서와 같다', () {
      for (final n in [2, 4, 7, 8]) {
        final keys = _keys(phaseSeqFor(n));
        expect(keys.length, n);
        final filtered = [
          for (final p in kPhaseSuperset)
            if (keys.contains(p.key)) p.key,
        ];
        expect(filtered, keys, reason: '$n-phase');
      }
    });

    test('돌려준 목록은 고칠 수 없다', () {
      for (final n in [0, 1, 2, 5, 6, 7, 9, 12]) {
        expect(() => phaseSeqFor(n).add(kRecovery), throwsUnsupportedError,
            reason: '$n-phase');
      }
    });
  });

  group('diff', () {
    test('9-phase: 8쌍의 라벨과 짧은 표기', () {
      expect(_diffRows(diffSeqFor(9)), _diff9);
      expect(_diffRows(kDiffSeq[9]!), _diff9);
    });

    test('등록된 모드(3/5/6/9): 개수는 phase 수 - 1, 슬롯은 0 부터 차례로', () {
      expect(kDiffSeq.keys.toList()..sort(), [1, 3, 5, 6, 9]);
      for (final n in [3, 5, 6, 9]) {
        final diffs = diffSeqFor(n);
        expect(diffs.length, n - 1, reason: '$n-phase');
        expect([for (final d in diffs) d.index],
            [for (int i = 0; i < n - 1; i++) i],
            reason: '$n-phase');
      }
    });

    test('등록된 목록은 phase 목록의 인접 쌍에서 유도한 것과 같다 (3/5/6/9)', () {
      for (final n in [3, 5, 6, 9]) {
        expect(_diffRows(diffSeqOf(phaseSeqFor(n))), _diffRows(kDiffSeq[n]!),
            reason: '$n-phase');
        expect(_diffRows(diffSeqFor(n)), _diffRows(kDiffSeq[n]!),
            reason: '$n-phase');
      }
    });

    test('유도된 diff: 7·8-phase 로 끝난 세션', () {
      expect(_diffRows(diffSeqFor(7)), [
        '0|Stimulation1-Baseline|Stim1-Base',
        '1|Recovery1-Stimulation1|Rec1-Stim1',
        '2|Stimulation2-Recovery1|Stim2-Rec1',
        '3|Recovery2-Stimulation2|Rec2-Stim2',
        '4|Stimulation3-Recovery2|Stim3-Rec2',
        '5|Recovery3-Stimulation3|Rec3-Stim3',
      ]);
      expect(_diffRows(diffSeqFor(8)), [
        '0|Stimulation1-Baseline|Stim1-Base',
        '1|Recovery1-Stimulation1|Rec1-Stim1',
        '2|Stimulation2-Recovery1|Stim2-Rec1',
        '3|Recovery2-Stimulation2|Rec2-Stim2',
        '4|Stimulation3-Recovery2|Stim3-Rec2',
        '5|Recovery3-Stimulation3|Rec3-Stim3',
        '6|Stimulation4-Recovery3|Stim4-Rec3',
      ]);
    });

    test('유도된 diff: 2·4-phase 로 끝난 세션', () {
      expect(_diffRows(diffSeqFor(2)), ['0|Stimulation1-Baseline|Stim1-Base']);
      expect(_diffRows(diffSeqFor(4)), [
        '0|Stimulation1-Baseline|Stim1-Base',
        '1|Recovery1-Stimulation1|Rec1-Stim1',
        '2|Stimulation2-Recovery1|Stim2-Rec1',
      ]);
    });

    test('1 이하는 diff 가 없고 10 이상은 9 와 같다', () {
      for (final n in [-1, 0, 1]) {
        expect(diffSeqFor(n), isEmpty, reason: '$n');
      }
      for (final n in [10, 12, 100]) {
        expect(_diffRows(diffSeqFor(n)), _diff9, reason: '$n');
      }
    });

    test('같은 슬롯이라도 모드마다 뜻이 다르다 (diff2, diff5)', () {
      expect(diffSeqFor(6)[1].label, 'Stimulation2-Stimulation1');
      expect(diffSeqFor(9)[1].label, 'Recovery1-Stimulation1');
      expect(diffSeqFor(6)[4].label, 'Recovery-Stimulation4');
      expect(diffSeqFor(9)[4].label, 'Stimulation3-Recovery2');
    });

    test('9-phase 의 앞 4쌍은 5-phase 와 같다', () {
      expect(_diffRows(diffSeqFor(9).take(4)), _diffRows(diffSeqFor(5)));
    });
  });

  group('phaseCountFromBoundaries', () {
    test('경계 0~13개 -> 1..9', () {
      expect(
        [for (int b = 0; b <= 13; b++) phaseCountFromBoundaries(b)],
        [1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 9],
      );
    });

    test('정식 모드의 경계 개수(2/4/6/7/10) -> 그 모드의 phase 목록', () {
      const boundariesOf = {1: 2, 3: 4, 5: 6, 6: 7, 9: 10};
      boundariesOf.forEach((mode, b) {
        expect(phaseCountFromBoundaries(b), mode);
        expect(_keys(phaseSeqFor(phaseCountFromBoundaries(b))), _modeKeys[mode],
            reason: '경계 $b개');
      });
    });
  });

  group('phaseCountFromKeys (trigger 가 없는 세션)', () {
    /// n-phase 세션에 있는 키 (계약 3절: 6 이면 6-phase 구성, 그 밖은 9-phase
    /// 순서의 앞 n 개).
    List<String> keysOf(int n) =>
        n == 6 ? _modeKeys[6]! : _modeKeys[9]!.sublist(0, n);

    test('판정 규칙을 거꾸로 읽은 것이다: n-phase 의 키 -> n (1..9)', () {
      for (int n = 1; n <= 9; n++) {
        expect(phaseCountFromKeys(keysOf(n)), n, reason: '$n-phase');
        // 키의 순서와 상관없다.
        expect(phaseCountFromKeys(keysOf(n).reversed), n, reason: '$n-phase');
      }
    });

    test('9-phase 는 stimulation3 이 있어도 6 이 아니다', () {
      expect(_modeKeys[9], contains('stimulation3'));
      expect(_modeKeys[9], isNot(contains('recovery')));
      expect(phaseCountFromKeys(_modeKeys[9]!), 9);
      // 7·8-phase(중간에 끝난 세션)도 stimulation3 을 갖는다.
      expect(keysOf(7), contains('stimulation3'));
      expect(phaseCountFromKeys(keysOf(7)), 7);
      expect(phaseCountFromKeys(keysOf(8)), 8);
    });

    test("'recovery' 가 있으면 6-phase 다 (6-phase 에만 있는 키)", () {
      expect(phaseCountFromKeys(_modeKeys[6]!), 6);
      expect(phaseCountFromKeys(const ['recovery']), 6);
      expect(phaseCountFromKeys(_supersetKeys), 6);
    });

    test('키가 없으면 1, 합집합에 없는 키와 중복은 세지 않는다', () {
      expect(phaseCountFromKeys(const []), 1);
      expect(phaseCountFromKeys(const ['psd', 'faa', 'trigger', 'diff1']), 1);
      expect(
          phaseCountFromKeys([..._modeKeys[5]!, 'psd', 'diff1', 'note']), 5);
      expect(phaseCountFromKeys([..._modeKeys[3]!, ..._modeKeys[3]!]), 3);
    });

    test('가운데 phase 가 비어 있어도 마지막으로 있는 phase 까지 센다', () {
      // 개수로 세면 뒤에 있는 phase 가 화면에서 가려진다 (5-phase 인데 4 로
      // 판정하면 recovery2 열이 사라진다). 빈 자리는 'No data' 로 나온다.
      List<String> without(int n, String missing) =>
          [for (final k in keysOf(n)) if (k != missing) k];
      expect(phaseCountFromKeys(without(5, 'recovery1')), 5);
      expect(phaseCountFromKeys(without(5, 'baseline')), 5);
      expect(phaseCountFromKeys(without(3, 'stimulation1')), 3);
      expect(phaseCountFromKeys(without(9, 'stimulation3')), 9);
      expect(phaseCountFromKeys(const ['recovery4']), 9);
      // 맨 뒤 phase 가 비면 그 앞까지다 (그 세션이 원래 몇 phase 였는지는
      // 키만으로 알 수 없다).
      expect(phaseCountFromKeys(without(5, 'recovery2')), 4);
      expect(phaseCountFromKeys(without(3, 'recovery1')), 2);
      // 6-phase 는 'recovery' 만 있으면 가운데가 비어도 6 이다.
      expect(phaseCountFromKeys(const ['baseline', 'stimulation4', 'recovery']), 6);
    });

    test('1/3/5/6-phase 는 예전 판정(stimulationN 이 있는지)과 같다', () {
      // page_2.dart 의 예전 키 fallback 을 그대로 옮긴 것.
      int oldCount(List<String> keys) {
        if (keys.contains('stimulation3')) return 6;
        if (keys.contains('stimulation2')) return 5;
        if (keys.contains('stimulation1')) return 3;
        return 1;
      }

      for (final n in [1, 3, 5, 6]) {
        expect(phaseCountFromKeys(_modeKeys[n]!), oldCount(_modeKeys[n]!),
            reason: '$n-phase');
      }
    });

    test('trigger 로 판정한 것과 같다: 경계 n+1 개 <-> n-phase 의 키', () {
      for (int n = 1; n <= 9; n++) {
        expect(phaseCountFromKeys(_keys(phaseSeqFor(n))),
            phaseCountFromBoundaries(n + 1),
            reason: '$n-phase');
      }
    });
  });

  group('phaseBoundaries', () {
    test('경계 10개 이하는 받은 목록 그대로다', () {
      for (int b = 0; b <= 10; b++) {
        final input = [for (int i = 0; i < b; i++) i * 5.0];
        expect(identical(phaseBoundaries(input), input), isTrue,
            reason: '경계 $b개');
      }
    });

    test('경계 11개 이상은 앞 9개 마커와 마지막 값(녹화 끝)만 남긴다', () {
      for (final b in [11, 12, 15]) {
        final input = [for (int i = 0; i < b; i++) i * 5.0];
        final out = phaseBoundaries(input);
        expect(out, [...input.sublist(0, 9), input.last], reason: '경계 $b개');
        expect(phaseCountFromBoundaries(out.length), 9);
        // 받은 목록은 건드리지 않는다.
        expect(input.length, b);
      }
    });

    test('trigger 처럼 num 이 섞인 dynamic 목록도 받는다', () {
      final List<dynamic> trigger = [0, 3, 6.5, 9, 12, 15, 18, 21, 24, 27, 30, 40];
      expect(phaseBoundaries(trigger), [0, 3, 6.5, 9, 12, 15, 18, 21, 24, 40]);
    });
  });

  group('kSegmentColors', () {
    test('9색이고 앞 6색은 6-phase 때 그대로다', () {
      expect(kSegmentColors.length, 9);
      expect(kSegmentColors.sublist(0, 6), [
        Colors.red, Colors.orange, Colors.yellow,
        Colors.green, Colors.blue, Colors.purple,
      ]);
    });

    test('9색이 서로 다르다', () {
      expect({for (final c in kSegmentColors) c.toARGB32()}.length, 9);
    });

    test('새 3색은 불투명하고 흰 배경에서 잘 보인다 (대비 2.5 이상)', () {
      // 기존 색의 대비: 주황 2.2, 초록 2.8, 빨강 3.7 — 노랑(1.2)만 약하다.
      for (final c in kSegmentColors.sublist(6)) {
        expect(c.a, 1.0, reason: '$c');
        expect(_contrastOnWhite(c), greaterThanOrEqualTo(2.5), reason: '$c');
      }
    });

    test('어느 두 색도 가깝지 않다 (색차 ΔE*ab 40 이상)', () {
      // 기존 6색에서 가장 가까운 쌍(주황-노랑)이 약 46 이다. 예를 들어
      // Colors.pink 는 빨강과 약 34 라서 이 검사에 걸린다.
      for (int i = 0; i < kSegmentColors.length; i++) {
        for (int j = i + 1; j < kSegmentColors.length; j++) {
          expect(_deltaE(kSegmentColors[i], kSegmentColors[j]),
              greaterThanOrEqualTo(40),
              reason: '${i + 1}번째와 ${j + 1}번째');
        }
      }
      expect(_deltaE(Colors.pink, Colors.red), lessThan(40));
    });
  });

  group('phaseImageWidth', () {
    // 화면의 실제 수치: bsrsr 3형제·FAA 는 테두리 안쪽 838px, 통합·FC 통합
    // 리포트는 본문 820px. 두 곳 모두 행 양끝에 20px 여백이 있고(합 40px),
    // 통합 리포트는 그림마다 테두리 1px 이 양쪽에 붙는다(열마다 2px).
    const side = 40.0;

    test('9열이 838px 에 들어간다 (perColumnExtra 0)', () {
      final w = phaseImageWidth(
          columns: 9, available: 838 - side, maxWidth: 110);
      expect(w, 88);
      expect(9 * w + side, lessThanOrEqualTo(838));
      // 들어가는 가장 큰 정수 폭이다.
      expect(9 * (w + 1) + side, greaterThan(838));
    });

    test('9열이 820px 에 들어간다 (perColumnExtra 2)', () {
      final w = phaseImageWidth(
          columns: 9, available: 820 - side, maxWidth: 120, perColumnExtra: 2);
      expect(w, 84);
      expect(9 * (w + 2) + side, lessThanOrEqualTo(820));
      expect(9 * (w + 1 + 2) + side, greaterThan(820));
    });

    test('여백을 빼지 않은 폭을 넘겨도 열의 합이 available 을 넘지 않는다', () {
      final a = phaseImageWidth(columns: 9, available: 838, maxWidth: 110);
      expect(a, 93);
      expect(9 * a, lessThanOrEqualTo(838));
      final b = phaseImageWidth(
          columns: 9, available: 820, maxWidth: 120, perColumnExtra: 2);
      expect(b, 89);
      expect(9 * (b + 2), lessThanOrEqualTo(820));
    });

    test('6열 이하는 maxWidth 그대로다 (기존 모드의 폭이 바뀌지 않는다)', () {
      // 지금 화면의 폭 사다리 (열 수 -> 그림 폭).
      double bsrsr(int n) => n >= 6 ? 110 : (n >= 5 ? 130 : 190);
      double faa(int n) => n >= 6 ? 110 : (n >= 5 ? 130 : (n >= 3 ? 180 : 250));
      double merged(int n) => n >= 6 ? 120 : 150;
      for (int n = 1; n <= 6; n++) {
        expect(
            phaseImageWidth(
                columns: n, available: 838 - side, maxWidth: bsrsr(n)),
            bsrsr(n),
            reason: 'bsrsr $n열');
        expect(
            phaseImageWidth(columns: n, available: 838 - side, maxWidth: faa(n)),
            faa(n),
            reason: 'FAA $n열');
        expect(
            phaseImageWidth(
                columns: n,
                available: 820 - side,
                maxWidth: merged(n),
                perColumnExtra: 2),
            merged(n),
            reason: '통합 리포트 $n열');
      }
    });

    test('7·8열: 들어가면 그대로, 넘치면 줄인다', () {
      // 838px: 7열은 110 그대로 들어가고(770 + 40), 8열은 99 로 줄어든다.
      expect(phaseImageWidth(columns: 7, available: 838 - side, maxWidth: 110),
          110);
      expect(phaseImageWidth(columns: 8, available: 838 - side, maxWidth: 110),
          99);
      // 820px, 테두리 2px: 7열 109, 8열 95.
      expect(
          phaseImageWidth(
              columns: 7, available: 820 - side, maxWidth: 120, perColumnExtra: 2),
          109);
      expect(
          phaseImageWidth(
              columns: 8, available: 820 - side, maxWidth: 120, perColumnExtra: 2),
          95);
    });

    test('줄일 때는 정수 px 로 내리고, 딱 맞으면 그 값이다', () {
      expect(phaseImageWidth(columns: 3, available: 100, maxWidth: 50), 33);
      expect(phaseImageWidth(columns: 9, available: 792, maxWidth: 110), 88);
      expect(phaseImageWidth(columns: 2, available: 220, maxWidth: 110), 110);
    });

    test('columns <= 0 이면 maxWidth, 폭이 모자라도 음수가 되지 않는다', () {
      expect(phaseImageWidth(columns: 0, available: 100, maxWidth: 110), 110);
      expect(phaseImageWidth(columns: -2, available: 100, maxWidth: 110), 110);
      expect(
          phaseImageWidth(
              columns: 9, available: 10, maxWidth: 110, perColumnExtra: 2),
          0);
      expect(phaseImageWidth(columns: 9, available: 0, maxWidth: 110), 0);
      // 폭 제한이 없으면(무한대) maxWidth.
      expect(
          phaseImageWidth(
              columns: 9, available: double.infinity, maxWidth: 110),
          110);
    });

    test('kShortLabelColumns 는 7 이다 (6열까지는 긴 라벨)', () {
      expect(kShortLabelColumns, 7);
    });
  });

  group('옛 구현과 같은 결과 (1/3/5/6-phase 회귀)', () {
    // 모드 -> 그 모드 세션의 trigger 경계값 개수.
    const boundariesOf = {1: 2, 3: 4, 5: 6, 6: 7};

    test('phaseSeqFor: 키와 라벨', () {
      for (final n in boundariesOf.keys) {
        expect(_phaseRows(phaseSeqFor(n)), _phaseRows(oldPhaseSeqFor(n)),
            reason: '$n-phase');
      }
    });

    test('diffSeqFor: 슬롯·라벨·짧은 표기', () {
      for (final n in boundariesOf.keys) {
        expect(_diffRows(diffSeqFor(n)), _diffRows(oldDiffSeqFor(n)),
            reason: '$n-phase');
      }
    });

    test('phaseCountFromBoundaries: 경계 2/4/6/7개', () {
      boundariesOf.forEach((mode, b) {
        expect(oldPhaseCountFromBoundaries(b), mode, reason: '옛 구현, 경계 $b개');
        expect(phaseCountFromBoundaries(b), oldPhaseCountFromBoundaries(b),
            reason: '경계 $b개');
      });
    });

    test('경계 개수에서 구한 phase·diff 목록', () {
      for (final b in boundariesOf.values) {
        final now = phaseCountFromBoundaries(b);
        final old = oldPhaseCountFromBoundaries(b);
        expect(_phaseRows(phaseSeqFor(now)), _phaseRows(oldPhaseSeqFor(old)),
            reason: '경계 $b개');
        expect(_diffRows(diffSeqFor(now)), _diffRows(oldDiffSeqFor(old)),
            reason: '경계 $b개');
      }
    });

    test('합집합: 새 키 둘을 빼면 옛 8키와 순서·라벨이 같다', () {
      final withoutNew = kPhaseSuperset
          .where((p) => p.key != 'recovery3' && p.key != 'recovery4');
      expect(_phaseRows(withoutNew), _phaseRows(oldPhaseSuperset));
      // 옛 합집합에서 거르던 화면(1/3/5/6-phase)은 새 합집합에서도 같은 순서다.
      for (final n in boundariesOf.keys) {
        final present = _keys(oldPhaseSeqFor(n)).toSet();
        expect(
          [for (final p in kPhaseSuperset) if (present.contains(p.key)) p.key],
          [for (final p in oldPhaseSuperset) if (present.contains(p.key)) p.key],
          reason: '$n-phase',
        );
      }
    });

    test('구간 색: 앞 6색', () {
      expect(kSegmentColors.sublist(0, oldSegmentColors.length),
          oldSegmentColors);
    });

    test('의도된 변경: 옛 판정과 달라지는 경계 개수는 3, 5 와 8 이상뿐이다', () {
      final changed = [
        for (int b = 0; b <= 13; b++)
          if (phaseCountFromBoundaries(b) != oldPhaseCountFromBoundaries(b)) b,
      ];
      expect(changed, [3, 5, 8, 9, 10, 11, 12, 13]);
    });
  });
}
