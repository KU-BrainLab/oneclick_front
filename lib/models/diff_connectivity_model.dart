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
      diff1: json['diff1']['connectivity_$type'],
      diff2: json['diff2']['connectivity_$type'],
      diff3: json['diff3']['connectivity_$type'],
      diff4: json['diff4']['connectivity_$type'],
    );
  }
}