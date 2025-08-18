class RegionPsdModel {
  List<double> left;
  List<double> right;
  double interval;
  double max;

  RegionPsdModel({
    required this.left,
    required this.right,
    required this.max,
    required this.interval,
  });

  factory RegionPsdModel.fromJson(List<dynamic> leftList, List<dynamic> rightList) {
    List<double> leftRaw = leftList.map((e) => (e as num).toDouble()).toList();
    List<double> rightRaw = rightList.map((e) => (e as num).toDouble()).toList();

    double leftSum = leftRaw.fold(0.0, (a,b) => a+b);
    double rightSum = rightRaw.fold(0.0, (a,b) => a+b);

    List<double> left = leftSum == 0
        ? List<double>.filled(leftRaw.length, 0.0)
        : leftRaw.map((v) => (v / leftSum) * 100.0).toList();

    List<double> right = rightSum == 0
        ? List<double>.filled(rightRaw.length, 0.0)
        : rightRaw.map((v) => (v / rightSum) * 100.0).toList();

    double max = 0.0;
    for (final v in left)  { if (v > max) max = v; }
    for (final v in right) { if (v > max) max = v; }

    double interval = 5;
    
    return RegionPsdModel(left: left, right: right, max: max, interval: interval);
  }

  @override
  String toString() {
    return "RegionPsdModel : { left : $left, right : $right, interval : $interval, max : $max }";
  }
}