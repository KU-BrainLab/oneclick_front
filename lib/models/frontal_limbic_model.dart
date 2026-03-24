class FrontalLimbicModel {
  String? alpha;
  String? beta;
  String? delta;
  String? gamma;
  String? theta;
  String? sigma;

  FrontalLimbicModel({
    required this.alpha,
    required this.beta,
    required this.delta,
    required this.gamma,
    required this.theta,
    required this.sigma,
  });

  factory FrontalLimbicModel.fromJson(dynamic map) {

    return FrontalLimbicModel(
        alpha: map['alpha'],
        beta: map['beta'],
        delta: map['delta'],
        gamma: map['gamma'],
        theta: map['theta'],
        sigma: map['sigma'],
    );
  }
}