class DiffConnectivityModel {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;

  DiffConnectivityModel({
    required this.diff1,
    required this.diff2,
    required this.diff3,
    required this.diff4,
  });


  factory DiffConnectivityModel.fromJson(Map<String, dynamic> json, String type) {


    return DiffConnectivityModel(
      diff1: (json['diff1'] as Map?)?['connectivity_$type'] as String?,
      diff2: (json['diff2'] as Map?)?['connectivity_$type'] as String?,
      diff3: (json['diff3'] as Map?)?['connectivity_$type'] as String?,
      diff4: (json['diff4'] as Map?)?['connectivity_$type'] as String?,
    );
  }
}