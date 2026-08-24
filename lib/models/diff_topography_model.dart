class DiffTopographyModel {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;
  String? diff5;   // 6-phase 전용 (recovery - stimulation4)

  DiffTopographyModel({
    required this.diff1,
    required this.diff2,
    required this.diff3,
    required this.diff4,
    this.diff5,
  });

  String? byIndex(int i) {
    switch (i) {
      case 0: return diff1;
      case 1: return diff2;
      case 2: return diff3;
      case 3: return diff4;
      case 4: return diff5;
    }
    return null;
  }


  factory DiffTopographyModel.fromJson(Map<String, dynamic> json, String type) {

    return DiffTopographyModel(
      diff1: (json['diff1'] as Map?)?['topography_$type'] as String?,
      diff2: (json['diff2'] as Map?)?['topography_$type'] as String?,
      diff3: (json['diff3'] as Map?)?['topography_$type'] as String?,
      diff4: (json['diff4'] as Map?)?['topography_$type'] as String?,
      diff5: (json['diff5'] as Map?)?['topography_$type'] as String?,
    );
  }
}