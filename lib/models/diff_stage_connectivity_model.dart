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
      diff1: json['diff1']['connectivity_${type}_$stage'],
      diff2: json['diff2']['connectivity_${type}_$stage'],
      diff3: json['diff3']['connectivity_${type}_$stage'],
      diff4: json['diff4']['connectivity_${type}_$stage'],
    );
  }
}
