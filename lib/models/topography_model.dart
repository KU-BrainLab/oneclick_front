class TopographyModel {
  String? baseline;
  String? stimulation1;
  String? recovery1;
  String? stimulation2;
  String? recovery2;

  TopographyModel({
    required this.baseline,
    required this.stimulation1,
    required this.recovery1,
    required this.stimulation2,
    required this.recovery2,
  });


  factory TopographyModel.fromJson(Map<String, dynamic> json, String type) {

    return TopographyModel(
      baseline: (json['baseline'] as Map?)?['topography_$type'] as String?,
      stimulation1: (json['stimulation1'] as Map?)?['topography_$type'] as String?,
      recovery1: (json['recovery1'] as Map?)?['topography_$type'] as String?,
      stimulation2: (json['stimulation2'] as Map?)?['topography_$type'] as String?,
      recovery2: (json['recovery2'] as Map?)?['topography_$type'] as String?,
    );
  }
}