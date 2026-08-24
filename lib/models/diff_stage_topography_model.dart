class DiffStageTopographyModel {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;
  String? diff5;   // 6-phase 전용 (recovery - stimulation4)

  DiffStageTopographyModel({
    this.diff1, this.diff2, this.diff3, this.diff4, this.diff5,
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

  // type: delta/theta/alpha/sigma/beta/gamma
  // stage: wake/n1/n2/n3/rem
  factory DiffStageTopographyModel.fromJson(Map<String, dynamic> json, String type, String stage) {
    return DiffStageTopographyModel(
      diff1: (json['diff1'] as Map?)?['topography_${type}_$stage'] as String?,
      diff2: (json['diff2'] as Map?)?['topography_${type}_$stage'] as String?,
      diff3: (json['diff3'] as Map?)?['topography_${type}_$stage'] as String?,
      diff4: (json['diff4'] as Map?)?['topography_${type}_$stage'] as String?,
      diff5: (json['diff5'] as Map?)?['topography_${type}_$stage'] as String?,
    );
  }
}
