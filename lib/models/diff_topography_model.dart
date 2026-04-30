class DiffTopographyModel {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;

  DiffTopographyModel({
    required this.diff1,
    required this.diff2,
    required this.diff3,
    required this.diff4,
  });


  factory DiffTopographyModel.fromJson(Map<String, dynamic> json, String type) {

    return DiffTopographyModel(
      diff1: (json['diff1'] as Map?)?['topography_$type'] as String?,
      diff2: (json['diff2'] as Map?)?['topography_$type'] as String?,
      diff3: (json['diff3'] as Map?)?['topography_$type'] as String?,
      diff4: (json['diff4'] as Map?)?['topography_$type'] as String?,
    );
  }
}