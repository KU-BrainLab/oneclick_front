import 'dart:math';

// stages: 0=Wake, 1=N1, 2=N2, 3=N3, 4=REM
// trigger: 6 values in minutes → epoch index = trigger[i] * 2 (30s per epoch)

class SleepPhaseDistributionModel {
  static const stageLabels = ['W', 'N1', 'N2', 'N3', 'REM'];
  static const phaseLabels = ['Baseline', 'Stim1', 'Rec1', 'Stim2', 'Rec2'];

  // [phaseIndex][stageIndex] = percentage (0~100)
  final List<List<double>> data;

  SleepPhaseDistributionModel({required this.data});

  factory SleepPhaseDistributionModel.fromJson(
    List<dynamic> sleepStage,
    List<dynamic> trigger,
  ) {
    final total = sleepStage.length;
    List<List<double>> data = [];

    for (int pi = 0; pi < 5; pi++) {
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

    return SleepPhaseDistributionModel(data: data);
  }
}
