import 'dart:convert';

GeneralSummaryModel generalSummaryModelFromJson(String str) => GeneralSummaryModel.fromJson(json.decode(str));

class SleepMetrics {
  final String label;
  final double min;
  final double tst;

  SleepMetrics({
    required this.label,
    required this.min,
    required this.tst,
  });

  factory SleepMetrics.fromJson(Map<String, dynamic> json) => SleepMetrics(
    label: json["label"] ?? '',
    min: (json["min"] as num? ?? 0.0).toDouble(),
    tst: (json["tst"] as num? ?? 0.0).toDouble(),
  );
}

class GeneralSummaryModel {
  final double tib;
  final double tst;
  final double twt;
  final double waso;
  final double sleepLatency;
  final double remLatency;
  final double sleepEfficiency;
  final List<SleepMetrics> sleepStages;
  final List<SleepMetrics> summaryStages;

  GeneralSummaryModel({
    required this.tib,
    required this.tst,
    required this.twt,
    required this.waso,
    required this.sleepLatency,
    required this.remLatency,
    required this.sleepEfficiency,
    required this.sleepStages,
    required this.summaryStages,
  });

  factory GeneralSummaryModel.fromJson(Map<String, dynamic> json) {
    final sleepStages = [
      SleepMetrics(
        label: 'Stage N1 sleep',
        min: (json['sleep_n1_min'] as num? ?? 0.0).toDouble(),
        tst: (json['sleep_n1_tst'] as num? ?? 0.0).toDouble(),
      ),
      SleepMetrics(
        label: 'Stage N2 sleep',
        min: (json['sleep_n2_min'] as num? ?? 0.0).toDouble(),
        tst: (json['sleep_n2_tst'] as num? ?? 0.0).toDouble(),
      ),
      SleepMetrics(
        label: 'Stage N3 sleep',
        min: (json['sleep_n3_min'] as num? ?? 0.0).toDouble(),
        tst: (json['sleep_n3_tst'] as num? ?? 0.0).toDouble(),
      ),
    ];

    final summaryStages = [
      SleepMetrics(
        label: 'Total NREM sleep',
        min: (json['sleep_nrem_min'] as num? ?? 0.0).toDouble(),
        tst: (json['sleep_nrem_tst'] as num? ?? 0.0).toDouble(),
      ),
      SleepMetrics(
        label: 'REM sleep',
        min: (json['sleep_rem_min'] as num? ?? 0.0).toDouble(),
        tst: (json['sleep_rem_tst'] as num? ?? 0.0).toDouble(),
      ),
    ];

    return GeneralSummaryModel(
      tib: (json["tib"] as num? ?? 0.0).toDouble(),
      tst: (json["tst"] as num? ?? 0.0).toDouble(),
      twt: (json["twt"] as num? ?? 0.0).toDouble(),
      waso: (json["waso"] as num? ?? 0.0).toDouble(),
      sleepLatency: (json["sleep_latency"] as num? ?? 0.0).toDouble(),
      remLatency: (json["rem_latency"] as num? ?? 0.0).toDouble(),
      sleepEfficiency: (json["sleep_eff"] as num? ?? 0.0).toDouble(),
      sleepStages: sleepStages,
      summaryStages: summaryStages,
    );
  }
}