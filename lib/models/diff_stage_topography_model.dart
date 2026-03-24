class DiffStageTopographyModel {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;

  DiffStageTopographyModel({
    this.diff1, this.diff2, this.diff3, this.diff4,
  });

  // type: delta/theta/alpha/sigma/beta/gamma
  // stage: wake/n1/n2/n3/rem
  factory DiffStageTopographyModel.fromJson(Map<String, dynamic> json, String type, String stage) {
    return DiffStageTopographyModel(
      diff1: json['diff1']['topography_${type}_$stage'],
      diff2: json['diff2']['topography_${type}_$stage'],
      diff3: json['diff3']['topography_${type}_$stage'],
      diff4: json['diff4']['topography_${type}_$stage'],
    );
  }
}
