class DiffTopographyModel {
  String diff1;
  String diff2;
  String diff3;
  String diff4;

  DiffTopographyModel({
    required this.diff1,
    required this.diff2,
    required this.diff3,
    required this.diff4,
  });


  factory DiffTopographyModel.fromJson(Map<String, dynamic> json, String type) {

    return DiffTopographyModel(
      diff1: json['diff1']['topography_$type'],
      diff2: json['diff2']['topography_$type'],
      diff3: json['diff3']['topography_$type'],
      diff4: json['diff4']['topography_$type'],
    );
  }
}