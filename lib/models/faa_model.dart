class FaaModel {
  String? faa_baseline;
  String? faa_stimulation1;
  String? faa_recovery1;
  String? faa_stimulation2;
  String? faa_recovery2;

  FaaModel({
    required this.faa_baseline,
    required this.faa_stimulation1,
    required this.faa_recovery1,
    required this.faa_stimulation2,
    required this.faa_recovery2
  });

  factory FaaModel.fromJson(dynamic map) {

    return FaaModel(
        faa_baseline: map['faa_baseline'],
        faa_stimulation1: map['faa_stimulation1'],
        faa_recovery1: map['faa_recovery1'],
        faa_stimulation2: map['faa_stimulation2'],
        faa_recovery2: map['faa_recovery2'],
    );
  }
}