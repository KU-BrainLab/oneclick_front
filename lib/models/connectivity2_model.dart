class Connectivity2Model {
  String? baseline;
  String? stimulation1;
  String? recovery1;
  String? stimulation2;
  String? recovery2;

  Connectivity2Model({
    required this.baseline,
    required this.stimulation1,
    required this.recovery1,
    required this.stimulation2,
    required this.recovery2,
  });


  factory Connectivity2Model.fromJson(Map<String, dynamic> json, String type) {


    return Connectivity2Model(
      baseline: json['baseline']['connectivity2_$type'],
      stimulation1: json['stimulation1']['connectivity2_$type'],
      recovery1: json['recovery1']['connectivity2_$type'],
      stimulation2: json['stimulation2']['connectivity2_$type'],
      recovery2: json['recovery2']['connectivity2_$type'],
    );
  }
}