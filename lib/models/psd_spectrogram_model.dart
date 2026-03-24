class PsdSpectrogramModel {
  String? cz;
  String? c3;
  String? c4;
  String? fp1;
  String? fp2;
  String? f3;
  String? f4;
  String? f7;
  String? f8;
  String? t3;
  String? t4;
  String? p3;
  String? p4;

  PsdSpectrogramModel({
    this.cz, this.c3, this.c4,
    this.fp1, this.fp2,
    this.f3, this.f4, this.f7, this.f8,
    this.t3, this.t4,
    this.p3, this.p4,
  });

  factory PsdSpectrogramModel.fromJson(dynamic map) {
    return PsdSpectrogramModel(
      cz:  map['cz'],
      c3:  map['c3'],
      c4:  map['c4'],
      fp1: map['fp1'],
      fp2: map['fp2'],
      f3:  map['f3'],
      f4:  map['f4'],
      f7:  map['f7'],
      f8:  map['f8'],
      t3:  map['t3'],
      t4:  map['t4'],
      p3:  map['p3'],
      p4:  map['p4'],
    );
  }
}
