class TimeDomainModel {
  double? mean_hr;
  double? mean_rr;
  double? sdnn;
  double? rmssd;
  double? pnn50;
  double? pnn20;
  double? pnn10;
  double? pnn05;

  TimeDomainModel({this.mean_hr, this.mean_rr, this.sdnn, this.rmssd, this.pnn50, this.pnn10, this.pnn20, this.pnn05});

  factory TimeDomainModel.fromJson(Map<String, dynamic> json) {
    return TimeDomainModel(
      mean_hr: json['mean_hr'],
      mean_rr: json['mean_rr'],
        sdnn: json['sdnn'],
        rmssd: json['rmssd'],
        pnn50: json['pnn50'],
        pnn10: json['pnn10'],
        pnn20: json['pnn20'],
        pnn05: json['pnn05'],

    );
  }
}
