class BrainConnectivityModel {
  String? alpha;
  String? beta;
  String? delta;
  String? gamma;
  String? theta;

  BrainConnectivityModel({
    required this.alpha,
    required this.beta,
    required this.delta,
    required this.gamma,
    required this.theta
  });

  factory BrainConnectivityModel.fromJson(dynamic map) {

    return BrainConnectivityModel(
      alpha: map['alpha'],
      beta: map['beta'],
      delta: map['delta'],
      gamma: map['gamma'],
      theta: map['theta'],
    );
  }
}