class FrequencyDomainModel {
  double? vlf;
  double? lf;
  double? hf;
  double? lf_hf_ratio;

  FrequencyDomainModel({this.vlf, this.lf, this.hf, this.lf_hf_ratio});

  get total => (vlf ?? 0) + (lf ?? 0) + (hf ?? 0);

  factory FrequencyDomainModel.fromJson(Map<String, dynamic> json) {
    return FrequencyDomainModel(
        vlf: json['vlf'],
        lf: json['lf'],
        hf: json['hf'],
        lf_hf_ratio: json['lf_hf_ratio'],
    );
  }
}
