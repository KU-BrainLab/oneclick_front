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
    List<double> left = [];
    List<double> right = [];
    double max = 0;

    leftList.forEach((element) {
      
      double ele = (element as double) * 100;
      
      left.add(ele);
      if(max < ele) {
        max = ele;
      }
    });

    rightList.forEach((element) {
      double ele = (element as double) * 100;

      right.add(ele);
      if(max < ele) {
        max = ele;
      }
    });

    double interval = 5;

    return RegionPsdModel(left: left, right: right, max: max, interval: interval);
  }

  @override
  String toString() {
    return "RegionPsdModel : { left : $left, right : $right, interval : $interval, max : $max }";
  }
}