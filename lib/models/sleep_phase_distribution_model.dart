import 'dart:math';

import 'package:omnifit_front/models/phase_defs.dart';

// stages: 0=Wake, 1=N1, 2=N2, 3=N3, 4=REM
// trigger: phase+1 개의 분 단위 경계값 → epoch index = trigger[i] * 2 (30s per epoch)

class SleepPhaseDistributionModel {
  static const stageLabels = ['W', 'N1', 'N2', 'N3', 'REM'];

  // [phaseIndex][stageIndex] = percentage (0~100)
  final List<List<double>> data;

  /// 이 세션의 phase 라벨 (모드에 따라 1~9개).
  final List<String> phaseLabels;

  SleepPhaseDistributionModel({required this.data, required this.phaseLabels});

  factory SleepPhaseDistributionModel.fromJson(
    List<dynamic> sleepStage,
    List<dynamic> trigger,
  ) {
    final total = sleepStage.length;
    List<List<double>> data = [];

    // 경계가 phase 수 + 1 개보다 많으면(마커 10개 이상) 앞 9개 마커와 마지막
    // 값(녹화 끝)만 쓴다 — 9번째 phase 가 녹화 끝까지 간다. 그 밖에는 trigger
    // 그대로다.
    final bounds = phaseBoundaries(trigger);
    final phaseCount = phaseCountFromBoundaries(bounds.length);
    final seq = phaseSeqFor(phaseCount);
    final nPhases = min(phaseCount, bounds.length - 1);

    for (int pi = 0; pi < nPhases; pi++) {
      final start = min((bounds[pi] as num).toInt() * 2, total);
      final end   = min((bounds[pi + 1] as num).toInt() * 2, total);
      final count = end - start;

      List<double> pct = List.filled(5, 0.0);
      if (count > 0) {
        List<int> counts = List.filled(5, 0);
        for (int i = start; i < end; i++) {
          final s = (sleepStage[i] as num).toInt();
          if (s >= 0 && s < 5) counts[s]++;
        }
        for (int si = 0; si < 5; si++) {
          pct[si] = counts[si] / count * 100.0;
        }
      }
      data.add(pct);
    }

    return SleepPhaseDistributionModel(
      data: data,
      phaseLabels: [for (int i = 0; i < data.length; i++) seq[i].short],
    );
  }
}
