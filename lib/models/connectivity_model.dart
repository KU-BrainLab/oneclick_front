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
      baseline: (json['baseline'] as Map?)?['connectivity_$type'] as String?,
      stimulation1: (json['stimulation1'] as Map?)?['connectivity_$type'] as String?,
      recovery1: (json['recovery1'] as Map?)?['connectivity_$type'] as String?,
      stimulation2: (json['stimulation2'] as Map?)?['connectivity_$type'] as String?,
      recovery2: (json['recovery2'] as Map?)?['connectivity_$type'] as String?,
    );
  }
}