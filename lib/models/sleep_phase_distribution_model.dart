import 'dart:math';

import 'package:omnifit_front/models/phase_defs.dart';

// stages: 0=Wake, 1=N1, 2=N2, 3=N3, 4=REM
// trigger: phase+1 개의 분 단위 경계값 → epoch index = trigger[i] * 2 (30s per epoch)

class SleepPhaseDistributionModel {
  static const stageLabels = ['W', 'N1', 'N2', 'N3', 'REM'];

  // [phaseIndex][stageIndex] = percentage (0~100)
  final List<List<double>> data;

  /// 이 세션의 phase 라벨 (모드에 따라 5개 또는 6개 등).
  final List<String> phaseLabels;

  SleepPhaseDistributionModel({required this.data, required this.phaseLabels});

  factory SleepPhaseDistributionModel.fromJson(
    List<dynamic> sleepStage,
    List<dynamic> trigger,
  ) {
    final total = sleepStage.length;
    List<List<double>> data = [];

    final phaseCount = phaseCountFromBoundaries(trigger.length);
    final seq = phaseSeqFor(phaseCount);
    final nPhases = min(phaseCount, trigger.length - 1);

    for (int pi = 0; pi < nPhases; pi++) {
      final start = min((trigger[pi] as num).toInt() * 2, total);
      final end   = min((trigger[pi + 1] as num).toInt() * 2, total);
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
