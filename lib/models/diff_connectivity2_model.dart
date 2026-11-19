class DiffConnectivity2Model {
  String? diff1;
  String? diff2;
  String? diff3;
  String? diff4;
  // diff 슬롯은 위치 기반이라 모드마다 뜻이 다르다 (라벨은 phase_defs.dart 의
  // diffSeqFor). diff5 는 6-phase 에서 recovery - stimulation4, 9-phase 에서
  // stimulation3 - recovery2 다.
  String? diff5;
  // 9-phase 에서 추가 (recovery3 - stimulation3, stimulation4 - recovery3,
  // recovery4 - stimulation4)
  String? diff6;
  String? diff7;
  String? diff8;

  DiffConnectivity2Model({
    required this.diff1,
    required this.diff2,
    required this.diff3,
    required this.diff4,
    this.diff5,
    this.diff6,
    this.diff7,
    this.diff8,
  });

  String? byIndex(int i) {
    switch (i) {
      case 0: return diff1;
      case 1: return diff2;
      case 2: return diff3;
      case 3: return diff4;
      case 4: return diff5;
      case 5: return diff6;
      case 6: return diff7;
      case 7: return diff8;
    }
    return null;
  }


  factory DiffConnectivity2Model.fromJson(Map<String, dynamic> json, String type) {


    return DiffConnectivity2Model(
      diff1: (json['diff1'] as Map?)?['connectivity2_$type'] as String?,
      diff2: (json['diff2'] as Map?)?['connectivity2_$type'] as String?,
      diff3: (json['diff3'] as Map?)?['connectivity2_$type'] as String?,
      diff4: (json['diff4'] as Map?)?['connectivity2_$type'] as String?,
      diff5: (json['diff5'] as Map?)?['connectivity2_$type'] as String?,
      diff6: (json['diff6'] as Map?)?['connectivity2_$type'] as String?,
      diff7: (json['diff7'] as Map?)?['connectivity2_$type'] as String?,
      diff8: (json['diff8'] as Map?)?['connectivity2_$type'] as String?,
    );
  }
}