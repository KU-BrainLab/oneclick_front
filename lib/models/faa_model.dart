class FaaModel {
  String? alpha;
  String? beta;
  String? delta;
  String? gamma;
  String? theta;

  FaaModel({
    required this.alpha,
    required this.beta,
    required this.delta,
    required this.gamma,
    required this.theta
  });

  factory FaaModel.fromJson(dynamic map) {

    return FaaModel(
        alpha: map['alpha'],
        beta: map['beta'],
        delta: map['delta'],
        gamma: map['gamma'],
        theta: map['theta'],
    );
  }
}