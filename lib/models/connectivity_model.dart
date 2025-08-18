class ConnectivityModel {
  String? baseline;
  String? stimulation1;
  String? recovery1;
  String? stimulation2;
  String? recovery2;

  ConnectivityModel({
    required this.baseline,
    required this.stimulation1,
    required this.recovery1,
    required this.stimulation2,
    required this.recovery2,
  });


  factory ConnectivityModel.fromJson(Map<String, dynamic> json, String type) {


    return ConnectivityModel(
      baseline: json['baseline']['connectivity_$type'],
      stimulation1: json['stimulation1']['connectivity_$type'],
      recovery1: json['recovery1']['connectivity_$type'],
      stimulation2: json['stimulation2']['connectivity_$type'],
      recovery2: json['recovery2']['connectivity_$type'],
    );
  }
}