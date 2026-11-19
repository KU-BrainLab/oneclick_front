// phase 를 키별 고정 필드로 읽는 모델 9종(phase 모델 4종, diff 모델 5종)과
// trigger 경계로 구간을 나누는 모델 2종의 테스트.
//
// JSON 은 백엔드 EEGSerializer 응답 모양을 흉내 낸 것이다. lib/models 만
// import 하므로 VM 에서 돈다:
//   flutter test --no-pub test/phase_models_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnifit_front/models/connectivity2_model.dart';
import 'package:omnifit_front/models/connectivity_model.dart';
import 'package:omnifit_front/models/diff_connectivity2_model.dart';
import 'package:omnifit_front/models/diff_connectivity_model.dart';
import 'package:omnifit_front/models/diff_stage_connectivity_model.dart';
import 'package:omnifit_front/models/diff_stage_topography_model.dart';
import 'package:omnifit_front/models/diff_topography_model.dart';
import 'package:omnifit_front/models/faa_model.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:omnifit_front/models/phase_defs.dart';
import 'package:omnifit_front/models/sleep_phase_distribution_model.dart';
import 'package:omnifit_front/models/topography_model.dart';

const _bands = ['delta', 'theta', 'alpha', 'sigma', 'beta', 'gamma'];
const _stages = ['wake', 'n1', 'n2', 'n3', 'rem'];

// 계약의 키 목록 (구현의 상수에서 가져오지 않는다).
const _allPhases = [
  'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
  'stimulation3', 'recovery3', 'stimulation4', 'recovery4', 'recovery',
];
const _phases5 = [
  'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
];
const _phases6 = [
  'baseline', 'stimulation1', 'stimulation2',
  'stimulation3', 'stimulation4', 'recovery',
];
const _phases9 = [
  'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
  'stimulation3', 'recovery3', 'stimulation4', 'recovery4',
];

String _url(String owner, String field) => '/media/$owner/$field.png';

/// phase 한 개의 객체 (EEGParameter 의 대역별 그림 3종).
Map<String, dynamic> _phaseObject(String owner) => {
      for (final b in _bands) ...{
        'topography_$b': _url(owner, 'topography_$b'),
        'connectivity_$b': _url(owner, 'connectivity_$b'),
        'connectivity2_$b': _url(owner, 'connectivity2_$b'),
      },
    };

/// diff 한 개의 객체 (EEGDiffParameter: 위 3종 + 수면단계별 그림 2종).
Map<String, dynamic> _diffObject(String owner) => {
      ..._phaseObject(owner),
      for (final b in _bands)
        for (final s in _stages) ...{
          'topography_${b}_$s': _url(owner, 'topography_${b}_$s'),
          'connectivity_${b}_$s': _url(owner, 'connectivity_${b}_$s'),
        },
    };

/// EEG 응답. 세션에 없는 phase·diff 는 서버가 null 로 내려준다.
/// [omitAbsent] 면 null 대신 키 자체가 없다 (새 필드를 모르는 옛 서버 응답).
/// diff 는 [diffCount] 개(기본: phase 수 - 1).
Map<String, dynamic> _eegJson(
  List<String> phases, {
  int? diffCount,
  bool omitAbsent = false,
}) {
  final nDiff = diffCount ?? phases.length - 1;
  final json = <String, dynamic>{};
  final faa = <String, dynamic>{};
  for (final k in _allPhases) {
    if (phases.contains(k)) {
      json[k] = _phaseObject(k);
      faa['faa_$k'] = _url('faa', 'faa_$k');
    } else if (!omitAbsent) {
      json[k] = null;
      faa['faa_$k'] = null;
    }
  }
  for (int i = 1; i <= 8; i++) {
    if (i <= nDiff) {
      json['diff$i'] = _diffObject('diff$i');
    } else if (!omitAbsent) {
      json['diff$i'] = null;
    }
  }
  json['faa'] = faa;
  return json;
}

