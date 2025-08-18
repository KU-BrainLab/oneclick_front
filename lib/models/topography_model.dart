class TopographyModel {
  String baseline;
  String stimulation1;
  String recovery1;
  String stimulation2;
  String recovery2;

  TopographyModel({
    required this.baseline,
    required this.stimulation1,
    required this.recovery1,
    required this.stimulation2,
    required this.recovery2,
  });


  factory TopographyModel.fromJson(Map<String, dynamic> json, String type) {

    return TopographyModel(
      baseline: json['baseline']['topography_$type'],
      stimulation1: json['stimulation1']['topography_$type'],
      recovery1: json['recovery1']['topography_$type'],
      stimulation2: json['stimulation2']['topography_$type'],
      recovery2: json['recovery2']['topography_$type'],
    );
  }
}