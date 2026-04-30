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
      diff1: (json['diff1'] as Map?)?['connectivity2_$type'] as String?,
      diff2: (json['diff2'] as Map?)?['connectivity2_$type'] as String?,
      diff3: (json['diff3'] as Map?)?['connectivity2_$type'] as String?,
      diff4: (json['diff4'] as Map?)?['connectivity2_$type'] as String?,
    );
  }
}