/// phase 마다 [minutes] 분씩인 trigger 경계값 (경계 [boundaries] 개).
List<double> _evenTrigger(int boundaries, {double minutes = 2}) =>
    [for (int i = 0; i < boundaries; i++) i * minutes];

/// 구간 i 의 모든 epoch 을 수면단계 (i % 5) 로 채운다 (1분 = 2 epoch).
List<int> _stagesByInterval(List<double> trigger) => [
      for (int i = 0; i + 1 < trigger.length; i++)
        for (int e = 0; e < ((trigger[i + 1] - trigger[i]) * 2).round(); e++)
          i % 5,
    ];

/// 수면단계 [stage] 만 100% 인 행.
List<double> _only(int stage) =>
    [for (int s = 0; s < 5; s++) s == stage ? 100.0 : 0.0];

/// 구간마다 [perSegment] 개씩인 RMSSD 값.
List<double> _rmssd(int segments, {int perSegment = 10}) =>
    [for (int i = 0; i < segments * perSegment; i++) 20.0 + i % 7];

/// 구간별 색 (구간 안의 점이 모두 같은 색인지도 본다).
List<Color> _segmentColors(MultiColorLineChartModel m, int segments,
    {int perSegment = 10}) {
  expect(m.dataList.length, segments * perSegment);
  final colors = <Color>[];
  for (int s = 0; s < segments; s++) {
    final points = m.dataList.sublist(s * perSegment, (s + 1) * perSegment);
    expect({for (final p in points) p.lineColor}.length, 1,
        reason: '${s + 1}번째 구간의 색이 섞였다');
    colors.add(points.first.lineColor);
  }
  return colors;
}

