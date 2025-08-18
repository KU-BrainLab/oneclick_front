class DiffConnectivity2Model {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;

  DiffConnectivity2Model({
    required this.diff1,
    required this.diff2,
    required this.diff3,
    required this.diff4,
  });


  factory DiffConnectivity2Model.fromJson(Map<String, dynamic> json, String type) {


    return DiffConnectivity2Model(
      diff1: json['diff1']['connectivity2_$type'],
      diff2: json['diff2']['connectivity2_$type'],
      diff3: json['diff3']['connectivity2_$type'],
      diff4: json['diff4']['connectivity2_$type'],
    );
  }
}