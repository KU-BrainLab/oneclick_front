class TopographyModel {
  String? baseline;
  String? stimulation1;
  String? recovery1;
  String? stimulation2;
  String? recovery2;
  // 6-phase 전용 (baseline, stim1~4, recovery)
  String? stimulation3;
  String? stimulation4;
  String? recovery;

  TopographyModel({
    required this.baseline,
    required this.stimulation1,
    required this.recovery1,
    required this.stimulation2,
    required this.recovery2,
    this.stimulation3,
    this.stimulation4,
    this.recovery,
  });

  /// phase_defs.dart 의 PhaseCol.key 로 필드를 찾는다.
  String? byKey(String key) {
    switch (key) {
      case 'baseline': return baseline;
      case 'stimulation1': return stimulation1;
      case 'recovery1': return recovery1;
      case 'stimulation2': return stimulation2;
      case 'recovery2': return recovery2;
      case 'stimulation3': return stimulation3;
      case 'stimulation4': return stimulation4;
      case 'recovery': return recovery;
    }
    return null;
  }


  factory TopographyModel.fromJson(Map<String, dynamic> json, String type) {

    return TopographyModel(
      baseline: (json['baseline'] as Map?)?['topography_$type'] as String?,
      stimulation1: (json['stimulation1'] as Map?)?['topography_$type'] as String?,
      recovery1: (json['recovery1'] as Map?)?['topography_$type'] as String?,
      stimulation2: (json['stimulation2'] as Map?)?['topography_$type'] as String?,
      recovery2: (json['recovery2'] as Map?)?['topography_$type'] as String?,
      stimulation3: (json['stimulation3'] as Map?)?['topography_$type'] as String?,
      stimulation4: (json['stimulation4'] as Map?)?['topography_$type'] as String?,
      recovery: (json['recovery'] as Map?)?['topography_$type'] as String?,
    );
  }
}