void main() {
  group('phase 모델 4종 (topography, connectivity, connectivity2, faa)', () {
    test('recovery3·recovery4 를 JSON 에서 읽어 byKey 로 돌려준다', () {
      final json = _eegJson(_phases9);
      for (final b in _bands) {
        final topo = TopographyModel.fromJson(json, b);
        final conn = ConnectivityModel.fromJson(json, b);
        final conn2 = Connectivity2Model.fromJson(json, b);
        for (final k in ['recovery3', 'recovery4']) {
          expect(topo.byKey(k), _url(k, 'topography_$b'));
          expect(conn.byKey(k), _url(k, 'connectivity_$b'));
          expect(conn2.byKey(k), _url(k, 'connectivity2_$b'));
        }
      }
      final faa = FaaModel.fromJson(json['faa']);
      expect(faa.byKey('recovery3'), '/media/faa/faa_recovery3.png');
      expect(faa.byKey('recovery4'), '/media/faa/faa_recovery4.png');
    });

    test('새 필드를 직접 읽을 수 있다 (통합 리포트는 byKey 가 아니라 필드로 읽는다)', () {
      final json = _eegJson(_phases9);
      final topo = TopographyModel.fromJson(json, 'alpha');
      expect(topo.recovery3, '/media/recovery3/topography_alpha.png');
      expect(topo.recovery4, '/media/recovery4/topography_alpha.png');
      final conn = ConnectivityModel.fromJson(json, 'alpha');
      expect(conn.recovery3, '/media/recovery3/connectivity_alpha.png');
      expect(conn.recovery4, '/media/recovery4/connectivity_alpha.png');
      final conn2 = Connectivity2Model.fromJson(json, 'alpha');
      expect(conn2.recovery3, '/media/recovery3/connectivity2_alpha.png');
      expect(conn2.recovery4, '/media/recovery4/connectivity2_alpha.png');
      final faa = FaaModel.fromJson(json['faa']);
      expect(faa.faa_recovery3, '/media/faa/faa_recovery3.png');
      expect(faa.faa_recovery4, '/media/faa/faa_recovery4.png');
    });

    test('9-phase 세션: 9개 키는 값이 있고 6-phase 의 recovery 는 null', () {
      final json = _eegJson(_phases9);
      final topo = TopographyModel.fromJson(json, 'delta');
      final conn = ConnectivityModel.fromJson(json, 'delta');
      final conn2 = Connectivity2Model.fromJson(json, 'delta');
      final faa = FaaModel.fromJson(json['faa']);
      for (final k in _phases9) {
        expect(topo.byKey(k), _url(k, 'topography_delta'), reason: k);
        expect(conn.byKey(k), _url(k, 'connectivity_delta'), reason: k);
        expect(conn2.byKey(k), _url(k, 'connectivity2_delta'), reason: k);
        expect(faa.byKey(k), _url('faa', 'faa_$k'), reason: k);
      }
      expect(topo.byKey('recovery'), isNull);
      expect(conn.byKey('recovery'), isNull);
      expect(conn2.byKey('recovery'), isNull);
      expect(faa.byKey('recovery'), isNull);
    });

    test('phase_defs 합집합의 모든 키를 byKey 가 안다 (case 누락 방지)', () {
      expect([for (final p in kPhaseSuperset) p.key], _allPhases);
      final json = _eegJson(_allPhases);
      final topo = TopographyModel.fromJson(json, 'gamma');
      final conn = ConnectivityModel.fromJson(json, 'gamma');
      final conn2 = Connectivity2Model.fromJson(json, 'gamma');
      final faa = FaaModel.fromJson(json['faa']);
      for (final p in kPhaseSuperset) {
        expect(topo.byKey(p.key), _url(p.key, 'topography_gamma'));
        expect(conn.byKey(p.key), _url(p.key, 'connectivity_gamma'));
        expect(conn2.byKey(p.key), _url(p.key, 'connectivity2_gamma'));
        expect(faa.byKey(p.key), _url('faa', 'faa_${p.key}'));
      }
    });

    test('없는 키는 null: 5-phase 세션의 recovery3·recovery4', () {
      // 서버가 null 로 내려주는 경우와, 키 자체가 없는 경우(옛 서버) 둘 다.
      for (final omit in [false, true]) {
        final json = _eegJson(_phases5, omitAbsent: omit);
        final topo = TopographyModel.fromJson(json, 'theta');
        final conn = ConnectivityModel.fromJson(json, 'theta');
        final conn2 = Connectivity2Model.fromJson(json, 'theta');
        final faa = FaaModel.fromJson(json['faa']);
        for (final k in ['recovery3', 'recovery4', 'stimulation3', 'recovery']) {
          expect(topo.byKey(k), isNull, reason: '$k omit=$omit');
          expect(conn.byKey(k), isNull, reason: '$k omit=$omit');
          expect(conn2.byKey(k), isNull, reason: '$k omit=$omit');
          expect(faa.byKey(k), isNull, reason: '$k omit=$omit');
        }
        expect(topo.recovery3, isNull);
        expect(topo.recovery4, isNull);
        expect(faa.faa_recovery3, isNull);
        expect(faa.faa_recovery4, isNull);
        // 있는 키는 그대로 읽힌다.
        for (final k in _phases5) {
          expect(topo.byKey(k), _url(k, 'topography_theta'), reason: k);
          expect(conn.byKey(k), _url(k, 'connectivity_theta'), reason: k);
          expect(conn2.byKey(k), _url(k, 'connectivity2_theta'), reason: k);
          expect(faa.byKey(k), _url('faa', 'faa_$k'), reason: k);
        }
      }
    });

    test('없는 키는 null: 6-phase 세션의 recovery1~4', () {
      final json = _eegJson(_phases6);
      final topo = TopographyModel.fromJson(json, 'beta');
      final faa = FaaModel.fromJson(json['faa']);
      for (final k in ['recovery1', 'recovery2', 'recovery3', 'recovery4']) {
        expect(topo.byKey(k), isNull, reason: k);
        expect(faa.byKey(k), isNull, reason: k);
      }
      for (final k in _phases6) {
        expect(topo.byKey(k), _url(k, 'topography_beta'), reason: k);
        expect(faa.byKey(k), _url('faa', 'faa_$k'), reason: k);
      }
    });

    test('모르는 키와 그림이 빠진 phase 객체는 null', () {
      final json = _eegJson(_phases9);
      final topo = TopographyModel.fromJson(json, 'alpha');
      final faa = FaaModel.fromJson(json['faa']);
      for (final k in ['recovery5', 'stimulation5', 'Recovery3', 'faa_recovery3', '']) {
        expect(topo.byKey(k), isNull, reason: "'$k'");
        expect(faa.byKey(k), isNull, reason: "'$k'");
      }
      // phase 객체는 있는데 그 대역의 그림 키가 없다.
      json['recovery3'] = <String, dynamic>{};
      expect(TopographyModel.fromJson(json, 'alpha').byKey('recovery3'), isNull);
      expect(ConnectivityModel.fromJson(json, 'alpha').byKey('recovery3'), isNull);
      expect(Connectivity2Model.fromJson(json, 'alpha').byKey('recovery3'), isNull);
    });
  });

  group('diff 모델 5종', () {
    test('diff6~diff8 을 JSON 에서 읽어 byIndex(5~7) 로 돌려준다', () {
      final json = _eegJson(_phases9);
      for (final b in _bands) {
        final topo = DiffTopographyModel.fromJson(json, b);
        final conn = DiffConnectivityModel.fromJson(json, b);
        final conn2 = DiffConnectivity2Model.fromJson(json, b);
        for (int i = 5; i <= 7; i++) {
          final d = 'diff${i + 1}';
          expect(topo.byIndex(i), _url(d, 'topography_$b'));
          expect(conn.byIndex(i), _url(d, 'connectivity_$b'));
          expect(conn2.byIndex(i), _url(d, 'connectivity2_$b'));
        }
        for (final s in _stages) {
          final stageTopo = DiffStageTopographyModel.fromJson(json, b, s);
          final stageConn = DiffStageConnectivityModel.fromJson(json, b, s);
          for (int i = 5; i <= 7; i++) {
            final d = 'diff${i + 1}';
            expect(stageTopo.byIndex(i), _url(d, 'topography_${b}_$s'));
            expect(stageConn.byIndex(i), _url(d, 'connectivity_${b}_$s'));
          }
        }
      }
    });

    test('새 필드를 직접 읽을 수 있다', () {
      final json = _eegJson(_phases9);
      final topo = DiffTopographyModel.fromJson(json, 'sigma');
      expect(topo.diff6, '/media/diff6/topography_sigma.png');
      expect(topo.diff7, '/media/diff7/topography_sigma.png');
      expect(topo.diff8, '/media/diff8/topography_sigma.png');
      final conn = DiffConnectivityModel.fromJson(json, 'sigma');
      expect([conn.diff6, conn.diff7, conn.diff8], [
        '/media/diff6/connectivity_sigma.png',
        '/media/diff7/connectivity_sigma.png',
        '/media/diff8/connectivity_sigma.png',
      ]);
      final conn2 = DiffConnectivity2Model.fromJson(json, 'sigma');
      expect([conn2.diff6, conn2.diff7, conn2.diff8], [
        '/media/diff6/connectivity2_sigma.png',
        '/media/diff7/connectivity2_sigma.png',
        '/media/diff8/connectivity2_sigma.png',
      ]);
      final stageTopo = DiffStageTopographyModel.fromJson(json, 'sigma', 'n2');
      expect([stageTopo.diff6, stageTopo.diff7, stageTopo.diff8], [
        '/media/diff6/topography_sigma_n2.png',
        '/media/diff7/topography_sigma_n2.png',
        '/media/diff8/topography_sigma_n2.png',
      ]);
      final stageConn = DiffStageConnectivityModel.fromJson(json, 'sigma', 'n2');
      expect([stageConn.diff6, stageConn.diff7, stageConn.diff8], [
        '/media/diff6/connectivity_sigma_n2.png',
        '/media/diff7/connectivity_sigma_n2.png',
        '/media/diff8/connectivity_sigma_n2.png',
      ]);
    });

    test('9-phase 세션: byIndex(0~7) 은 diff1~diff8, 범위 밖은 null', () {
      final json = _eegJson(_phases9);
      final topo = DiffTopographyModel.fromJson(json, 'delta');
      final conn = DiffConnectivityModel.fromJson(json, 'delta');
      final conn2 = DiffConnectivity2Model.fromJson(json, 'delta');
      final stageTopo = DiffStageTopographyModel.fromJson(json, 'delta', 'rem');
      final stageConn = DiffStageConnectivityModel.fromJson(json, 'delta', 'rem');
      for (int i = 0; i < 8; i++) {
        final d = 'diff${i + 1}';
        expect(topo.byIndex(i), _url(d, 'topography_delta'), reason: d);
        expect(conn.byIndex(i), _url(d, 'connectivity_delta'), reason: d);
        expect(conn2.byIndex(i), _url(d, 'connectivity2_delta'), reason: d);
        expect(stageTopo.byIndex(i), _url(d, 'topography_delta_rem'), reason: d);
        expect(stageConn.byIndex(i), _url(d, 'connectivity_delta_rem'), reason: d);
      }
      for (final i in [-1, 8, 9, 100]) {
        expect(topo.byIndex(i), isNull, reason: '$i');
        expect(conn.byIndex(i), isNull, reason: '$i');
        expect(conn2.byIndex(i), isNull, reason: '$i');
        expect(stageTopo.byIndex(i), isNull, reason: '$i');
        expect(stageConn.byIndex(i), isNull, reason: '$i');
      }
    });

    test('diffSeqFor 가 내는 모든 슬롯을 byIndex 가 안다 (case 누락 방지)', () {
      final json = _eegJson(_phases9);
      final topo = DiffTopographyModel.fromJson(json, 'beta');
      final conn = DiffConnectivityModel.fromJson(json, 'beta');
      final conn2 = DiffConnectivity2Model.fromJson(json, 'beta');
      final stageTopo = DiffStageTopographyModel.fromJson(json, 'beta', 'wake');
      final stageConn = DiffStageConnectivityModel.fromJson(json, 'beta', 'wake');
      for (final n in [2, 3, 4, 5, 6, 7, 8, 9, 12]) {
        for (final d in diffSeqFor(n)) {
          final owner = 'diff${d.index + 1}';
          expect(topo.byIndex(d.index), _url(owner, 'topography_beta'));
          expect(conn.byIndex(d.index), _url(owner, 'connectivity_beta'));
          expect(conn2.byIndex(d.index), _url(owner, 'connectivity2_beta'));
          expect(stageTopo.byIndex(d.index), _url(owner, 'topography_beta_wake'));
          expect(stageConn.byIndex(d.index), _url(owner, 'connectivity_beta_wake'));
        }
      }
    });

    test('없는 diff 는 null: 5-phase 세션의 diff5~diff8', () {
      for (final omit in [false, true]) {
        final json = _eegJson(_phases5, omitAbsent: omit);
        final topo = DiffTopographyModel.fromJson(json, 'theta');
        final conn = DiffConnectivityModel.fromJson(json, 'theta');
        final conn2 = DiffConnectivity2Model.fromJson(json, 'theta');
        final stageTopo = DiffStageTopographyModel.fromJson(json, 'theta', 'n3');
        final stageConn = DiffStageConnectivityModel.fromJson(json, 'theta', 'n3');
        for (int i = 0; i < 4; i++) {
          final d = 'diff${i + 1}';
          expect(topo.byIndex(i), _url(d, 'topography_theta'), reason: d);
          expect(conn.byIndex(i), _url(d, 'connectivity_theta'), reason: d);
          expect(conn2.byIndex(i), _url(d, 'connectivity2_theta'), reason: d);
          expect(stageTopo.byIndex(i), _url(d, 'topography_theta_n3'), reason: d);
          expect(stageConn.byIndex(i), _url(d, 'connectivity_theta_n3'), reason: d);
        }
        for (int i = 4; i < 8; i++) {
          expect(topo.byIndex(i), isNull, reason: 'diff${i + 1} omit=$omit');
          expect(conn.byIndex(i), isNull, reason: 'diff${i + 1} omit=$omit');
          expect(conn2.byIndex(i), isNull, reason: 'diff${i + 1} omit=$omit');
          expect(stageTopo.byIndex(i), isNull, reason: 'diff${i + 1} omit=$omit');
          expect(stageConn.byIndex(i), isNull, reason: 'diff${i + 1} omit=$omit');
        }
        expect([topo.diff6, topo.diff7, topo.diff8], [null, null, null]);
      }
    });

    test('없는 diff 는 null: 6-phase 세션은 diff5 까지', () {
      final json = _eegJson(_phases6);
      final topo = DiffTopographyModel.fromJson(json, 'alpha');
      final stageConn = DiffStageConnectivityModel.fromJson(json, 'alpha', 'n1');
      expect(topo.byIndex(4), '/media/diff5/topography_alpha.png');
      expect(stageConn.byIndex(4), '/media/diff5/connectivity_alpha_n1.png');
      for (int i = 5; i < 8; i++) {
        expect(topo.byIndex(i), isNull, reason: 'diff${i + 1}');
        expect(stageConn.byIndex(i), isNull, reason: 'diff${i + 1}');
      }
    });
  });

  group('SleepPhaseDistributionModel (trigger 경계 -> phase 별 수면단계 비율)', () {
    test('9-phase: 9행, 라벨은 짧은 표기', () {
      final trigger = _evenTrigger(10);
      final stages = _stagesByInterval(trigger);
      // 마지막 phase(Rec4) 4 epoch 을 N3 2개 + REM 2개로 바꾼다.
      stages.setRange(32, 36, [3, 3, 4, 4]);
      final m = SleepPhaseDistributionModel.fromJson(stages, trigger);
      expect(m.phaseLabels, [
        'Baseline', 'Stim1', 'Rec1', 'Stim2', 'Rec2',
        'Stim3', 'Rec3', 'Stim4', 'Rec4',
      ]);
      expect(m.data, [
        _only(0), _only(1), _only(2), _only(3), _only(4),
        _only(0), _only(1), _only(2),
        [0.0, 0.0, 0.0, 50.0, 50.0],
      ]);
    });

    test('1/3/5/6-phase: 행 수와 라벨이 예전과 같다', () {
      const expected = {
        2: ['Baseline'],
        4: ['Baseline', 'Stim1', 'Rec1'],
        6: ['Baseline', 'Stim1', 'Rec1', 'Stim2', 'Rec2'],
        7: ['Baseline', 'Stim1', 'Stim2', 'Stim3', 'Stim4', 'Rec'],
      };
      expected.forEach((boundaries, labels) {
        final trigger = _evenTrigger(boundaries);
        final m = SleepPhaseDistributionModel.fromJson(
            _stagesByInterval(trigger), trigger);
        expect(m.phaseLabels, labels, reason: '경계 $boundaries개');
        expect(m.data, [for (int i = 0; i < labels.length; i++) _only(i % 5)],
            reason: '경계 $boundaries개');
      });
    });

    test('중간에 끝난 세션(경계 3/5/8/9개): 9-phase 순서의 앞부분', () {
      const nine = [
        'Baseline', 'Stim1', 'Rec1', 'Stim2', 'Rec2',
        'Stim3', 'Rec3', 'Stim4', 'Rec4',
      ];
      for (final boundaries in [3, 5, 8, 9]) {
        final trigger = _evenTrigger(boundaries);
        final m = SleepPhaseDistributionModel.fromJson(
            _stagesByInterval(trigger), trigger);
        expect(m.phaseLabels, nine.sublist(0, boundaries - 1),
            reason: '경계 $boundaries개');
        expect(m.data, [for (int i = 0; i < boundaries - 1; i++) _only(i % 5)],
            reason: '경계 $boundaries개');
      }
    });

    test('경계 11개 이상: 9번째 phase 가 녹화 끝까지 간다', () {
      // 경계 12개(2분 간격, 끝 22분). 9번째 phase 는 16분~22분 = epoch 32~43.
      final trigger = _evenTrigger(12);
      final stages = _stagesByInterval(trigger);
      stages.setRange(32, 44, [3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4]);
      final m = SleepPhaseDistributionModel.fromJson(stages, trigger);
      expect(m.phaseLabels.length, 9);
      expect(m.phaseLabels.last, 'Rec4');
      expect(m.data.sublist(0, 8), [for (int i = 0; i < 8; i++) _only(i % 5)]);
      expect(m.data[8][3], closeTo(100 / 3, 1e-9));
      expect(m.data[8][4], closeTo(200 / 3, 1e-9));
      expect(m.data[8].sublist(0, 3), [0.0, 0.0, 0.0]);
    });

    test('경계가 2개 미만이면 행이 없다', () {
      for (final trigger in [<double>[], <double>[0]]) {
        final m = SleepPhaseDistributionModel.fromJson([0, 1, 2, 3], trigger);
        expect(m.data, isEmpty);
        expect(m.phaseLabels, isEmpty);
      }
    });
  });

  group('MultiColorLineChartModel (RMSSD 구간 색)', () {
    MultiColorLineChartModel build(List<double> intervals, int segments,
            {double maxX = 50}) =>
        MultiColorLineChartModel.fromJson(_rmssd(segments),
            finalAxisMaxX: maxX, intervals: intervals);

    test('9-phase: 구간 9개가 팔레트 순서대로 서로 다른 색이다', () {
      final intervals = _evenTrigger(10, minutes: 5);
      final m = build(intervals, 9);
      final colors = _segmentColors(m, 9);
      expect(colors, kSegmentColors);
      expect({for (final c in colors) c.toARGB32()}.length, 9);
      expect(m.intervalX, intervals);
      expect(m.maxX, 45);
      // 구간 s 의 점은 경계 s ~ s+1 사이에 놓인다.
      for (int s = 0; s < 9; s++) {
        expect(m.dataList[s * 10].x, intervals[s]);
        expect(m.dataList[s * 10 + 9].x, intervals[s + 1]);
      }
    });

    test('1/3/5/6-phase: 구간과 색이 예전과 같다', () {
      const oldColors = [
        Colors.red, Colors.orange, Colors.yellow,
        Colors.green, Colors.blue, Colors.purple,
      ];
      for (final segments in [1, 3, 5, 6]) {
        final intervals = _evenTrigger(segments + 1, minutes: 5);
        final m = build(intervals, segments);
        expect(_segmentColors(m, segments), oldColors.sublist(0, segments),
            reason: '$segments-phase');
        expect(identical(m.intervalX, intervals), isTrue,
            reason: '$segments-phase');
        expect(m.maxX, segments * 5.0, reason: '$segments-phase');
      }
    });

    test('경계 11개 이상: 구간은 9개이고 9번째가 녹화 끝까지 간다', () {
      final intervals = _evenTrigger(12, minutes: 5); // 0 ~ 55분
      final m = build(intervals, 9);
      expect(m.intervalX, [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 55.0]);
      expect(m.maxX, 55);
      expect(_segmentColors(m, 9), kSegmentColors);
      expect(m.dataList[80].x, 40);
      expect(m.dataList.last.x, 55);
      // 받은 목록은 건드리지 않는다.
      expect(intervals.length, 12);
    });

    test('trigger 가 없으면 예전처럼 5등분한다', () {
      final m = build(const [], 5, maxX: 50);
      expect(m.intervalX, [0.0, 10.0, 20.0, 30.0, 40.0, 50.0]);
      expect(_segmentColors(m, 5), [
        Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue,
      ]);
    });
  });
}
