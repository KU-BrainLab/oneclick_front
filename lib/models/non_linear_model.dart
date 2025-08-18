class NonLinearModel {
  double? sd1;
  double? sd2;
  double? sd1_sd2_ratio;

  NonLinearModel({this.sd1, this.sd2, this.sd1_sd2_ratio});

  factory NonLinearModel.fromJson(Map<String, dynamic> json) {
    return NonLinearModel(
        sd1: json['sd1'],
        sd2: json['sd2'],
        sd1_sd2_ratio: json['sd1_sd2_ratio'],
    );
  }
}
