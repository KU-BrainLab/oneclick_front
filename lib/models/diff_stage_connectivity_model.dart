class DiffStageConnectivityModel {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;

  DiffStageConnectivityModel({
    this.diff1, this.diff2, this.diff3, this.diff4,
  });

  // type: delta/theta/alpha/sigma/beta/gamma
  // stage: wake/n1/n2/n3/rem
  factory DiffStageConnectivityModel.fromJson(Map<String, dynamic> json, String type, String stage) {
    return DiffStageConnectivityModel(
      diff1: (json['diff1'] as Map?)?['connectivity_${type}_$stage'] as String?,
      diff2: (json['diff2'] as Map?)?['connectivity_${type}_$stage'] as String?,
      diff3: (json['diff3'] as Map?)?['connectivity_${type}_$stage'] as String?,
      diff4: (json['diff4'] as Map?)?['connectivity_${type}_$stage'] as String?,
    );
  }
}