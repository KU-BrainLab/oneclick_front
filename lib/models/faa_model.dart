class FaaModel {
  String? faa_baseline;
  String? faa_stimulation1;
  String? faa_recovery1;
  String? faa_stimulation2;
  String? faa_recovery2;
  // 6-phase 전용
  String? faa_stimulation3;
  String? faa_stimulation4;
  String? faa_recovery;

  FaaModel({
    required this.faa_baseline,
    required this.faa_stimulation1,
    required this.faa_recovery1,
    required this.faa_stimulation2,
    required this.faa_recovery2,
    this.faa_stimulation3,
    this.faa_stimulation4,
    this.faa_recovery,
  });

  /// phase_defs.dart 의 PhaseCol.key ('baseline' 등)로 faa_* 필드를 찾는다.
  String? byKey(String key) {
    switch (key) {
      case 'baseline': return faa_baseline;
      case 'stimulation1': return faa_stimulation1;
      case 'recovery1': return faa_recovery1;
      case 'stimulation2': return faa_stimulation2;
      case 'recovery2': return faa_recovery2;
      case 'stimulation3': return faa_stimulation3;
      case 'stimulation4': return faa_stimulation4;
      case 'recovery': return faa_recovery;
    }
    return null;
  }

  factory FaaModel.fromJson(dynamic map) {

    return FaaModel(
        faa_baseline: map['faa_baseline'],
        faa_stimulation1: map['faa_stimulation1'],
        faa_recovery1: map['faa_recovery1'],
        faa_stimulation2: map['faa_stimulation2'],
        faa_recovery2: map['faa_recovery2'],
        faa_stimulation3: map['faa_stimulation3'],
        faa_stimulation4: map['faa_stimulation4'],
        faa_recovery: map['faa_recovery'],
    );
  }
}